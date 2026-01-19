#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Deploying RPS Betting Game to Kubernetes              ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl not found.${NC}"
    echo -e "${YELLOW}Please run: ./install-prerequisites.sh${NC}"
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster.${NC}"
    echo -e "${YELLOW}Please run: ./setup-k8s-cluster.sh${NC}"
    exit 1
fi

echo -e "${GREEN}✓ kubectl found: $(kubectl version --client --short 2>/dev/null | head -1)${NC}"
echo -e "${GREEN}✓ Cluster connected: $(kubectl config current-context)${NC}"
echo ""

# Create namespace
echo -e "${YELLOW}Creating namespace...${NC}"
kubectl apply -f k8s/00-namespace.yaml

# Check if configuration has been updated
echo -e "${YELLOW}⚠️  Configuration Check${NC}"
if grep -q "YOUR_SECURE_PASSWORD" k8s/02-redis-deployment.yaml 2>/dev/null || \
   grep -q "your_private_key_here" k8s/03-backend-deployment.yaml 2>/dev/null || \
   grep -q "your-email@example.com" k8s/05-cert-manager.yaml 2>/dev/null || \
   grep -q "yourdomain.com" k8s/06-ingress.yaml 2>/dev/null || \
   grep -q "YOUR_USERNAME" k8s/03-backend-deployment.yaml 2>/dev/null; then
    echo -e "${RED}❌ Configuration files contain placeholder values!${NC}"
    echo ""
    echo -e "${YELLOW}Please update the following files:${NC}"
    echo -e "  1. k8s/02-redis-deployment.yaml - Update Redis password"
    echo -e "  2. k8s/03-backend-deployment.yaml - Update blockchain credentials & image name"
    echo -e "  3. k8s/04-frontend-deployment.yaml - Update image name"
    echo -e "  4. k8s/05-cert-manager.yaml - Update email address"
    echo -e "  5. k8s/06-ingress.yaml - Update domain name"
    echo ""
    read -p "Have you updated ALL configuration files? (yes/no): " answer
    if [ "$answer" != "yes" ]; then
        echo -e "${RED}Please update configuration files first!${NC}"
        exit 1
    fi
fi

# Install cert-manager if not already installed
echo -e "${YELLOW}[2/7] Checking cert-manager installation...${NC}"
if kubectl get namespace cert-manager &> /dev/null; then
    echo -e "${GREEN}✓ cert-manager already installed${NC}"
else
    echo -e "${YELLOW}Installing cert-manager...${NC}"
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml
    echo -e "${YELLOW}Waiting for cert-manager to be ready (this may take 1-2 minutes)...${NC}"
    sleep 30
    kubectl wait --for=condition=ready pod -l app=cert-manager -n cert-manager --timeout=300s 2>/dev/null || true
    kubectl wait --for=condition=ready pod -l app=webhook -n cert-manager --timeout=300s 2>/dev/null || true
    echo -e "${GREEN}✓ cert-manager installed${NC}"
fi

# Apply cert-manager issuers
echo -e "${YELLOW}[3/7] Applying cert-manager issuers...${NC}"
kubectl apply -f k8s/05-cert-manager.yaml
echo -e "${GREEN}✓ Issuers configured${NC}"

# Deploy Redis
echo -e "${YELLOW}[4/7] Deploying Redis...${NC}"
kubectl apply -f k8s/01-redis-pv.yaml
kubectl apply -f k8s/02-redis-deployment.yaml
echo -e "${GREEN}✓ Redis deployed${NC}"

# Deploy Backend
echo -e "${YELLOW}[5/7] Deploying Backend (3 replicas)...${NC}"
kubectl apply -f k8s/03-backend-deployment.yaml
echo -e "${GREEN}✓ Backend deployed${NC}"

# Deploy Frontend
echo -e "${YELLOW}[6/7] Deploying Frontend (3 replicas)...${NC}"
kubectl apply -f k8s/04-frontend-deployment.yaml
echo -e "${GREEN}✓ Frontend deployed${NC}"

# Deploy Ingress
echo -e "${YELLOW}[7/7] Deploying Ingress...${NC}"
kubectl apply -f k8s/06-ingress.yaml
echo -e "${GREEN}✓ Ingress deployed${NC}"

# Wait for deployments
echo ""
echo -e "${YELLOW}⏳ Waiting for all deployments to be ready...${NC}"
echo -e "${BLUE}This may take 2-5 minutes depending on image pull times...${NC}"

kubectl wait --for=condition=available --timeout=600s deployment/redis -n rps-game 2>/dev/null || echo -e "${YELLOW}⚠️  Redis still starting...${NC}"
kubectl wait --for=condition=available --timeout=600s deployment/backend -n rps-game 2>/dev/null || echo -e "${YELLOW}⚠️  Backend still starting...${NC}"
kubectl wait --for=condition=available --timeout=600s deployment/frontend -n rps-game 2>/dev/null || echo -e "${YELLOW}⚠️  Frontend still starting...${NC}"

# Get status
echo -e "${GREEN}✅ Deployment complete!${NC}"
echo ""
echo "📊 Deployment Status:"
kubectl get pods -n rps-game
echo ""
echo "🌐 Services:"
kubectl get svc -n rps-game
echo ""
echo "🔐 Ingress:"
kubectl get ingress -n rps-game
echo ""
echo "📝 To view logs:"
echo "  kubectl logs -f deployment/backend -n rps-game"
echo "  kubectl logs -f deployment/frontend -n rps-game"
echo ""
echo "🔍 To check certificate status:"
echo "  kubectl get certificate -n rps-game"
echo "  kubectl describe certificate rps-game-tls -n rps-game"