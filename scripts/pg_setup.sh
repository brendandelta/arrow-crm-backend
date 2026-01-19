#!/bin/bash
#
# Arrow CRM - PostgreSQL Setup Script
# Idempotent: safe to run multiple times
#
# Creates:
#   - Role: crm2_user (with password crm2_password)
#   - Database: crm2_development
#   - Database: crm2_test
#

set -e

# Configuration (matches database.yml defaults)
DB_USER="crm2_user"
DB_PASSWORD="crm2_password"
DB_DEV="crm2_development"
DB_TEST="crm2_test"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "================================================"
echo "  Arrow CRM - PostgreSQL Setup"
echo "================================================"
echo ""

# Check if psql is available
if ! command -v psql &> /dev/null; then
    echo -e "${RED}Error: psql command not found${NC}"
    echo "Install PostgreSQL: brew install postgresql@16"
    exit 1
fi

# Check Postgres connectivity
echo "Checking PostgreSQL connection..."
if ! psql -h localhost -p 5432 -c "SELECT 1" postgres &> /dev/null; then
    echo -e "${RED}Error: Cannot connect to PostgreSQL${NC}"
    echo ""
    echo "Make sure PostgreSQL is running:"
    echo "  brew services start postgresql@16"
    echo "  # or"
    echo "  pg_ctl -D /usr/local/var/postgres start"
    exit 1
fi
echo -e "${GREEN}✓ PostgreSQL is running${NC}"
echo ""

# Function to run psql as superuser
run_psql() {
    psql -h localhost -p 5432 -d postgres -c "$1" 2>&1
}

# Function to check if role exists
role_exists() {
    psql -h localhost -p 5432 -d postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='$1'" | grep -q 1
}

# Function to check if database exists
db_exists() {
    psql -h localhost -p 5432 -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$1'" | grep -q 1
}

# Try to create role
echo "Setting up role: $DB_USER"
if role_exists "$DB_USER"; then
    echo -e "${GREEN}✓ Role '$DB_USER' already exists${NC}"
else
    echo "Creating role '$DB_USER'..."
    if run_psql "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASSWORD' CREATEDB;" 2>/dev/null; then
        echo -e "${GREEN}✓ Role '$DB_USER' created${NC}"
    else
        echo -e "${YELLOW}⚠ Could not create role (permission denied)${NC}"
        echo ""
        echo "Run these commands manually as a PostgreSQL superuser:"
        echo ""
        echo -e "${YELLOW}  psql postgres${NC}"
        echo -e "${YELLOW}  CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASSWORD' CREATEDB;${NC}"
        echo -e "${YELLOW}  \\q${NC}"
        echo ""
        echo "Or if using Homebrew Postgres, try:"
        echo -e "${YELLOW}  createuser -s $DB_USER${NC}"
        echo -e "${YELLOW}  psql -c \"ALTER ROLE $DB_USER WITH PASSWORD '$DB_PASSWORD';\" postgres${NC}"
        echo ""
        exit 1
    fi
fi

# Create development database
echo ""
echo "Setting up database: $DB_DEV"
if db_exists "$DB_DEV"; then
    echo -e "${GREEN}✓ Database '$DB_DEV' already exists${NC}"
else
    echo "Creating database '$DB_DEV'..."
    if run_psql "CREATE DATABASE $DB_DEV OWNER $DB_USER;" 2>/dev/null; then
        echo -e "${GREEN}✓ Database '$DB_DEV' created${NC}"
    else
        # Try creating as the new user (if they have CREATEDB)
        if PGPASSWORD="$DB_PASSWORD" psql -h localhost -p 5432 -U "$DB_USER" -d postgres -c "CREATE DATABASE $DB_DEV;" 2>/dev/null; then
            echo -e "${GREEN}✓ Database '$DB_DEV' created${NC}"
        else
            echo -e "${RED}Error: Could not create database '$DB_DEV'${NC}"
            exit 1
        fi
    fi
fi

# Create test database
echo ""
echo "Setting up database: $DB_TEST"
if db_exists "$DB_TEST"; then
    echo -e "${GREEN}✓ Database '$DB_TEST' already exists${NC}"
else
    echo "Creating database '$DB_TEST'..."
    if run_psql "CREATE DATABASE $DB_TEST OWNER $DB_USER;" 2>/dev/null; then
        echo -e "${GREEN}✓ Database '$DB_TEST' created${NC}"
    else
        # Try creating as the new user (if they have CREATEDB)
        if PGPASSWORD="$DB_PASSWORD" psql -h localhost -p 5432 -U "$DB_USER" -d postgres -c "CREATE DATABASE $DB_TEST;" 2>/dev/null; then
            echo -e "${GREEN}✓ Database '$DB_TEST' created${NC}"
        else
            echo -e "${RED}Error: Could not create database '$DB_TEST'${NC}"
            exit 1
        fi
    fi
fi

# Grant privileges
echo ""
echo "Granting privileges..."
run_psql "GRANT ALL PRIVILEGES ON DATABASE $DB_DEV TO $DB_USER;" 2>/dev/null || true
run_psql "GRANT ALL PRIVILEGES ON DATABASE $DB_TEST TO $DB_USER;" 2>/dev/null || true
echo -e "${GREEN}✓ Privileges granted${NC}"

# Verify connection as app user
echo ""
echo "Verifying connection as $DB_USER..."
if PGPASSWORD="$DB_PASSWORD" psql -h localhost -p 5432 -U "$DB_USER" -d "$DB_DEV" -c "SELECT current_database(), current_user;" &>/dev/null; then
    echo -e "${GREEN}✓ Connection verified${NC}"
else
    echo -e "${RED}Error: Could not connect as $DB_USER${NC}"
    exit 1
fi

echo ""
echo "================================================"
echo -e "${GREEN}  PostgreSQL setup complete!${NC}"
echo "================================================"
echo ""
echo "Connection details:"
echo "  Host:     localhost"
echo "  Port:     5432"
echo "  User:     $DB_USER"
echo "  Password: $DB_PASSWORD"
echo "  Dev DB:   $DB_DEV"
echo "  Test DB:  $DB_TEST"
echo ""
