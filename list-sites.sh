#!/bin/bash

# List all WordPress sites and their ports
# This script is directory-independent - run from anywhere

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Load configuration
if [ -f "$SCRIPT_DIR/config.sh" ]; then
    source "$SCRIPT_DIR/config.sh"
else
    echo "Warning: config.sh not found, using defaults"
    COMPOSE_FILE="docker-compose.yml"
fi

COMPOSE_FILE_PATH="$SCRIPT_DIR/$COMPOSE_FILE"

echo "WordPress Multi-Site Overview"
echo "=============================="
echo ""

if [ ! -f "$COMPOSE_FILE_PATH" ]; then
    echo "Error: $COMPOSE_FILE not found at $COMPOSE_FILE_PATH"
    exit 1
fi

# Extract site information
sites=$(grep -oP '^\s+\K[a-zA-Z0-9_-]+(?=_wordpress:)' "$COMPOSE_FILE_PATH" | sort)

if [ -z "$sites" ]; then
    echo "No sites found in docker-compose.yml"
    exit 0
fi

echo "Active Sites:"
echo "-------------"
printf "%-20s %-15s %-15s %-10s\n" "Site Name" "WordPress" "phpMyAdmin" "Status"
echo "------------------------------------------------------------------------"

for site in $sites; do
    # Get WordPress port
    wp_port=$(grep -A 3 "^  ${site}_wordpress:" "$COMPOSE_FILE_PATH" | grep -oP '"\K[0-9]+(?=:80")' | head -1)

    # Get phpMyAdmin port
    pma_port=$(grep -A 3 "^  ${site}_phpmyadmin:" "$COMPOSE_FILE_PATH" | grep -oP '"\K[0-9]+(?=:80")' | head -1)

    # Check if containers are running
    if docker ps --format '{{.Names}}' | grep -q "^${site}_wordpress$"; then
        status="Running"
    else
        status="Stopped"
    fi

    printf "%-20s %-15s %-15s %-10s\n" \
        "$site" \
        "localhost:$wp_port" \
        "localhost:$pma_port" \
        "$status"
done

echo ""
echo "Quick Commands (run from wp-docker directory):"
echo "  Start site:   docker-compose up -d <sitename>_wordpress"
echo "  Stop site:    docker-compose stop <sitename>_wordpress <sitename>_db <sitename>_phpmyadmin"
echo "  View logs:    docker-compose logs -f <sitename>_wordpress"
echo "  Start all:    docker-compose up -d"
echo "  Stop all:     docker-compose down"
echo ""
echo "Or run from anywhere with:"
echo "  cd $SCRIPT_DIR"
echo "  docker-compose up -d <sitename>_wordpress"
echo ""
