#!/bin/bash

# Test script for Docker installation on Rocky Linux 9.6
# This script tests the Docker installation steps from INSTALL-DOCKER.md

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================="
echo "Docker Installation Test for Rocky 9.6"
echo "========================================="

# Function to print colored output
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
        return 1
    fi
}

# Function to check command existence
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check OS version
echo -e "\n${YELLOW}Checking OS version...${NC}"
if [ -f /etc/rocky-release ]; then
    OS_VERSION=$(cat /etc/rocky-release)
    echo "OS: $OS_VERSION"
    if [[ $OS_VERSION == *"9.6"* ]] || [[ $OS_VERSION == *"9."* ]]; then
        print_status 0 "Rocky Linux 9.x detected"
    else
        echo -e "${YELLOW}Warning: This script is optimized for Rocky 9.6${NC}"
    fi
else
    echo -e "${RED}Error: Not running on Rocky Linux${NC}"
    exit 1
fi

# Check prerequisites
echo -e "\n${YELLOW}Checking prerequisites...${NC}"

# Check RAM
TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
if [ $TOTAL_MEM -ge 2000 ]; then
    print_status 0 "RAM: ${TOTAL_MEM}MB (>= 2GB)"
else
    print_status 1 "RAM: ${TOTAL_MEM}MB (< 2GB required)"
fi

# Check disk space
DISK_SPACE=$(df -h / | awk 'NR==2 {print $4}' | sed 's/G//')
echo "Available disk space: ${DISK_SPACE}GB"

# Check internet connectivity
echo -e "\n${YELLOW}Checking internet connectivity...${NC}"
if ping -c 1 download.docker.com &> /dev/null; then
    print_status 0 "Can reach download.docker.com"
else
    print_status 1 "Cannot reach download.docker.com"
fi

# Check if old Docker versions exist
echo -e "\n${YELLOW}Checking for old Docker installations...${NC}"
OLD_PACKAGES=("docker" "docker-client" "docker-client-latest" "docker-common" "docker-latest" "docker-latest-logrotate" "docker-logrotate" "docker-engine" "podman")
FOUND_OLD=0
for pkg in "${OLD_PACKAGES[@]}"; do
    if rpm -qa | grep -q "^$pkg-"; then
        echo -e "${YELLOW}Found: $pkg${NC}"
        FOUND_OLD=1
    fi
done

if [ $FOUND_OLD -eq 0 ]; then
    print_status 0 "No old Docker/Podman packages found"
else
    echo -e "${YELLOW}Old packages found - would be removed during installation${NC}"
fi

# Check if Docker repository is configured
echo -e "\n${YELLOW}Checking Docker repository configuration...${NC}"
if [ -f /etc/yum.repos.d/docker-ce.repo ]; then
    print_status 0 "Docker CE repository configured"

    # Check if it's the correct RHEL repo for Rocky 9
    if grep -q "download.docker.com/linux/rhel" /etc/yum.repos.d/docker-ce.repo; then
        print_status 0 "Using correct RHEL repository for Rocky 9"
    elif grep -q "download.docker.com/linux/centos" /etc/yum.repos.d/docker-ce.repo; then
        echo -e "${YELLOW}Warning: Using CentOS repository - should use RHEL for Rocky 9${NC}"
    fi
else
    echo -e "${YELLOW}Docker CE repository not configured yet${NC}"
fi

# Check if Docker is installed
echo -e "\n${YELLOW}Checking Docker installation...${NC}"
if command_exists docker; then
    DOCKER_VERSION=$(docker --version 2>/dev/null | awk '{print $3}' | sed 's/,//')
    print_status 0 "Docker installed: version $DOCKER_VERSION"

    # Check Docker service status
    if systemctl is-active docker &> /dev/null; then
        print_status 0 "Docker service is running"
    else
        print_status 1 "Docker service is not running"
        echo "  Try: sudo systemctl start docker"
    fi

    if systemctl is-enabled docker &> /dev/null; then
        print_status 0 "Docker service is enabled at boot"
    else
        echo -e "${YELLOW}Docker service not enabled at boot${NC}"
        echo "  Try: sudo systemctl enable docker"
    fi
else
    echo -e "${YELLOW}Docker not installed${NC}"
fi

# Check Docker Compose
echo -e "\n${YELLOW}Checking Docker Compose...${NC}"
if command_exists docker; then
    if docker compose version &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version 2>/dev/null | awk '{print $4}')
        print_status 0 "Docker Compose plugin installed: $COMPOSE_VERSION"
    else
        print_status 1 "Docker Compose plugin not found"
    fi
fi

# Check user group membership
echo -e "\n${YELLOW}Checking user permissions...${NC}"
if id -nG | grep -qw docker; then
    print_status 0 "User $USER is in docker group"
else
    echo -e "${YELLOW}User $USER is not in docker group${NC}"
    echo "  Try: sudo usermod -aG docker \$USER"
    echo "  Then log out and log back in"
fi

# Check SELinux status
echo -e "\n${YELLOW}Checking SELinux configuration...${NC}"
if command_exists getenforce; then
    SELINUX_STATUS=$(getenforce)
    echo "SELinux status: $SELINUX_STATUS"

    if rpm -qa | grep -q container-selinux; then
        print_status 0 "container-selinux package installed"
    else
        echo -e "${YELLOW}container-selinux package not installed${NC}"
        echo "  Try: sudo dnf install -y container-selinux"
    fi
fi

# Test Docker functionality (if installed and running)
echo -e "\n${YELLOW}Testing Docker functionality...${NC}"
if command_exists docker && systemctl is-active docker &> /dev/null; then
    # Test without sudo first
    if docker ps &> /dev/null; then
        print_status 0 "Can run 'docker ps' without sudo"

        # Try hello-world
        echo "Testing hello-world container..."
        if docker run --rm hello-world &> /dev/null; then
            print_status 0 "Successfully ran hello-world container"
        else
            print_status 1 "Failed to run hello-world container"
        fi
    else
        echo -e "${YELLOW}Cannot run docker without sudo - checking with sudo...${NC}"
        if sudo docker ps &> /dev/null; then
            print_status 0 "Can run 'docker ps' with sudo"
            echo "  Add your user to docker group to run without sudo"
        else
            print_status 1 "Docker not working properly"
        fi
    fi
else
    echo "Skipping functionality tests (Docker not running)"
fi

# Summary
echo -e "\n========================================="
echo "Test Summary"
echo "========================================="

ISSUES=0
[ ! -f /etc/rocky-release ] || [[ ! $OS_VERSION == *"9."* ]] && ((ISSUES++))
[ $TOTAL_MEM -lt 2000 ] && ((ISSUES++))
! command_exists docker && ((ISSUES++))
! systemctl is-active docker &> /dev/null && command_exists docker && ((ISSUES++))

if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo "Docker appears to be properly installed and configured."
else
    echo -e "${YELLOW}⚠ Some issues detected${NC}"
    echo "Please review the warnings above and follow the INSTALL-DOCKER.md guide."
fi

echo -e "\nFor full installation instructions, see: INSTALL-DOCKER.md"