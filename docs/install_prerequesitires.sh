#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  RPS Betting Game - Prerequisites Installation Script     ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo ""

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
else
    echo -e "${RED}Cannot detect OS. This script supports Ubuntu/Debian.${NC}"
    exit 1
fi

echo -e "${GREEN}Detected OS: $OS $VER${NC}"
echo ""

# Update system
echo -e "${YELLOW}[1/8] Updating system packages...${NC}"
sudo apt-get update -y
sudo apt-get upgrade -y

# Install basic tools
echo -e "${YELLOW}[2/8] Installing basic tools (curl, wget, git, ca-certificates)...${NC}"
sudo apt-get install -y \
    curl \
    wget \
    git \
    ca-certificates \
    gnupg \
    lsb-release \
    apt-transport-https \
    software-properties-common

# Install Docker
echo -e "${YELLOW}[3/8] Installing Docker...${NC}"
if command -v docker &> /dev/null; then
    echo -e "${GREEN}Docker already installed: $(docker --version)${NC}"
else
    # Add Docker's official GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # Set up the repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Add current user to docker group
    sudo usermod -aG docker $USER

    echo -e "${GREEN}✓ Docker installed: $(docker --version)${NC}"
    echo -e "${YELLOW}⚠️  You may need to log out and back in for docker group changes to take effect${NC}"
fi

# Install kubectl
echo -e "${YELLOW}[4/8] Installing kubectl...${NC}"
if command -v kubectl &> /dev/null; then
    echo -e "${GREEN}kubectl already installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)${NC}"
else
    # Download kubectl
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    
    # Install kubectl
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl

    echo -e "${GREEN}✓ kubectl installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)${NC}"
fi

# Install Helm
echo -e "${YELLOW}[5/8] Installing Helm...${NC}"
if command -v helm &> /dev/null; then
    echo -e "${GREEN}Helm already installed: $(helm version --short)${NC}"
else
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    echo -e "${GREEN}✓ Helm installed: $(helm version --short)${NC}"
fi

# Install kind (Kubernetes in Docker) - for local testing
echo -e "${YELLOW}[6/8] Installing kind (Kubernetes in Docker)...${NC}"
if command -v kind &> /dev/null; then
    echo -e "${GREEN}kind already installed: $(kind version)${NC}"
else
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
    echo -e "${GREEN}✓ kind installed: $(kind version)${NC}"
fi

# Install Node.js and npm (needed for development)
echo -e "${YELLOW}[7/8] Installing Node.js and npm...${NC}"
if command -v node &> /dev/null; then
    echo -e "${GREEN}Node.js already installed: $(node --version)${NC}"
else
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
    echo -e "${GREEN}✓ Node.js installed: $(node --version)${NC}"
    echo -e "${GREEN}✓ npm installed: $(npm --version)${NC}"
fi

# Install additional utilities
echo -e "${YELLOW}[8/8] Installing additional utilities...${NC}"
sudo apt-get install -y \
    jq \
    vim \
    nano \
    htop \
    net-tools \
    iputils-ping \
    dnsutils

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Installation Complete! ✓                      ║${NC}"
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo ""
echo -e "${BLUE}Installed versions:${NC}"
echo -e "  • Docker:    $(docker --version | cut -d' ' -f3)"
echo -e "  • kubectl:   $(kubectl version --client --short 2>/dev/null | cut -d' ' -f3 || kubectl version --client | grep 'Client Version' | awk '{print $3}')"
echo -e "  • Helm:      $(helm version --short | cut -d':' -f2)"
echo -e "  • kind:      $(kind version | cut -d' ' -f2)"
echo -e "  • Node.js:   $(node --version)"
echo -e "  • npm:       $(npm --version)"
echo -e "  • git:       $(git --version | cut -d' ' -f3)"
echo ""
echo -e "${YELLOW}⚠️  Important: If Docker was just installed, please run:${NC}"
echo -e "${YELLOW}   newgrp docker${NC}"
echo -e "${YELLOW}   or log out and log back in for group changes to take effect.${NC}"
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo -e "  1. Clone your repository: ${BLUE}git clone <your-repo-url>${NC}"
echo -e "  2. Create a Kubernetes cluster: ${BLUE}./setup-k8s-cluster.sh${NC}"
echo -e "  3. Deploy the application: ${BLUE}./deploy.sh${NC}"
echo ""