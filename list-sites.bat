@echo off
setlocal enabledelayedexpansion

REM List all WordPress sites and their ports
REM This script is directory-independent - run from anywhere

REM Get script directory
set SCRIPT_DIR=%~dp0
set SCRIPT_DIR=%SCRIPT_DIR:~0,-1%

REM Load configuration
if exist "%SCRIPT_DIR%\config.bat" (
    call "%SCRIPT_DIR%\config.bat"
) else (
    echo Warning: config.bat not found, using defaults
    set COMPOSE_FILE=docker-compose.yml
)

set COMPOSE_FILE_PATH=%SCRIPT_DIR%\%COMPOSE_FILE%

echo WordPress Multi-Site Overview
echo ==============================
echo.

if not exist "%COMPOSE_FILE_PATH%" (
    echo Error: %COMPOSE_FILE% not found at %COMPOSE_FILE_PATH%
    exit /b 1
)

echo Active Sites:
echo -------------
echo.

REM Header
echo Site Name            WordPress        phpMyAdmin       Status
echo ------------------------------------------------------------------------

REM Parse docker-compose.yml for sites
for /f "tokens=1" %%a in ('findstr /R "^  [a-zA-Z0-9_-]*_wordpress:" "%COMPOSE_FILE_PATH%"') do (
    set line=%%a
    set site=!line:~2,-11!

    REM Get WordPress port
    for /f "tokens=2 delims=:""" %%p in ('findstr /C:"!site!_wordpress:" -A 3 "%COMPOSE_FILE_PATH%" ^| findstr /R "\"[0-9]*:80\""') do (
        set wp_port=%%p
        goto :got_wp_port
    )
    :got_wp_port

    REM Get phpMyAdmin port
    for /f "tokens=2 delims=:""" %%p in ('findstr /C:"!site!_phpmyadmin:" -A 3 "%COMPOSE_FILE_PATH%" ^| findstr /R "\"[0-9]*:80\""') do (
        set pma_port=%%p
        goto :got_pma_port
    )
    :got_pma_port

    REM Check if running
    docker ps --format "{{.Names}}" | findstr /X "!site!_wordpress" >nul 2>&1
    if !errorlevel! equ 0 (
        set status=Running
    ) else (
        set status=Stopped
    )

    echo !site!                localhost:!wp_port!    localhost:!pma_port!    !status!
)

echo.
echo Quick Commands (run from wp-docker directory):
echo   Start site:   docker-compose up -d ^<sitename^>_wordpress
echo   Stop site:    docker-compose stop ^<sitename^>_wordpress ^<sitename^>_db ^<sitename^>_phpmyadmin
echo   View logs:    docker-compose logs -f ^<sitename^>_wordpress
echo   Start all:    docker-compose up -d
echo   Stop all:     docker-compose down
echo.
echo Or run from anywhere with:
echo   cd %SCRIPT_DIR%
echo   docker-compose up -d ^<sitename^>_wordpress
echo.

endlocal
