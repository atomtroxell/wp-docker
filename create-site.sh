#!/bin/bash

# WordPress Multi-Site Creator with Automatic Port Detection
# Usage: ./create-site.sh <site-name>

set -e

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Load configuration
if [ -f "$SCRIPT_DIR/config.sh" ]; then
    source "$SCRIPT_DIR/config.sh"
else
    echo "Warning: config.sh not found, using defaults"
    SITES_DIR=".."
    START_PORT=8080
    COMPOSE_FILE="docker-compose.yml"
fi

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if site name is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Site name is required${NC}"
    echo "Usage: ./create-site.sh <site-name>"
    echo "Example: ./create-site.sh my-client"
    exit 1
fi

SITE_NAME=$1

# Convert SITES_DIR to absolute path if relative
if [[ "$SITES_DIR" != /* ]]; then
    SITES_DIR="$SCRIPT_DIR/$SITES_DIR"
fi

SITE_DIR="$SITES_DIR/$SITE_NAME"
COMPOSE_FILE_PATH="$SCRIPT_DIR/$COMPOSE_FILE"

# Validate site name (alphanumeric and hyphens only)
if [[ ! $SITE_NAME =~ ^[a-zA-Z0-9-]+$ ]]; then
    echo -e "${RED}Error: Site name must contain only letters, numbers, and hyphens${NC}"
    exit 1
fi

# Check if site already exists
if [ -d "$SITE_DIR" ]; then
    echo -e "${RED}Error: Site '$SITE_NAME' already exists at: $SITE_DIR${NC}"
    exit 1
fi

# Check if site already exists in docker-compose.yml
if grep -q "${SITE_NAME}_wordpress:" "$COMPOSE_FILE_PATH" 2>/dev/null; then
    echo -e "${RED}Error: Site '$SITE_NAME' already exists in docker-compose.yml!${NC}"
    exit 1
fi

echo -e "${BLUE}Creating new WordPress site: $SITE_NAME${NC}"

# Function to find next available port
find_next_port() {
    local start_port=$1
    local port=$start_port

    # Extract all ports from docker-compose.yml
    local used_ports=$(grep -oP '"\K[0-9]+(?=:80")' "$COMPOSE_FILE_PATH" 2>/dev/null || echo "")

    # Find the next available port
    while echo "$used_ports" | grep -q "^$port$"; do
        ((port+=2))
    done

    echo $port
}

# Find next available ports (WordPress and phpMyAdmin)
WP_PORT=$(find_next_port $START_PORT)
PMA_PORT=$((WP_PORT + 1))

echo -e "${GREEN}Assigned ports:${NC}"
echo "  WordPress: $WP_PORT"
echo "  phpMyAdmin: $PMA_PORT"
echo -e "${BLUE}Site location:${NC}"
echo "  $SITE_DIR"

# Create site directory structure
echo -e "${BLUE}Creating directory structure...${NC}"
mkdir -p "$SITE_DIR/wp-content/themes"
mkdir -p "$SITE_DIR/wp-content/plugins"
mkdir -p "$SITE_DIR/wp-content/uploads"

# Create .gitkeep for uploads
touch "$SITE_DIR/wp-content/uploads/.gitkeep"

# Create site-specific .env file
cat > "$SITE_DIR/.env" <<EOF
# Site Configuration for $SITE_NAME
SITE_NAME=$SITE_NAME

# Port Configuration
WP_PORT=$WP_PORT
PMA_PORT=$PMA_PORT

# Database Configuration
DB_NAME=wordpress
DB_USER=wordpress
DB_PASSWORD=wordpress
DB_ROOT_PASSWORD=rootpassword

# WordPress Debug Mode (1 = enabled, 0 = disabled)
WP_DEBUG=1
EOF

# Create .gitignore
cat > "$SITE_DIR/.gitignore" <<EOF
# WordPress uploads (media files can be large)
wp-content/uploads/*
!wp-content/uploads/.gitkeep

# Environment files (if you create local overrides)
.env.local

# System files
.DS_Store
Thumbs.db
*.swp
*~

# IDE files
.vscode/
.idea/
EOF

# Create README for the site
cat > "$SITE_DIR/README.md" <<EOF
# $SITE_NAME WordPress Site

## Access Points

- **WordPress**: http://localhost:$WP_PORT
- **phpMyAdmin**: http://localhost:$PMA_PORT

## Quick Start

All commands should be run from the \`wp-docker\` directory:

\`\`\`bash
cd wp-docker

# Start this site
docker-compose up -d ${SITE_NAME}_wordpress

# Stop this site
docker-compose stop ${SITE_NAME}_wordpress ${SITE_NAME}_db ${SITE_NAME}_phpmyadmin

# View logs
docker-compose logs -f ${SITE_NAME}_wordpress

# Restart this site
docker-compose restart ${SITE_NAME}_wordpress
\`\`\`

## Database Access

### phpMyAdmin
- URL: http://localhost:$PMA_PORT
- Server: ${SITE_NAME}_db
- Username: wordpress
- Password: wordpress

### MySQL Command Line
\`\`\`bash
cd wp-docker
docker-compose exec ${SITE_NAME}_db mysql -u wordpress -pwordpress wordpress
\`\`\`

## Development

### Adding Themes
Place your theme in \`wp-content/themes/\` and activate via WordPress admin.

### Adding Plugins
Place your plugin in \`wp-content/plugins/\` and activate via WordPress admin.

### Git Workflow
This directory is a git repository for tracking your site's custom code:

\`\`\`bash
cd $SITE_DIR
git add wp-content/
git commit -m "Your changes"
git push
\`\`\`

## Data Persistence

Your data is safe when containers are stopped:

- **Database**: Stored in Docker volume \`${SITE_NAME}_db_data\`
- **WordPress Core**: Stored in Docker volume \`${SITE_NAME}_wordpress_data\`
- **Themes/Plugins/Uploads**: Stored in \`wp-content/\` directory (this folder)

Running \`docker-compose down\` or stopping containers does NOT delete your data.
Only \`docker-compose down -v\` or manually deleting volumes will remove data.

## Site Configuration

Configuration is stored in \`.env\` file. After changing, restart containers:

\`\`\`bash
cd wp-docker
docker-compose restart ${SITE_NAME}_wordpress
\`\`\`
EOF

# Calculate relative path from docker-compose.yml to site directory
RELATIVE_SITE_PATH=$(realpath --relative-to="$SCRIPT_DIR" "$SITE_DIR")

# Add site to docker-compose.yml
echo -e "${BLUE}Adding site to docker-compose.yml...${NC}"

# Create the service definitions
cat >> "$COMPOSE_FILE_PATH" <<EOF

  # $SITE_NAME site
  ${SITE_NAME}_wordpress:
    image: wordpress:latest
    restart: unless-stopped
    container_name: ${SITE_NAME}_wordpress
    ports:
      - "$WP_PORT:80"
    environment:
      WORDPRESS_DB_HOST: ${SITE_NAME}_db:3306
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress
      WORDPRESS_DB_NAME: wordpress
      WORDPRESS_DEBUG: 1
    volumes:
      - ${SITE_NAME}_wordpress_data:/var/www/html
      - $RELATIVE_SITE_PATH/wp-content:/var/www/html/wp-content
    depends_on:
      ${SITE_NAME}_db:
        condition: service_healthy
    networks:
      - ${SITE_NAME}_network

  ${SITE_NAME}_db:
    image: mysql:8.0
    restart: unless-stopped
    container_name: ${SITE_NAME}_db
    environment:
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress
      MYSQL_ROOT_PASSWORD: rootpassword
    volumes:
      - ${SITE_NAME}_db_data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - ${SITE_NAME}_network

  ${SITE_NAME}_phpmyadmin:
    image: phpmyadmin:latest
    restart: unless-stopped
    container_name: ${SITE_NAME}_phpmyadmin
    ports:
      - "$PMA_PORT:80"
    environment:
      PMA_HOST: ${SITE_NAME}_db
      PMA_USER: wordpress
      PMA_PASSWORD: wordpress
    depends_on:
      - ${SITE_NAME}_db
    networks:
      - ${SITE_NAME}_network

networks:
  ${SITE_NAME}_network:
    name: ${SITE_NAME}_network

volumes:
  ${SITE_NAME}_wordpress_data:
    name: ${SITE_NAME}_wordpress_data
  ${SITE_NAME}_db_data:
    name: ${SITE_NAME}_db_data
EOF

# Initialize git repository for the site
echo -e "${BLUE}Initializing git repository...${NC}"
cd "$SITE_DIR"
git init
git add .
git commit -m "Initial commit for $SITE_NAME WordPress site"
cd - > /dev/null

# Success message
echo ""
echo -e "${GREEN}✓ Site '$SITE_NAME' created successfully!${NC}"
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Next steps:${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "1. Start the site:"
echo "   ${GREEN}cd wp-docker${NC}"
echo "   ${GREEN}docker-compose up -d ${SITE_NAME}_wordpress${NC}"
echo ""
echo "2. Access WordPress:"
echo "   ${GREEN}http://localhost:$WP_PORT${NC}"
echo ""
echo "3. Complete WordPress installation in your browser"
echo ""
echo "4. Access phpMyAdmin:"
echo "   ${GREEN}http://localhost:$PMA_PORT${NC}"
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Git repository initialized:${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "  Location: $SITE_DIR"
echo ""
echo "  To add a remote repository:"
echo "  ${GREEN}cd $SITE_DIR${NC}"
echo "  ${GREEN}git remote add origin <your-repo-url>${NC}"
echo "  ${GREEN}git push -u origin main${NC}"
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Data Persistence:${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "  ✓ Database is stored in Docker volume: ${SITE_NAME}_db_data"
echo "  ✓ WordPress core is stored in Docker volume: ${SITE_NAME}_wordpress_data"
echo "  ✓ Your themes/plugins are stored in: $SITE_DIR/wp-content"
echo ""
echo "  Your data persists even when containers are stopped!"
echo "  Only 'docker-compose down -v' removes volumes."
echo ""
