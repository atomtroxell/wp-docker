# WordPress Multi-Site Docker - Architecture & Design

## Directory Independence

This tool is designed to be **completely directory-independent**. You can place the `wp-docker` folder anywhere on your system and it will work correctly.

### How It Works

All scripts follow these principles:

1. **Self-Locating**: Each script determines its own location
2. **Config-Driven**: All paths come from config files
3. **No Assumptions**: Scripts never assume their current working directory
4. **Portable**: Works anywhere on any system

### Script Architecture

#### Unix/Mac Scripts (.sh)

Each script follows this pattern:

```bash
#!/bin/bash

# Get script directory (absolute path)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Load configuration from script directory
if [ -f "$SCRIPT_DIR/config.sh" ]; then
    source "$SCRIPT_DIR/config.sh"
else
    # Fallback defaults
    SITES_DIR=".."
    START_PORT=8080
    COMPOSE_FILE="docker-compose.yml"
fi

# Convert relative SITES_DIR to absolute
if [[ "$SITES_DIR" != /* ]]; then
    SITES_DIR="$SCRIPT_DIR/$SITES_DIR"
fi

# All file paths are absolute
COMPOSE_FILE_PATH="$SCRIPT_DIR/$COMPOSE_FILE"
SITE_DIR="$SITES_DIR/$SITE_NAME"
```

#### Windows Scripts (.bat)

Each script follows this pattern:

```batch
@echo off

REM Get script directory (absolute path)
set SCRIPT_DIR=%~dp0
set SCRIPT_DIR=%SCRIPT_DIR:~0,-1%

REM Load configuration from script directory
if exist "%SCRIPT_DIR%\config.bat" (
    call "%SCRIPT_DIR%\config.bat"
) else (
    REM Fallback defaults
    set SITES_DIR=..
    set START_PORT=8080
    set COMPOSE_FILE=docker-compose.yml
)

REM Convert relative path to absolute
if not "%SITES_DIR:~1,1%"==":" (
    set SITES_DIR=%SCRIPT_DIR%\%SITES_DIR%
)

REM All file paths are absolute
set COMPOSE_FILE_PATH=%SCRIPT_DIR%\%COMPOSE_FILE%
set SITE_DIR=%SITES_DIR%\%SITE_NAME%
```

## Configuration System

### config.sh / config.bat

The configuration files define:

```bash
# Where to create WordPress sites
SITES_DIR=".."              # Relative to wp-docker folder
                            # Or absolute: "/home/user/sites"

# Starting port for first site
START_PORT=8080             # Increments by 2 for each site

# Docker Compose file
COMPOSE_FILE="docker-compose.yml"  # In wp-docker directory
```

### Path Resolution

1. **Relative Paths**: Resolved relative to `wp-docker` directory
   - `SITES_DIR=".."` → Parent of wp-docker
   - `SITES_DIR="../sites"` → sites folder next to wp-docker
   - `SITES_DIR="."` → Inside wp-docker (not recommended)

2. **Absolute Paths**: Used as-is
   - Windows: `SITES_DIR="C:\MySites"`
   - Unix/Mac: `SITES_DIR="/home/user/wordpress-sites"`

## Usage Examples

### Example 1: Default Setup

```
/home/user/
├── wp-docker/              # Place anywhere
│   ├── config.sh           # SITES_DIR=".."
│   ├── create-site.sh
│   └── docker-compose.yml
│
└── my-site/                # Created by script
    └── wp-content/
```

**Usage:**
```bash
cd /home/user/wp-docker
./create-site.sh my-site    # Creates /home/user/my-site
```

**Or from anywhere:**
```bash
/home/user/wp-docker/create-site.sh my-site
```

### Example 2: Custom Sites Directory

```
/home/user/
└── tools/
    └── wp-docker/          # Place anywhere
        ├── config.sh       # SITES_DIR="../../../wordpress-sites"
        └── ...

/home/user/wordpress-sites/
└── my-site/                # Created here
    └── wp-content/
```

**Usage:**
```bash
cd /home/user/tools/wp-docker
./create-site.sh my-site    # Creates /home/user/wordpress-sites/my-site
```

### Example 3: Absolute Path

Edit config.sh:
```bash
SITES_DIR="/var/www/wordpress"
```

Now sites are created in `/var/www/wordpress/` regardless of where wp-docker is located.

### Example 4: Run from Anywhere

```bash
# wp-docker can be anywhere
# Can run scripts from any location

# List sites from home directory
cd ~
/opt/wp-docker/list-sites.sh

# Create site from desktop
cd ~/Desktop
/opt/wp-docker/create-site.sh new-site
```

## File Locations

### What Lives in wp-docker/

- `docker-compose.yml` - Container definitions for all sites
- `create-site.sh/.bat` - Site creation scripts
- `list-sites.sh/.bat` - Site listing scripts
- `config.sh/.bat` - Configuration
- `README.md` - Documentation
- `QUICK-START.md` - Quick reference
- `ARCHITECTURE.md` - This file

### What Lives in Site Directories

Created at `SITES_DIR/<site-name>/`:

- `.git/` - Git repository (initialized)
- `.gitignore` - Git ignore rules
- `.env` - Site configuration (ports, credentials)
- `README.md` - Site-specific docs
- `wp-content/` - WordPress content
  - `themes/` - Custom themes
  - `plugins/` - Custom plugins
  - `uploads/` - Media uploads

### What Lives in Docker Volumes

Managed by Docker, persists across restarts:

- `<site-name>_wordpress_data` - WordPress core files
- `<site-name>_db_data` - MySQL database

## Docker Compose Architecture

### Service Naming Convention

Each site gets three services:
- `<site-name>_wordpress` - WordPress container
- `<site-name>_db` - MySQL database
- `<site-name>_phpmyadmin` - Database management

### Network Isolation

Each site has its own isolated network:
- `<site-name>_network`

Services within a site communicate via this network. Sites cannot communicate with each other.

### Volume Strategy

**Named Volumes** (for WordPress core and database):
```yaml
volumes:
  my-site_wordpress_data:
    name: my-site_wordpress_data
  my-site_db_data:
    name: my-site_db_data
```

**Bind Mounts** (for editable content):
```yaml
volumes:
  - ../my-site/wp-content:/var/www/html/wp-content
```

The bind mount path is calculated relative to docker-compose.yml location.

## Path Calculation Details

### create-site.sh Path Logic

1. **Get Script Directory**:
   ```bash
   SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
   # Result: /home/user/wp-docker
   ```

2. **Load Config**:
   ```bash
   source "$SCRIPT_DIR/config.sh"
   # SITES_DIR=".."
   ```

3. **Resolve SITES_DIR**:
   ```bash
   # If relative, make absolute
   if [[ "$SITES_DIR" != /* ]]; then
       SITES_DIR="$SCRIPT_DIR/$SITES_DIR"
   fi
   # Result: /home/user
   ```

4. **Calculate Site Path**:
   ```bash
   SITE_DIR="$SITES_DIR/$SITE_NAME"
   # Result: /home/user/my-site
   ```

5. **Calculate Relative Path for Docker**:
   ```bash
   RELATIVE_SITE_PATH=$(realpath --relative-to="$SCRIPT_DIR" "$SITE_DIR")
   # Result: ../my-site
   ```

6. **Write to docker-compose.yml**:
   ```yaml
   - ../my-site/wp-content:/var/www/html/wp-content
   ```

## Design Benefits

### 1. Portability

Drop `wp-docker` anywhere and it works:
- `/opt/wp-docker`
- `~/tools/wp-docker`
- `C:\Tools\wp-docker`
- Anywhere!

### 2. Flexibility

Configure where sites are created:
- Next to wp-docker (default)
- In a subdirectory
- In a completely different location
- System-wide location

### 3. Team Sharing

Share wp-docker via git:
```bash
git clone https://github.com/team/wp-docker.git
cd wp-docker
./create-site.sh project-name
```

Each team member configures their own `config.sh` for their system.

### 4. Multi-Environment

Same wp-docker folder, different configs:
- Development: `SITES_DIR=~/dev-sites`
- Staging: `SITES_DIR=/var/www/staging`
- Production: Different server entirely

### 5. No Path Hardcoding

Scripts never contain:
- Hardcoded paths
- Assumptions about working directory
- System-specific locations

Everything is calculated at runtime.

## Testing Directory Independence

### Test 1: Run from Different Directory

```bash
cd /tmp
/home/user/wp-docker/list-sites.sh
# Should work correctly
```

### Test 2: Different Config

```bash
cd wp-docker
echo 'SITES_DIR="/tmp/test-sites"' > config.sh
./create-site.sh test
# Should create /tmp/test-sites/test
```

### Test 3: Move wp-docker

```bash
mv ~/wp-docker /opt/wp-docker
/opt/wp-docker/list-sites.sh
# Should still work
```

## Best Practices

### For Users

1. **Don't modify scripts** - Edit `config.sh`/`config.bat` instead
2. **Use relative paths** - Unless you need absolute control
3. **Test your config** - Run `list-sites.sh` to verify
4. **Document your setup** - Note your SITES_DIR in project README

### For Developers

1. **Never hardcode paths** - Always use `SCRIPT_DIR`
2. **Always load config** - With fallback defaults
3. **Calculate paths at runtime** - Don't assume locations
4. **Test from different directories** - Ensure portability
5. **Use absolute paths internally** - Convert relative paths early

## Troubleshooting

### "docker-compose.yml not found"

**Cause**: COMPOSE_FILE points to wrong location

**Solution**: Check `config.sh`:
```bash
COMPOSE_FILE="docker-compose.yml"  # Should be in wp-docker
```

### "Site directory already exists"

**Cause**: SITES_DIR is wrong or site was created before

**Solution**: Check where SITES_DIR points:
```bash
# In create-site.sh, it shows:
# Site location: /actual/path/to/site
```

### Scripts Don't Run

**Unix/Mac**: Make executable
```bash
chmod +x create-site.sh list-sites.sh
```

**Windows**: Verify `.bat` extension

## Summary

The wp-docker tool is designed to be:

- ✅ **Portable** - Works anywhere
- ✅ **Configurable** - Customize via config files
- ✅ **Self-Contained** - No external dependencies
- ✅ **Directory-Independent** - No path assumptions
- ✅ **Team-Friendly** - Easy to share and configure
- ✅ **Maintainable** - Clear, consistent architecture

Place it anywhere, configure it once, use it everywhere.
