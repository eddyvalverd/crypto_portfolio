#!/bin/bash

# Script to setup and start crypto tracker services
# Creates necessary directories and starts docker-compose

set -e  # Exit on error

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Crypto Tracker Setup ===${NC}\n"

# Create exports directory if it doesn't exist
if [ ! -d "exports" ]; then
    echo -e "${YELLOW}Creating exports directory...${NC}"
    mkdir -p exports
    echo -e "${GREEN}✓ exports directory created${NC}\n"
else
    echo -e "${GREEN}✓ exports directory already exists${NC}\n"
fi

# Start docker-compose services
echo -e "${YELLOW}Starting Docker services...${NC}"
docker-compose up -d

# Check if docker-compose succeeded
if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}✓ All services started successfully!${NC}"
    echo -e "\n${YELLOW}Available services:${NC}"
    echo -e "  - PostgreSQL: ${GREEN}localhost:5432${NC}"
    echo -e "  - pgAdmin: ${GREEN}http://localhost:5050${NC}"
    echo -e "  - CSV exports: ${GREEN}./exports/${NC}"
    echo -e "\n${YELLOW}To view logs:${NC} docker-compose logs -f"
    echo -e "${YELLOW}To stop services:${NC} docker-compose down"
else
    echo -e "\n${RED}✗ Error starting services${NC}"
    exit 1
fi