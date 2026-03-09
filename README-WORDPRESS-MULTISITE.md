# WordPress Multi-Site Docker Development Environment

A streamlined Docker-based WordPress development setup that manages multiple sites through a single `docker-compose.yml` file with automatic port detection and individual git repositories for each site.

## Features

- **Single Docker Compose File**: All sites managed in one `docker-compose.yml`
- **Automatic Port Detection**: Scripts automatically find and assign available ports
- **Individual Git Repositories**: Each site has its own repository for version control
- **Isolated Services**: Each site has its own WordPress, MySQL, and phpMyAdmin containers
- **Native Development Experience**: Work with themes and plugins like traditional WordPress development
- **Easy Site Management**: Simple commands to start, stop, and manage individual sites

## Prerequisites

- Docker Desktop installed and running
- Git installed
- Basic command line knowledge

## Quick Start

### 1. Start the Example Site

```bash
# From c:/Sites directory
docker-compose up -d example_wordpress
```

Access:
- WordPress: http://localhost:8080
- phpMyAdmin: http://localhost:8081

### 2. Complete WordPress Installation

1. Open http://localhost:8080 in your browser
2. Follow the WordPress installation wizard
3. Create your admin account

### 3. Create Your First Site

**Windows:**
```bash
create-site.bat my-first-site
```

**Unix/Mac/Linux:**
```bash
./create-site.sh my-first-site
```

This automatically:
- Detects next available ports (8082, 8083)
- Creates directory structure in `sites/my-first-site/`
- Adds services to `docker-compose.yml`
- Initializes a git repository
- Creates a site-specific README

## Directory Structure

```
c:/Sites/
├── docker-compose.yml           # Single compose file for all sites
├── create-site.sh               # Unix/Mac site creation script
├── create-site.bat              # Windows site creation script
├── sites/                       # All WordPress sites
│   ├── example/                 # Example site
│   │   ├── .git/               # Git repository
│   │   ├── .env                # Site configuration
│   │   ├── .gitignore          # Git ignore rules
│   │   ├── README.md           # Site-specific documentation
│   │   └── wp-content/         # WordPress content
│   │       ├── themes/         # Custom themes
│   │       ├── plugins/        # Custom plugins
│   │       └── uploads/        # Media uploads (not tracked)
│   └── my-first-site/          # Your sites...
│       ├── .git/
│       ├── .env
│       ├── .gitignore
│       ├── README.md
│       └── wp-content/
└── README-WORDPRESS-MULTISITE.md
```

## Creating New Sites

### Basic Usage

**Windows:**
```bash
create-site.bat <site-name>
```

**Unix/Mac:**
```bash
./create-site.sh <site-name>
```

### Site Name Requirements

- Use only letters, numbers, and hyphens
- Must be unique
- Examples: `client-site`, `my-blog`, `test-site-123`

### What Happens When You Create a Site

1. **Port Detection**: Script scans `docker-compose.yml` for used ports
2. **Auto Assignment**: Assigns next available port pair (WordPress + phpMyAdmin)
3. **Directory Creation**: Creates `sites/<site-name>/` with wp-content structure
4. **Service Addition**: Adds 3 services to `docker-compose.yml`:
   - `<site-name>_wordpress` - WordPress container
   - `<site-name>_db` - MySQL database
   - `<site-name>_phpmyadmin` - phpMyAdmin interface
5. **Git Initialization**: Creates a git repository in the site directory
6. **Documentation**: Generates site-specific README with access URLs

### Example

```bash
# Create a site named "acme-corp"
create-site.bat acme-corp

# Output:
# Creating new WordPress site: acme-corp
# Assigned ports:
#   WordPress: 8082
#   phpMyAdmin: 8083
# ✓ Site 'acme-corp' created successfully!
```

## Managing Sites

### Start All Sites

```bash
docker-compose up -d
```

### Start Specific Site

```bash
docker-compose up -d sitename_wordpress
```

This automatically starts required dependencies (database, phpMyAdmin).

### Stop Specific Site

```bash
docker-compose stop sitename_wordpress sitename_db sitename_phpmyadmin
```

### Stop All Sites

```bash
docker-compose down
```

### View Site Logs

```bash
# All logs for a site
docker-compose logs -f sitename_wordpress

# All container logs
docker-compose logs -f
```

### Restart a Site

```bash
docker-compose restart sitename_wordpress
```

### Remove a Site

To remove containers but keep data:
```bash
docker-compose stop sitename_wordpress sitename_db sitename_phpmyadmin
```

To remove everything including database:
```bash
docker-compose rm -v sitename_wordpress sitename_db sitename_phpmyadmin
docker volume rm sitename_wordpress_data sitename_db_data
```

Then manually remove from `docker-compose.yml` and delete `sites/sitename/` directory.

## Development Workflow

### Working with Themes

1. Create or copy your theme to `sites/<site-name>/wp-content/themes/`
2. Activate via WordPress admin dashboard
3. Edit theme files directly - changes are live
4. Commit changes to git:

```bash
cd sites/<site-name>
git add wp-content/themes/
git commit -m "Update theme"
git push
```

### Working with Plugins

1. Add plugins to `sites/<site-name>/wp-content/plugins/`
2. Activate via WordPress admin
3. Configure as needed
4. Commit custom plugins to git

### Database Management

**Via phpMyAdmin:**
- Access at `http://localhost:<pma-port>`
- Server: `<site-name>_db`
- Username: `wordpress`
- Password: `wordpress`

**Via MySQL CLI:**
```bash
docker-compose exec sitename_db mysql -u wordpress -pwordpress wordpress
```

## Git Repository Management

Each site is automatically initialized as a git repository.

### Initial Setup

```bash
cd sites/<site-name>

# Add remote repository
git remote add origin https://github.com/yourusername/site-repo.git

# Push to remote
git push -u origin main
```

### Daily Workflow

```bash
cd sites/<site-name>

# Check status
git status

# Add changes
git add wp-content/themes/ wp-content/plugins/

# Commit
git commit -m "Describe your changes"

# Push
git push
```

### What's Tracked

**Tracked by Git:**
- Custom themes in `wp-content/themes/`
- Custom plugins in `wp-content/plugins/`
- Configuration files (`.env`, `.gitignore`)

**Not Tracked:**
- Media uploads (`wp-content/uploads/`)
- Core WordPress files (in Docker volume)
- Database (in Docker volume)

## Port Management

Ports are automatically assigned by the creation script:

| Site Order | WordPress Port | phpMyAdmin Port |
|------------|---------------|-----------------|
| example    | 8080          | 8081            |
| site-1     | 8082          | 8083            |
| site-2     | 8084          | 8085            |
| site-3     | 8086          | 8087            |
| ...        | +2            | +2              |

Port pairs increment by 2 to keep WordPress and phpMyAdmin ports sequential.

### Changing Ports

If you need to change a site's port:

1. Edit `docker-compose.yml` - update the port mapping
2. Update the site's `.env` file (optional, for documentation)
3. Restart the site:

```bash
docker-compose up -d --force-recreate sitename_wordpress sitename_phpmyadmin
```

## Configuration

Each site has its own `.env` file in `sites/<site-name>/.env`:

```env
# Site Configuration
SITE_NAME=my-site

# Port Configuration
WP_PORT=8082
PMA_PORT=8083

# Database Configuration
DB_NAME=wordpress
DB_USER=wordpress
DB_PASSWORD=wordpress
DB_ROOT_PASSWORD=rootpassword

# WordPress Debug Mode
WP_DEBUG=1
```

### Changing Configuration

1. Edit the `.env` file
2. Update corresponding values in `docker-compose.yml`
3. Restart the site containers

## Troubleshooting

### Port Already in Use

**Error:** `Bind for 0.0.0.0:8082 failed: port is already allocated`

**Solution:**
1. Check what's using the port:
   ```bash
   # Windows
   netstat -ano | findstr :8082

   # Unix/Mac
   lsof -i :8082
   ```
2. Stop the conflicting service or change the port in `docker-compose.yml`

### Database Connection Error

**Error:** `Error establishing a database connection`

**Solutions:**
1. Ensure database container is healthy:
   ```bash
   docker-compose ps
   ```
2. Wait for database to finish initializing (first start takes longer)
3. Check database credentials in `docker-compose.yml`

### Permission Issues

**Error:** Can't write to `wp-content` directory

**Solution:**
```bash
docker-compose exec sitename_wordpress chown -R www-data:www-data /var/www/html/wp-content
```

### Container Won't Start

1. Check logs:
   ```bash
   docker-compose logs sitename_wordpress
   ```
2. Verify port availability
3. Ensure Docker Desktop is running
4. Try recreating the container:
   ```bash
   docker-compose up -d --force-recreate sitename_wordpress
   ```

### Site Shows Wrong Content

This happens if multiple sites share the same WordPress volume name.

**Solution:** Ensure each site in `docker-compose.yml` has unique volume names:
- `sitename_wordpress_data`
- `sitename_db_data`

## Backup and Restore

### Backup Database

```bash
docker-compose exec sitename_db mysqldump -u wordpress -pwordpress wordpress > backup-$(date +%Y%m%d).sql
```

### Restore Database

```bash
docker-compose exec -T sitename_db mysql -u wordpress -pwordpress wordpress < backup-20260125.sql
```

### Backup Files

The `wp-content` directory is already on your filesystem:

```bash
# Create archive
tar -czf sitename-backup-$(date +%Y%m%d).tar.gz sites/sitename/wp-content

# Or use git
cd sites/sitename
git add .
git commit -m "Backup $(date +%Y-%m-%d)"
git push
```

### Restore Files

```bash
# From archive
tar -xzf sitename-backup-20260125.tar.gz -C sites/

# Or from git
cd sites/sitename
git pull
```

## Best Practices

### Version Control

1. **Commit Often**: Regular commits to track changes
2. **Meaningful Messages**: Describe what changed and why
3. **Exclude Uploads**: Never commit `wp-content/uploads/` (large files)
4. **Branch for Features**: Use git branches for major changes
5. **Tag Releases**: Tag stable versions (`git tag v1.0`)

### Security

1. **Change Default Passwords**: Update database passwords in `.env` and `docker-compose.yml`
2. **Disable Debug in Production**: Set `WP_DEBUG=0` in `.env`
3. **Use Strong Admin Passwords**: During WordPress installation
4. **Keep WordPress Updated**: Update via admin dashboard
5. **Don't Commit Secrets**: Add sensitive files to `.gitignore`

### Performance

1. **Stop Unused Sites**: Only run sites you're actively developing
2. **Limit Running Sites**: Don't run all sites simultaneously unless needed
3. **Clean Up**: Periodically remove unused volumes and images
   ```bash
   docker system prune -a
   ```

### Organization

1. **Consistent Naming**: Use clear, descriptive site names
2. **Document Changes**: Update site README when making major changes
3. **Use Branches**: Create branches for experimental features
4. **Remote Backups**: Always push to remote git repository

## Advanced Usage

### Custom PHP Configuration

Create `sites/<site-name>/php.ini` with custom settings, then mount in `docker-compose.yml`:

```yaml
volumes:
  - ./sites/sitename/wp-content:/var/www/html/wp-content
  - ./sites/sitename/php.ini:/usr/local/etc/php/conf.d/custom.ini
```

### WP-CLI Access

```bash
docker-compose exec sitename_wordpress wp --allow-root <command>

# Examples:
docker-compose exec sitename_wordpress wp --allow-root plugin list
docker-compose exec sitename_wordpress wp --allow-root theme list
docker-compose exec sitename_wordpress wp --allow-root user list
```

### Xdebug for Development

Add to WordPress service in `docker-compose.yml`:

```yaml
environment:
  XDEBUG_MODE: debug
  XDEBUG_CONFIG: client_host=host.docker.internal
```

### Multiple Environments

Create environment-specific compose files:

```bash
# Development (default)
docker-compose up -d

# Production simulation
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## Migrating from Existing Setup

If you have the old setup in `wordpress-docker-dev/`:

1. This new setup is independent and lives in `c:/Sites/`
2. Both can coexist without conflicts (different ports)
3. To migrate a site:
   ```bash
   # Copy wp-content
   cp -r wordpress-docker-dev/clients/old-site/wp-content sites/old-site/

   # Export database from old setup
   cd wordpress-docker-dev/clients/old-site
   docker-compose exec db mysqldump -u wordpress -pwordpress wordpress > dump.sql

   # Import to new setup
   cd ../../../../
   docker-compose exec old-site_db mysql -u wordpress -pwordpress wordpress < dump.sql
   ```

## Updating WordPress

WordPress can be updated through the admin dashboard. Updates persist in Docker volumes.

For major updates:
1. Backup database and files
2. Update via WordPress admin
3. Test thoroughly
4. Commit any theme/plugin compatibility fixes

## Contributing

This is a personal development environment setup. Feel free to customize the scripts and configuration for your needs.

## License

This setup is provided as-is for development purposes.

## Support

For issues:
1. Check the Troubleshooting section
2. Review Docker logs
3. Verify Docker Desktop is running
4. Check port availability
5. Ensure git is installed

---

**Happy WordPress Development! 🚀**
