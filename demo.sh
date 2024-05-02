#!/bin/bash
#
# bash ./demo.sh

# Color codes for aesthetics
YELLOW='\033[1;33m'
GREY='\033[1;30m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to display formatted output with extra padding
formatted_echo() {
    echo -e "\n\033[1;42;30m $1 ${NC}\n"
}

# Function to echo colored text
colored_echo() {
    echo -e "${1}${2}${NC}\n"
}

# Function to pause between steps
pause() {
    echo -e "${YELLOW}$1${NC}"
    read || echo "Press Enter to continue..."
}

# Listing All Challenges
formatted_echo "UDX Worker addresses the following key challenges in software development for Enterprises:"
colored_echo $YELLOW "1. Security and Compliance"
colored_echo $GREY "Enterprise software development needs mechanisms to control SDLC and ensure compliance."
colored_echo $GREY "It includes managing sensitive data, access controls, and meet compliance requirements."
colored_echo $YELLOW "2. Policy Enforcement and Best Practices Adoption"
colored_echo $GREY "Enterprises need ways to enforce policies and integrate/apply best practices to ensure quality and security."
colored_echo $YELLOW "3. Integration Complexity and Systems Variety"
colored_echo $GREY "Enterprises face challenges in integrating with a variety of tools and systems."

# Features
formatted_echo "Main UDX Features:"

colored_echo $GREEN "- Docker Image"
colored_echo $BLUE "Self-contained, equipped with all necessary tools and modules tooling worker."
colored_echo $BLUE "Can be run on any (virtual) machine with Docker installed."
colored_echo $BLUE "Features:"
colored_echo $GREY "1. Run jobs"
colored_echo $GREY "2. Manage configurations"
colored_echo $GREY "3. Bootstrap and Build new projects"
colored_echo $GREY "4. Run tests and generate reports"
colored_echo $GREY "5. Base Hardened Worker Tooling Image"

colored_echo $GREEN "- CLI"
colored_echo $BLUE "Command-line interface to interact with the worker."
colored_echo $BLUE "Can be used to run jobs, manage configurations, and more."
colored_echo $BLUE "Features:"
colored_echo $GREY "1. Start and stop the worker"
colored_echo $GREY "2. Execute worker commands"
colored_echo $GREY "3. Orchestrating tasks and jobs"


colored_echo $GREEN "- GitHub Actions Integration"
colored_echo $BLUE "GitHub Actions workflow and steps templates to integrate UDX Worker with GitHub Actions."
colored_echo $BLUE "Features:"
colored_echo $GREY "1. Run UDX Worker as a GitHub Action"
colored_echo $GREY "2. Use UDX Worker as container to run jobs in GitHub Actions"
colored_echo $GREY "3. Use UDX Worker to run jobs in GitHub Actions"

colored_echo $GREEN "- Thanks for watching!"

