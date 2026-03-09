# WordPress Multi-Site Docker - Quick Start

## Directory Structure

```
c:/Sites/
├── wp-docker/              # Docker configs (you're here)
├── dev/                    # Your WordPress sites (at root level)
├── dadhelpdad/
├── handcrafteddad/
└── example/
```

Sites are created at the **same level** as `wp-docker/`, not nested in a subdirectory.

## Installation (One-time setup)

1. **Ensure Docker Desktop is running**

2. **Start a site:**
   ```bash
   cd c:/Sites/wp-docker
   docker-compose up -d dev_wordpress
   ```

3. **Open WordPress in browser:**
   - WordPress: http://localhost:8082
   - phpMyAdmin: http://localhost:8083

4. **Complete WordPress installation** through the browser wizard

## Create New Site

**Windows:**
```bash
cd c:/Sites/wp-docker
create-site.bat my-site
docker-compose up -d my-site_wordpress
```

**Unix/Mac:**
```bash
cd /c/Sites/wp-docker
./create-site.sh my-site
docker-compose up -d my-site_wordpress
```

This creates the site at `c:/Sites/my-site/` (same level as wp-docker).

## Common Commands

Run these from the `wp-docker` directory:

```bash
# List all sites
./list-sites.sh               # Unix/Mac
list-sites.bat                 # Windows

# Start a site
docker-compose up -d sitename_wordpress

# Stop a site
docker-compose stop sitename_wordpress sitename_db sitename_phpmyadmin

# View logs
docker-compose logs -f sitename_wordpress

# Start all sites
docker-compose up -d

# Stop all sites
docker-compose down
```

## Current Sites

| Site | WordPress URL | phpMyAdmin URL | Location |
|------|---------------|----------------|----------|
| dev | http://localhost:8082 | http://localhost:8083 | `c:/Sites/dev/` |
| dadhelpdad | http://localhost:8084 | http://localhost:8085 | `c:/Sites/dadhelpdad/` |
| handcrafteddad | http://localhost:8086 | http://localhost:8087 | `c:/Sites/handcrafteddad/` |

## Development Workflow

1. **Edit themes/plugins** in `c:/Sites/<sitename>/wp-content/`
2. **Changes are live** - refresh browser to see them
3. **Commit your work:**
   ```bash
   cd c:/Sites/<sitename>
   git add .
   git commit -m "Your changes"
   git push
   ```

## Data Persistence

✅ **Your data is safe!**

- Database stored in Docker volume: `sitename_db_data`
- WordPress core stored in Docker volume: `sitename_wordpress_data`
- Themes/plugins stored in: `c:/Sites/<sitename>/wp-content/`

Data persists even when containers are stopped with `docker-compose down`.

❌ Only `docker-compose down -v` deletes data (the `-v` flag removes volumes)

## Configuration

Edit [config.sh](config.sh) or [config.bat](config.bat) to customize:

```bash
SITES_DIR=".."              # Creates sites in c:/Sites/ (parent of wp-docker)
START_PORT=8080             # Starting port for sites
```

## Documentation

- **This file:** Quick reference
- **[README.md](README.md):** Complete documentation
- **[../README.md](../README.md):** Project overview
- **Site READMEs:** Each site has its own `README.md`

## Troubleshooting

**Port already in use:**
- Change port in `docker-compose.yml`
- Or stop conflicting service

**Container won't start:**
```bash
docker-compose logs sitename_wordpress
```

**Data disappeared:**
- Check if volumes exist: `docker volume ls | grep sitename`
- If you used `docker-compose down -v`, data is gone (restore from backup)
- If you used `docker-compose down`, data is still there - just restart containers

---

**Need help?** Check [README.md](README.md) for full documentation.
