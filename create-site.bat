@echo off
setlocal enabledelayedexpansion

REM WordPress Multi-Site Creator with Automatic Port Detection
REM Usage: create-site.bat <site-name>

REM Get script directory
set SCRIPT_DIR=%~dp0
set SCRIPT_DIR=%SCRIPT_DIR:~0,-1%

REM Load configuration
if exist "%SCRIPT_DIR%\config.bat" (
    call "%SCRIPT_DIR%\config.bat"
) else (
    echo Warning: config.bat not found, using defaults
    set SITES_DIR=..
    set START_PORT=8080
    set COMPOSE_FILE=docker-compose.yml
)

if "%~1"=="" (
    echo Error: Site name is required
    echo Usage: create-site.bat ^<site-name^>
    echo Example: create-site.bat my-client
    exit /b 1
)

set SITE_NAME=%~1

REM Convert relative path to absolute
if not "%SITES_DIR:~1,1%"==":" (
    set SITES_DIR=%SCRIPT_DIR%\%SITES_DIR%
)

set SITE_DIR=%SITES_DIR%\%SITE_NAME%
set COMPOSE_FILE_PATH=%SCRIPT_DIR%\%COMPOSE_FILE%

REM Check if site directory already exists
if exist "%SITE_DIR%" (
    echo Error: Site '%SITE_NAME%' already exists at: %SITE_DIR%
    exit /b 1
)

REM Check if site already exists in docker-compose.yml
findstr /C:"%SITE_NAME%_wordpress:" "%COMPOSE_FILE_PATH%" >nul 2>&1
if %errorlevel% equ 0 (
    echo Error: Site '%SITE_NAME%' already exists in docker-compose.yml!
    exit /b 1
)

echo Creating new WordPress site: %SITE_NAME%

REM Find next available port
set /a WP_PORT=%START_PORT%
set /a PMA_PORT=%START_PORT%+1

REM Extract used ports and find next available
for /f "tokens=2 delims=:""" %%a in ('findstr /R "\"[0-9]*:80\"" "%COMPOSE_FILE_PATH%" 2^>nul') do (
    set /a LAST_PORT=%%a
    if !LAST_PORT! geq !WP_PORT! (
        set /a WP_PORT=LAST_PORT+2
    )
)
set /a PMA_PORT=WP_PORT+1

echo Assigned ports:
echo   WordPress: %WP_PORT%
echo   phpMyAdmin: %PMA_PORT%
echo Site location:
echo   %SITE_DIR%

REM Create directory structure
echo Creating directory structure...
mkdir "%SITE_DIR%\wp-content\themes" 2>nul
mkdir "%SITE_DIR%\wp-content\plugins" 2>nul
mkdir "%SITE_DIR%\wp-content\uploads" 2>nul

REM Create .gitkeep
type nul > "%SITE_DIR%\wp-content\uploads\.gitkeep"

REM Create .env file
(
echo # Site Configuration for %SITE_NAME%
echo SITE_NAME=%SITE_NAME%
echo.
echo # Port Configuration
echo WP_PORT=%WP_PORT%
echo PMA_PORT=%PMA_PORT%
echo.
echo # Database Configuration
echo DB_NAME=wordpress
echo DB_USER=wordpress
echo DB_PASSWORD=wordpress
echo DB_ROOT_PASSWORD=rootpassword
echo.
echo # WordPress Debug Mode
echo WP_DEBUG=1
) > "%SITE_DIR%\.env"

REM Create .gitignore
(
echo # WordPress uploads
echo wp-content/uploads/*
echo !wp-content/uploads/.gitkeep
echo.
echo # Environment files
echo .env.local
echo.
echo # System files
echo .DS_Store
echo Thumbs.db
echo *.swp
echo *~
echo.
echo # IDE files
echo .vscode/
echo .idea/
) > "%SITE_DIR%\.gitignore"

REM Calculate relative path - use Python for reliability across Windows versions
python -c "import os.path; print(os.path.relpath(r'%SITE_DIR%', r'%SCRIPT_DIR%').replace('\', '/'))" > "%TEMP%\relpath.txt" 2>nul
if errorlevel 1 (
    REM Fallback if Python not available - use simple relative path
    set RELATIVE_SITE_PATH=..\sites\%SITE_NAME%
) else (
    set /p RELATIVE_SITE_PATH=<"%TEMP%\relpath.txt"
    del "%TEMP%\relpath.txt"
)

REM Create README
(
echo # %SITE_NAME% WordPress Site
echo.
echo ## Access Points
echo.
echo - **WordPress**: http://localhost:%WP_PORT%
echo - **phpMyAdmin**: http://localhost:%PMA_PORT%
echo.
echo ## Quick Start
echo.
echo All commands should be run from the `wp-docker` directory:
echo.
echo ```bash
echo cd wp-docker
echo.
echo # Start this site
echo docker-compose up -d %SITE_NAME%_wordpress
echo.
echo # Stop this site
echo docker-compose stop %SITE_NAME%_wordpress %SITE_NAME%_db %SITE_NAME%_phpmyadmin
echo.
echo # View logs
echo docker-compose logs -f %SITE_NAME%_wordpress
echo ```
echo.
echo ## Data Persistence
echo.
echo Your data is safe when containers are stopped:
echo.
echo - **Database**: Stored in Docker volume `%SITE_NAME%_db_data`
echo - **WordPress Core**: Stored in Docker volume `%SITE_NAME%_wordpress_data`
echo - **Themes/Plugins/Uploads**: Stored in `wp-content/` directory
echo.
echo Running `docker-compose down` does NOT delete your data.
echo Only `docker-compose down -v` removes volumes.
) > "%SITE_DIR%\README.md"

REM Add site to docker-compose.yml
echo Adding site to docker-compose.yml...
(
echo.
echo   # %SITE_NAME% site
echo   %SITE_NAME%_wordpress:
echo     image: wordpress:latest
echo     restart: unless-stopped
echo     container_name: %SITE_NAME%_wordpress
echo     ports:
echo       - "%WP_PORT%:80"
echo     environment:
echo       WORDPRESS_DB_HOST: %SITE_NAME%_db:3306
echo       WORDPRESS_DB_USER: wordpress
echo       WORDPRESS_DB_PASSWORD: wordpress
echo       WORDPRESS_DB_NAME: wordpress
echo       WORDPRESS_DEBUG: 1
echo     volumes:
echo       - %SITE_NAME%_wordpress_data:/var/www/html
echo       - %RELATIVE_SITE_PATH%/wp-content:/var/www/html/wp-content
echo     depends_on:
echo       %SITE_NAME%_db:
echo         condition: service_healthy
echo     networks:
echo       - %SITE_NAME%_network
echo.
echo   %SITE_NAME%_db:
echo     image: mysql:8.0
echo     restart: unless-stopped
echo     container_name: %SITE_NAME%_db
echo     environment:
echo       MYSQL_DATABASE: wordpress
echo       MYSQL_USER: wordpress
echo       MYSQL_PASSWORD: wordpress
echo       MYSQL_ROOT_PASSWORD: rootpassword
echo     volumes:
echo       - %SITE_NAME%_db_data:/var/lib/mysql
echo     healthcheck:
echo       test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
echo       interval: 10s
echo       timeout: 5s
echo       retries: 5
echo     networks:
echo       - %SITE_NAME%_network
echo.
echo   %SITE_NAME%_phpmyadmin:
echo     image: phpmyadmin:latest
echo     restart: unless-stopped
echo     container_name: %SITE_NAME%_phpmyadmin
echo     ports:
echo       - "%PMA_PORT%:80"
echo     environment:
echo       PMA_HOST: %SITE_NAME%_db
echo       PMA_USER: wordpress
echo       PMA_PASSWORD: wordpress
echo     depends_on:
echo       - %SITE_NAME%_db
echo     networks:
echo       - %SITE_NAME%_network
echo.
echo networks:
echo   %SITE_NAME%_network:
echo     name: %SITE_NAME%_network
echo.
echo volumes:
echo   %SITE_NAME%_wordpress_data:
echo     name: %SITE_NAME%_wordpress_data
echo   %SITE_NAME%_db_data:
echo     name: %SITE_NAME%_db_data
) >> "%COMPOSE_FILE_PATH%"

REM Initialize git repository
echo Initializing git repository...
cd "%SITE_DIR%"
git init
git add .
git commit -m "Initial commit for %SITE_NAME% WordPress site"
cd "%SCRIPT_DIR%"

REM Success message
echo.
echo ✓ Site '%SITE_NAME%' created successfully!
echo.
echo ==============================================================
echo Next steps:
echo ==============================================================
echo.
echo 1. Start the site:
echo    cd wp-docker
echo    docker-compose up -d %SITE_NAME%_wordpress
echo.
echo 2. Access WordPress: http://localhost:%WP_PORT%
echo 3. Access phpMyAdmin: http://localhost:%PMA_PORT%
echo.
echo ==============================================================
echo Data Persistence:
echo ==============================================================
echo.
echo   ✓ Database: %SITE_NAME%_db_data volume
echo   ✓ WordPress core: %SITE_NAME%_wordpress_data volume
echo   ✓ Themes/plugins: %SITE_DIR%\wp-content
echo.
echo   Your data persists when containers are stopped!
echo.

endlocal
