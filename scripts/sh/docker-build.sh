#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if .env file exists and load it
check_env() {
    if [ ! -f .env ]; then
        echo -e "${RED}Error: .env file not found${NC}"
        echo -e "Please create one from .env.example:"
        echo -e "${YELLOW}cp .env.example .env${NC}"
        exit 1
    fi
    
    # Load environment variables
    export $(cat .env | grep -v '^#' | xargs)
}

# Function to validate required environment variables
validate_env() {
    local missing_vars=0
    
    # Required variables array
    declare -a required_vars=(
        "SUPABASE_URL"
        "SUPABASE_ANON_KEY"
        "SUPABASE_SERVICE_ROLE_KEY"
        "POSTGRES_PASSWORD"
        "JWT_SECRET"
    )
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            echo -e "${RED}Error: $var is not set in .env file${NC}"
            missing_vars=1
        fi
    done
    
    if [ $missing_vars -eq 1 ]; then
        exit 1
    fi
}

# Function to build all services
build_services() {
    echo -e "${GREEN}Building all services...${NC}"
    
    # Build with environment variables
    docker compose build \
        --build-arg NEXT_PUBLIC_SUPABASE_URL=$SUPABASE_URL \
        --build-arg NEXT_PUBLIC_SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}All services built successfully!${NC}"
        echo -e "\nYou can now start the services with:"
        echo -e "${YELLOW}docker compose up -d${NC}"
        echo -e "\nAccess the services at:"
        echo -e "Frontend: http://localhost:3001"
        echo -e "Backend API: http://localhost:8000"
        echo -e "Supabase Studio: http://localhost:54323"
        echo -e "N8N Dashboard: http://localhost:5678"
    else
        echo -e "${RED}Error: Failed to build services${NC}"
        exit 1
    fi
}

# Function to build the GoTrue service
build_gotrue_service() {
    echo -e "${GREEN}Building GoTrue service...${NC}"
    docker build -f docker/Dockerfile.gotrue -t orga-ai-gotrue .
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}GoTrue service built successfully!${NC}"
    else
        echo -e "${RED}Error: Failed to build GoTrue service${NC}"
        exit 1
    fi
}

# Main execution
echo -e "${GREEN}Starting build process...${NC}"
check_env
validate_env
build_services
build_gotrue_service