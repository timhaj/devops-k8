#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Setting up Kubernetes Cluster with kind               ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo ""

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    echo -e "${RED}Error: kind is not installed. Please run install-prerequisites.sh first.${NC}"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed. Please run install-prerequisites.sh first.${NC}"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}Error: Docker is not running. Please start Docker first.${NC}"
    echo -e "${YELLOW}Try: sudo systemctl start docker${NC}"
    echo -e "${YELLOW}Or:  newgrp docker${NC}"
    exit 1
fi

CLUSTER_NAME="rps-game-cluster"

# Check if cluster already exists
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    echo -e "${YELLOW}Cluster '${CLUSTER_NAME}' already exists.${NC}"
    read -p "Do you want to delete and recreate it? (yes/no): " answer
    if [ "$answer" = "yes" ]; then
        echo -e "${YELLOW}Deleting existing cluster...${NC}"
        kind delete cluster --name ${CLUSTER_NAME}
    else
        echo -e "${GREEN}Using existing cluster.${NC}"
        kubectl cluster-info --context kind-${CLUSTER_NAME}
        exit 0
    fi
fi

# Create kind cluster configuration
echo -e "${YELLOW}[1/5] Creating cluster configuration...${NC}"
cat > kind-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ${CLUSTER_NAME}
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 8080
    protocol: TCP
  - containerPort: 443
    hostPort: 8443
    protocol: TCP
- role: worker
- role: worker
EOF

echo -e "${GREEN}✓ Configuration created${NC}"

# Create the cluster
echo -e "${YELLOW}[2/5] Creating Kubernetes cluster (this may take a few minutes)...${NC}"
kind create cluster --config kind-config.yaml

echo -e "${GREEN}✓ Cluster created successfully${NC}"

# Verify cluster
echo -e "${YELLOW}[3/5] Verifying cluster...${NC}"
kubectl cluster-info --context kind-${CLUSTER_NAME}
echo ""
kubectl get nodes
echo ""

# Install Ingress Controller
echo -e "${YELLOW}[4/5] Installing Nginx Ingress Controller...${NC}"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/kind/deploy.yaml

echo -e "${YELLOW}Waiting for Ingress Controller to be ready (this may take 1-2 minutes)...${NC}"
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

echo -e "${GREEN}✓ Ingress Controller installed${NC}"

# Install cert-manager
echo -e "${YELLOW}[5/5] Installing cert-manager...${NC}"
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml

echo -e "${YELLOW}Waiting for cert-manager to be ready...${NC}"
kubectl wait --for=condition=ready pod \
  -l app=cert-manager \
  -n cert-manager \
  --timeout=300s 2>/dev/null || true

kubectl wait --for=condition=ready pod \
  -l app=webhook \
  -n cert-manager \
  --timeout=300s 2>/dev/null || true

echo -e "${GREEN}✓ cert-manager installed${NC}"

# Clean up config file
rm kind-config.yaml

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           Kubernetes Cluster Ready! ✓                      ║${NC}"
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo ""
echo -e "${BLUE}Cluster Information:${NC}"
echo -e "  • Cluster Name:     ${CLUSTER_NAME}"
echo -e "  • Context:          kind-${CLUSTER_NAME}"
echo -e "  • Nodes:            1 control-plane + 2 workers"
echo -e "  • Ingress:          Nginx (ports 80, 443)"
echo -e "  • Cert-Manager:     Installed"
echo ""
echo -e "${BLUE}Useful commands:${NC}"
echo -e "  • View nodes:       ${YELLOW}kubectl get nodes${NC}"
echo -e "  • View all pods:    ${YELLOW}kubectl get pods -A${NC}"
echo -e "  • Delete cluster:   ${YELLOW}kind delete cluster --name ${CLUSTER_NAME}${NC}"
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo -e "  1. Update configuration files in k8s/ directory"
echo -e "  2. Run: ${BLUE}./deploy.sh${NC}"
echo ""
echo -e "${YELLOW}⚠️  Note: For local testing with kind, you'll need to:${NC}"
echo -e "${YELLOW}   - Use 'localhost' or '127.0.0.1' instead of a real domain${NC}"
echo -e "${YELLOW}   - Or add entries to /etc/hosts for your test domain${NC}"
echo -e "${YELLOW}   - Use self-signed certificates for local testing${NC}"
echo ""