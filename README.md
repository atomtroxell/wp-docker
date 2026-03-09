# WordPress Multi-Site Docker Manager

A complete Docker-based solution for managing multiple WordPress development sites. Run as many WordPress sites as you need with automatic port detection, isolated databases, and guaranteed data persistence. Each site is its own git repository for version control.

## What This Does

This tool lets you:
- **Create unlimited WordPress sites** with a single command
- **Run multiple sites simultaneously** on different ports
- **Develop like normal WordPress** - edit themes and plugins directly
- **Never lose data** - everything persists when containers stop
- **Version control each site** - automatic git initialization
- **Share your setup** - others can use this exact configuration

## Features

- ✅ **One-Command Site Creation** - Automated setup with port detection
- ✅ **Complete Isolation** - Each site has its own database, network, and volumes
- ✅ **Guaranteed Data Persistence** - Database and files survive reboots and container restarts
- ✅ **Git Integration** - Each site initialized as a git repository
- ✅ **Native Development** - Edit files directly, changes are immediate
- ✅ **Production-Ready** - Health checks, restart policies, named volumes
- ✅ **Configurable** - Choose where sites are created
- ✅ **Cross-Platform** - Works on Windows, Mac, and Linux

## Prerequisites

Before starting, install:

1. **Docker Desktop** - [Download here](https://www.docker.com/products/docker-desktop)
   - Start Docker Desktop and ensure it's running
   - Verify: `docker --version`

2. **Git** - [Download here](https://git-scm.com/)
   - Verify: `git --version`

## Quick Start Guide

### Step 1: Download or Clone This Repository

Place the `wp-docker` folder anywhere on your computer.

```bash
# Example locations:
# Windows: C:\Users\YourName\wp-docker
# Mac/Linux: ~/wp-docker or ~/projects/wp-docker
```

### Step 2: Create Your First Site

Open a terminal in the `wp-docker` directory.

**Windows (Command Prompt or PowerShell):**
```cmd
cd path\to\wp-docker
create-site.bat my-first-site
```

**Mac/Linux/Git Bash:**
```bash
cd path/to/wp-docker
./create-site.sh my-first-site
```

The script will:
- ✅ Detect the next available port (starting at 8080)
- ✅ Create a new site directory (by default, next to wp-docker)
- ✅ Generate configuration files
- ✅ Add the site to docker-compose.yml
- ✅ Initialize a git repository
- ✅ Show you the access URLs

### Step 3: Start Your Site

```bash
docker-compose up -d my-first-site_wordpress
```

Wait about 30 seconds for MySQL to initialize (first start only).

### Step 4: Access WordPress

Open your browser to the URL shown by the script (e.g., http://localhost:8080)

Complete the WordPress installation:
1. Choose language
2. Enter site title
3. Create admin username and password
4. Click "Install WordPress"

**You're done!** Start developing your WordPress site.

## Configuration

Before creating sites, you can customize where they're created.

Edit `config.sh` (Mac/Linux) or `config.bat` (Windows):

```bash
# Where WordPress sites will be created
# Default: ".." (parent directory - same level as wp-docker folder)
# Examples:
#   ".." - creates sites next to wp-docker (recommended)
#   "../sites" - creates sites in a 'sites' subdirectory
#   "C:\MySites" - absolute path (Windows)
#   "/home/user/wordpress-sites" - absolute path (Mac/Linux)
SITES_DIR=".."

# Starting port for first site
# Each new site increments by 2 (WordPress + phpMyAdmin)
START_PORT=8080

# Docker Compose file (don't change unless you know what you're doing)
COMPOSE_FILE="docker-compose.yml"
```

**Example Configurations:**

```bash
# Default - creates sites at same level as wp-docker
SITES_DIR=".."
# Result: wp-docker/ and my-site/ are siblings

# Create sites in a subdirectory
SITES_DIR="../wordpress-sites"
# Result: wordpress-sites/my-site/

# Absolute path (Windows)
SITES_DIR="C:\Projects\WordPress"
# Result: C:\Projects\WordPress\my-site\

# Absolute path (Mac/Linux)
SITES_DIR="/home/username/sites"
# Result: /home/username/sites/my-site/
```

## How It Works

### What Gets Created

When you run `create-site.sh my-site`, this happens:

1. **Site Directory Structure:**
   ```
   my-site/
   ├── .git/              # Git repository (initialized)
   ├── .gitignore         # Ignores uploads directory
   ├── .env               # Site configuration (ports, database credentials)
   ├── README.md          # Site-specific documentation
   └── wp-content/        # Your WordPress content (directly editable)
       ├── themes/        # Custom themes go here
       ├── plugins/       # Custom plugins go here
       └── uploads/       # Media uploads (ignored by git)
   ```

2. **Docker Services Added** (in docker-compose.yml):
   - `my-site_wordpress` - WordPress container
   - `my-site_db` - MySQL database
   - `my-site_phpmyadmin` - Database management interface

3. **Docker Volumes Created:**
   - `my-site_wordpress_data` - WordPress core files
   - `my-site_db_data` - MySQL database

4. **Isolated Network:**
   - `my-site_network` - Private network for site containers

### Port Assignment

Ports are automatically assigned:

| Site Order | WordPress Port | phpMyAdmin Port |
|------------|---------------|-----------------|
| 1st site   | 8080          | 8081            |
| 2nd site   | 8082          | 8083            |
| 3rd site   | 8084          | 8085            |
| ...        | +2            | +2              |

The script scans docker-compose.yml and finds the next available port pair.

## Data Persistence - GUARANTEED

Your data is **100% safe** and persists across:
- ✅ Container stops (`docker-compose stop`)
- ✅ Container removal (`docker-compose down`)
- ✅ Docker Desktop restarts
- ✅ Computer reboots
- ✅ System crashes

### Where Data is Stored

**Docker Volumes (Managed by Docker):**
- **Database:** `my-site_db_data` volume
  - All posts, pages, users, comments, settings
  - Survives container lifecycle

- **WordPress Core:** `my-site_wordpress_data` volume
  - WordPress installation files
  - Installed plugins (if installed via admin)
  - WordPress updates

**Your Filesystem (Directly Accessible):**
- **Themes:** `my-site/wp-content/themes/`
- **Plugins:** `my-site/wp-content/plugins/`
- **Uploads:** `my-site/wp-content/uploads/`

### Safe vs Dangerous Commands

**SAFE (Data Persists):**
```bash
docker-compose stop              # Stops containers
docker-compose down              # Removes containers (keeps volumes)
docker-compose restart           # Restarts containers
docker-compose up -d             # Starts containers
```

**DANGEROUS (Deletes Data):**
```bash
docker-compose down -v           # ❌ Removes volumes - DELETES DATABASE
docker volume rm my-site_db_data # ❌ Deletes database volume
```

**Rule:** Never use the `-v` flag unless you want to delete everything and start fresh.

### Verifying Data Persistence

Check your volumes exist:
```bash
docker volume ls | grep my-site
```

You should see:
- `my-site_wordpress_data`
- `my-site_db_data`

These volumes persist until explicitly deleted with `-v` flag or `docker volume rm`.

## Managing Sites

### List All Sites

```bash
# Windows
list-sites.bat

# Mac/Linux
./list-sites.sh
```

Shows:
- Site names
- WordPress URLs
- phpMyAdmin URLs
- Running status

### Start Sites

```bash
# Start one site
docker-compose up -d my-site_wordpress

# Start multiple sites
docker-compose up -d site1_wordpress site2_wordpress

# Start all sites
docker-compose up -d

# Start in foreground (see logs in real-time)
docker-compose up my-site_wordpress
```

### Stop Sites

```bash
# Stop one site (keeps data)
docker-compose stop my-site_wordpress my-site_db my-site_phpmyadmin

# Stop all sites (keeps data)
docker-compose down

# Stop and remove volumes (DELETES DATA)
docker-compose down -v  # ⚠️ DANGEROUS
```

### View Logs

```bash
# Follow logs in real-time
docker-compose logs -f my-site_wordpress

# View all site logs
docker-compose logs my-site_wordpress my-site_db

# Last 100 lines
docker-compose logs --tail=100 my-site_wordpress
```

### Restart Sites

```bash
# Restart one site
docker-compose restart my-site_wordpress

# Restart all sites
docker-compose restart
```

### Update Site Configuration

After editing a site's `.env` file:

```bash
docker-compose restart my-site_wordpress
```

## Development Workflow

### Standard Development Process

1. **Edit files directly** in `my-site/wp-content/`
   ```bash
   # Edit with any editor
   code my-site/wp-content/themes/my-theme/
   ```

2. **Changes are immediately live**
   - No build process needed
   - Just refresh your browser

3. **Commit changes to git**
   ```bash
   cd my-site
   git add wp-content/themes/my-theme/
   git commit -m "Updated homepage layout"
   git push
   ```

### Installing Themes

**Method 1: Via WordPress Admin (Recommended)**
1. Log into WordPress admin
2. Go to Appearance → Themes → Add New
3. Install and activate
4. Theme saves to `my-site/wp-content/themes/`

**Method 2: Manual Installation**
1. Download theme ZIP
2. Extract to `my-site/wp-content/themes/theme-name/`
3. Activate via WordPress admin

**Method 3: Custom Development**
1. Create folder: `my-site/wp-content/themes/my-custom-theme/`
2. Add `style.css` with theme header
3. Add `index.php` and templates
4. Activate via WordPress admin

### Installing Plugins

**Method 1: Via WordPress Admin (Recommended)**
1. Log into WordPress admin
2. Go to Plugins → Add New
3. Install and activate
4. Plugin saves to `my-site/wp-content/plugins/`

**Method 2: Manual Installation**
1. Download plugin ZIP
2. Extract to `my-site/wp-content/plugins/plugin-name/`
3. Activate via WordPress admin

### Database Management

**Via phpMyAdmin (Visual Interface):**
- URL: http://localhost:8081 (or your assigned port)
- Server: `my-site_db`
- Username: `wordpress`
- Password: `wordpress`

**Via MySQL Command Line:**
```bash
docker-compose exec my-site_db mysql -u wordpress -pwordpress wordpress
```

**Via WP-CLI:**
```bash
# List plugins
docker-compose exec my-site_wordpress wp --allow-root plugin list

# Install plugin
docker-compose exec my-site_wordpress wp --allow-root plugin install contact-form-7 --activate

# Export database
docker-compose exec my-site_wordpress wp --allow-root db export
```

## Git Repository Management

Each site is automatically initialized as a git repository.

### Connect to Remote Repository

```bash
cd my-site

# Add remote repository
git remote add origin https://github.com/username/my-site.git

# Push to remote
git branch -M main
git push -u origin main
```

### Daily Git Workflow

```bash
cd my-site

# Check what changed
git status

# Stage changes
git add wp-content/themes/my-theme/

# Commit with message
git commit -m "Add new homepage template"

# Push to remote
git push
```

### What Gets Tracked by Git

**Included in Git:**
- ✅ Custom themes: `wp-content/themes/`
- ✅ Custom plugins: `wp-content/plugins/`
- ✅ Configuration: `.env`, `.gitignore`
- ✅ Documentation: `README.md`

**Excluded from Git (via .gitignore):**
- ❌ Uploads: `wp-content/uploads/` (too large, regenerated)
- ❌ Local config: `.env.local`

**Not in Git (Docker volumes):**
- WordPress core files
- Database

### Working with Branches

```bash
cd my-site

# Create feature branch
git checkout -b feature/new-homepage

# Make changes
# ... edit files ...

# Commit changes
git add .
git commit -m "New homepage design"

# Push branch
git push -u origin feature/new-homepage

# Merge to main
git checkout main
git merge feature/new-homepage
git push
```

## Backup and Restore

### Full Site Backup

**Step 1: Backup Database**
```bash
docker-compose exec my-site_db mysqldump -u wordpress -pwordpress wordpress > backup-$(date +%Y%m%d).sql
```

**Step 2: Backup Files**
```bash
# The wp-content directory is already on your filesystem
# Commit and push to git
cd my-site
git add .
git commit -m "Backup $(date +%Y-%m-%d)"
git push

# Or create archive
tar -czf my-site-backup.tar.gz my-site/wp-content
```

**Step 3: Document Configuration**
- Save a copy of `my-site/.env`
- Note the ports from `docker-compose.yml`

### Restore from Backup

**Step 1: Restore Database**
```bash
# Import SQL file
docker-compose exec -T my-site_db mysql -u wordpress -pwordpress wordpress < backup-20260125.sql
```

**Step 2: Restore Files**
```bash
# From git
cd my-site
git pull

# Or from archive
tar -xzf my-site-backup.tar.gz
```

**Step 3: Restart Containers**
```bash
docker-compose restart my-site_wordpress
```

### Automated Backup Script

Create `backup-site.sh`:
```bash
#!/bin/bash
SITE_NAME=$1
DATE=$(date +%Y%m%d_%H%M%S)

# Backup database
docker-compose exec $SITE_NAME_db mysqldump -u wordpress -pwordpress wordpress > backups/${SITE_NAME}_${DATE}.sql

# Backup files
tar -czf backups/${SITE_NAME}_${DATE}.tar.gz $SITE_NAME/wp-content

echo "Backup complete: backups/${SITE_NAME}_${DATE}.*"
```

## Troubleshooting

### Port Already in Use

**Problem:**
```
Error: Bind for 0.0.0.0:8080 failed: port is already allocated
```

**Solution:**
```bash
# Windows - Find what's using the port
netstat -ano | findstr :8080

# Mac/Linux - Find what's using the port
lsof -i :8080

# Then either:
# 1. Stop that service, OR
# 2. Edit docker-compose.yml and change the port
```

### Database Connection Error

**Problem:** "Error establishing a database connection"

**Solutions:**

1. **Wait for database initialization** (first start takes ~30 seconds)
   ```bash
   # Check if database is healthy
   docker-compose ps
   ```

2. **Check container logs**
   ```bash
   docker-compose logs my-site_db
   docker-compose logs my-site_wordpress
   ```

3. **Restart containers**
   ```bash
   docker-compose restart my-site_wordpress my-site_db
   ```

### Container Won't Start

```bash
# View detailed logs
docker-compose logs my-site_wordpress

# Check container status
docker-compose ps

# Force recreate
docker-compose up -d --force-recreate my-site_wordpress
```

### Permission Issues

**Problem:** Can't upload files or install plugins

**Solution:**
```bash
# Fix WordPress permissions
docker-compose exec my-site_wordpress chown -R www-data:www-data /var/www/html/wp-content
```

### Data Disappeared After Restart

**If you used `docker-compose down -v`:**
- The `-v` flag deleted your volumes
- Data is gone - restore from backup
- **Never use `-v` flag unless you want to delete everything**

**If you used `docker-compose down` (without -v):**
- Data should still be there
- Check volumes exist:
  ```bash
  docker volume ls | grep my-site
  ```
- If volumes exist, start containers again:
  ```bash
  docker-compose up -d my-site_wordpress
  ```

### Site is Slow

**Solutions:**

1. **Check Docker resources**
   - Docker Desktop → Settings → Resources
   - Allocate more CPU/RAM if needed

2. **Only run sites you're using**
   ```bash
   # Stop unused sites
   docker-compose stop unused-site_wordpress unused-site_db unused-site_phpmyadmin
   ```

3. **Check container resources**
   ```bash
   docker stats
   ```

### Can't Access phpMyAdmin

**Solutions:**

1. **Check port in docker-compose.yml**
   ```bash
   grep -A 5 "my-site_phpmyadmin" docker-compose.yml
   ```

2. **Ensure container is running**
   ```bash
   docker-compose ps my-site_phpmyadmin
   ```

3. **Restart phpMyAdmin**
   ```bash
   docker-compose restart my-site_phpmyadmin
   ```

## Advanced Usage

### Custom PHP Configuration

Create `php.ini` in your site directory:

```ini
upload_max_filesize = 64M
post_max_size = 64M
memory_limit = 256M
max_execution_time = 300
```

Add to `docker-compose.yml` under your site's wordpress service:
```yaml
volumes:
  - ../my-site/php.ini:/usr/local/etc/php/conf.d/custom.ini
```

Restart:
```bash
docker-compose up -d --force-recreate my-site_wordpress
```

### Using Xdebug

Add to your site's wordpress service in `docker-compose.yml`:

```yaml
environment:
  XDEBUG_MODE: debug
  XDEBUG_CONFIG: client_host=host.docker.internal
```

### Multiple Environments

Create environment-specific compose files:

```bash
# Start in development mode
docker-compose up -d

# Start in production simulation mode
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### Changing Site URL (Domain)

If you want to use a custom domain instead of localhost:

1. **Edit hosts file:**
   ```bash
   # Windows: C:\Windows\System32\drivers\etc\hosts
   # Mac/Linux: /etc/hosts

   127.0.0.1 mysite.local
   ```

2. **Update WordPress:**
   ```bash
   # Via WP-CLI
   docker-compose exec my-site_wordpress wp --allow-root search-replace 'http://localhost:8080' 'http://mysite.local:8080'

   # Or via phpMyAdmin:
   # wp_options table, change siteurl and home
   ```

## Best Practices

### Security

1. **Change default passwords** before going to production
   - Edit `.env` file
   - Update `docker-compose.yml`
   - Use strong, unique passwords

2. **Disable debug mode** for production
   - Set `WP_DEBUG=0` in `.env`

3. **Keep WordPress updated**
   - Updates via admin dashboard persist in volumes

4. **Don't commit sensitive data**
   - Never commit `.env` files with real passwords to public repos
   - Use `.env.example` for sharing configuration templates

### Performance

1. **Only run sites you're working on**
   ```bash
   # Start only what you need
   docker-compose up -d current-project_wordpress
   ```

2. **Regular cleanup**
   ```bash
   # Remove unused images
   docker system prune -a

   # Remove unused volumes (CAREFUL!)
   docker volume prune
   ```

3. **Monitor resource usage**
   ```bash
   docker stats
   ```

### Organization

1. **Use descriptive site names**
   - Good: `client-website`, `portfolio-2024`, `blog-redesign`
   - Avoid: `site1`, `test`, `aaa`

2. **Document each site**
   - Update the site's `README.md`
   - Note custom configuration
   - Document special plugins/themes

3. **Commit regularly**
   ```bash
   cd my-site
   git add .
   git commit -m "Descriptive message"
   git push
   ```

4. **Use git tags for releases**
   ```bash
   git tag -a v1.0 -m "Version 1.0 - Initial launch"
   git push origin v1.0
   ```

## Sharing This Setup

This wp-docker folder is designed to be shared and reused.

### Share as Git Repository

```bash
cd wp-docker
git init
git add .
git commit -m "WordPress Docker multi-site setup"
git remote add origin https://github.com/username/wp-docker.git
git push -u origin main
```

### For Others to Use

1. They clone your repository:
   ```bash
   git clone https://github.com/username/wp-docker.git
   cd wp-docker
   ```

2. They configure for their environment:
   - Edit `config.sh` or `config.bat`
   - Set `SITES_DIR` to their preferred location

3. They create sites:
   ```bash
   ./create-site.sh their-site-name
   docker-compose up -d their-site-name_wordpress
   ```

### Template for Teams

Create a template repository with:
- Your custom docker-compose.yml base
- Team-specific configurations
- Common plugins pre-configured
- Standard theme structure

Team members clone and create sites with consistent setup.

## Frequently Asked Questions

**Q: Will my data survive if I stop containers?**
A: Yes! Data persists in Docker volumes until explicitly deleted with `-v` flag.

**Q: Can I edit WordPress core files?**
A: WordPress core is in a Docker volume. For modifications, edit themes/plugins in wp-content.

**Q: How do I change where sites are created?**
A: Edit `SITES_DIR` in `config.sh` or `config.bat` before creating sites.

**Q: Can I run this in production?**
A: This is optimized for development. For production, add SSL, use strong passwords, disable debug, and consider managed hosting.

**Q: How many sites can I run?**
A: Limited only by system resources. Each site uses ~500MB-1GB RAM.

**Q: Can I use custom Docker images?**
A: Yes! Create a Dockerfile extending `wordpress:latest` and reference it in docker-compose.yml.

**Q: What if I accidentally used `docker-compose down -v`?**
A: Your database is deleted. Restore from backup. Always use `docker-compose down` without `-v`.

**Q: Can I move a site to another computer?**
A: Yes! Export database, copy wp-content folder, recreate site on new computer, import database.

**Q: How do I update WordPress?**
A: Via WordPress admin dashboard. Updates save to the wordpress_data volume.

**Q: Can I use different WordPress versions?**
A: Yes! In docker-compose.yml, change `wordpress:latest` to `wordpress:6.3` or any version.

## Getting Help

1. **Check this README** - Most questions answered here
2. **Review logs** - `docker-compose logs my-site_wordpress`
3. **Verify Docker is running** - Docker Desktop should be running
4. **Check port availability** - Ensure ports aren't in use
5. **Confirm disk space** - Docker volumes need space

## Technical Details

**Technologies Used:**
- Docker & Docker Compose
- WordPress (latest official image)
- MySQL 8.0
- phpMyAdmin (latest official image)

**System Requirements:**
- Docker Desktop 4.0+
- 4GB RAM minimum (8GB recommended)
- 10GB free disk space per site
- Modern CPU (multi-core recommended)

**Network Architecture:**
- Each site has isolated network
- Containers communicate via service names
- Exposed ports: WordPress (808x), phpMyAdmin (808x+1)

**Volume Strategy:**
- Named volumes for WordPress core and database
- Bind mounts for wp-content (direct file access)

## License

This setup is free to use, modify, and share. No attribution required.

---

**Happy WordPress Development! 🚀**

For updates and contributions, visit the project repository.
