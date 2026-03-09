#!/bin/bash

# WordPress Multi-Site Docker Configuration
# Edit this file to customize your setup

# Directory where WordPress sites will be created
# This should be an absolute path or relative to where you run the scripts
# Default: .. (parent directory - same level as wp-docker)
SITES_DIR=".."

# Starting port for WordPress sites
# Each site will use this port + increments of 2
START_PORT=8080

# Docker Compose file location
COMPOSE_FILE="docker-compose.yml"
