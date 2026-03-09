@echo off
REM WordPress Multi-Site Docker Configuration
REM Edit this file to customize your setup

REM Directory where WordPress sites will be created
REM This should be an absolute path or relative to where you run the scripts
REM Default: .. (parent directory - same level as wp-docker)
set SITES_DIR=..

REM Starting port for WordPress sites
REM Each site will use this port + increments of 2
set START_PORT=8080

REM Docker Compose file location
set COMPOSE_FILE=docker-compose.yml
