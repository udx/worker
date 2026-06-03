#!/bin/bash

# Test helper functions and common utilities

# Colors and symbols
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'
CHECK="✓"
CROSS="✗"
INFO="ℹ️"
WARN="⚠️"

# Helper functions
print_header() {
    printf "\n${BLUE}=== %s ===${NC}\n" "$1"
}

print_success() {
    printf "${GREEN}%s %s${NC}\n" "$CHECK" "$1"
}

print_error() {
    printf "${RED}%s %s${NC}\n" "$CROSS" "$1"
}

print_info() {
    printf "${BLUE}%s %s${NC}\n" "$INFO" "$1"
}

print_warning() {
    printf "${YELLOW}%s %s${NC}\n" "$WARN" "$1"
}
