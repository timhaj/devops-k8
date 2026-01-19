# Complete Setup Guide - Fresh Ubuntu VM

This guide will take you from a **completely fresh Ubuntu VM** to a fully deployed Kubernetes application.

## 📋 Prerequisites

- Fresh Ubuntu 20.04/22.04 VM
- At least 4GB RAM and 2 CPU cores
- Root or sudo access
- Internet connection

## 🚀 Step-by-Step Installation

### Step 1: Initial System Setup (5 minutes)

```bash
# Update system packages
sudo apt-get update && sudo apt-get upgrade -y

# Install git to clone the repository
sudo apt-get install -y git curl

# Reboot if kernel was updated (optional but recommended)
# sudo reboot
```

### Step 2: Clone Repository (1 minute)

```bash
# Clone your repository
git clone https://github.com/YOUR_USERNAME/rps-betting-game.git
cd rps-betting-game

# Make scripts executable
chmod +x install-prerequisites.sh
chmod +x setup-k8s-cluster.sh
chmod +x deploy.sh
```

### Step 3: Install All Prerequisites (10-15 minutes)

This installs Docker, kubectl, Helm, kind, Node.js, and other tools.

```bash
./install-prerequisites.sh
```

**What gets installed:**
- ✅ Docker (for containers)
- ✅ kubectl (Kubernetes CLI)
- ✅ Helm (Kubernetes package manager)
- ✅ kind (Kubernetes in Docker - for local clusters)
- ✅ Node.js & npm (for development)
- ✅ Additional utilities (jq, vim, htop, etc.)

**After installation completes:**

```bash
# IMPORTANT: Activate Docker group changes
newgrp docker

# Verify installations
docker --version
kubectl version --client
helm version
kind version
node --version
```

### Step 4: Create Kubernetes Cluster (5 minutes)

```bash
./setup-k8s-cluster.sh
```

**What this does:**
- Creates a kind cluster with 1 control-plane + 2 worker nodes
- Installs Nginx Ingress Controller
- Installs cert-manager for SSL certificates
- Configures ports 80 and 443 for web access

**Verify cluster:**
```bash
kubectl get nodes
# Should show 3 nodes: 1 control-plane, 2 workers

kubectl get pods -A
# Should show system pods running
```

### Step 5: Configure Application (5 minutes)

Now you need to update configuration files with your actual values.

#### 5.1 Redis Password
Edit `k8s/02-redis-deployment.yaml` (line 8):
```yaml
stringData:
  redis-password: "MySecurePassword123!"  # ← Change this
```

#### 5.2 Backend Blockchain Credentials
Edit `k8s/03-backend-deployment.yaml` (lines 22-27):
```yaml
stringData:
  SEPOLIA_RPC_URL: "https://eth-sepolia.g.alchemy.com/v2/YOUR_ACTUAL_API_KEY"
  PRIVATE_KEY: "your_actual_private_key_without_0x_prefix"
  MNEMONIC: "your actual mnemonic phrase here"
```

#### 5.3 Update Image Names
Edit `k8s/03-backend-deployment.yaml` (line 61):
```yaml
image: ghcr.io/YOUR_GITHUB_USERNAME/rps-betting-game/backend:latest
```

Edit `k8s/04-frontend-deployment.yaml` (line 31):
```yaml
image: ghcr.io/YOUR_GITHUB_USERNAME/rps-betting-game/frontend:latest
```

#### 5.4 Email for Let's Encrypt
Edit `k8s/05-cert-manager.yaml` (line 11):
```yaml
email: your-real-email@example.com  # ← Change this
```

#### 5.5 Domain Name (for production) or localhost (for testing)

**For local testing with kind:**

Edit `k8s/06-ingress.yaml` (lines 19 & 22):
```yaml
tls:
  - hosts:
    - localhost  # ← Use localhost for local testing
    secretName: rps-game-tls
rules:
  - host: localhost  # ← Use localhost for local testing
```

**For production with real domain:**

1. Point your domain's A record to your server's public IP
2. Edit `k8s/06-ingress.yaml`:
```yaml
tls:
  - hosts:
    - rps-game.yourdomain.com  # ← Your actual domain
    secretName: rps-game-tls
rules:
  - host: rps-game.yourdomain.com  # ← Your actual domain
```

### Step 6: Deploy Application (5 minutes)

```bash
./deploy.sh
```

**What happens:**
1. Creates namespace
2. Deploys Redis with persistent storage
3. Deploys Backend (3 replicas)
4. Deploys Frontend (3 replicas)
5. Configures Ingress
6. Waits for everything to be ready

**Monitor deployment:**
```bash
# In another terminal, watch pods come up
watch kubectl get pods -n rps-game
```

### Step 7: Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n rps-game

# Should see:
# backend-xxx-aaa    1/1  Running
# backend-xxx-bbb    1/1  Running
# backend-xxx-ccc    1/1  Running
# frontend-xxx-ddd   1/1  Running
# frontend-xxx-eee   1/1  Running
# frontend-xxx-fff   1/1  Running
# redis-xxx-ggg      1/1  Running

# Check services
kubectl get svc -n rps-game

# Check ingress
kubectl get ingress -n rps-game

# Check certificate (for real domains)
kubectl get certificate -n rps-game
```

### Step 8: Access Application

**For local testing (kind cluster):**
```bash
# The application is available at:
http://localhost

# Or if using HTTPS:
https://localhost
# (Accept self-signed certificate warning in browser)
```

**For production (real domain):**
```bash
# Access via your domain:
https://rps-game.yourdomain.com

# Wait 2-3 minutes for Let's Encrypt certificate to be issued
kubectl describe certificate rps-game-tls -n rps-game
```

## 🔧 Troubleshooting

### Docker Permission Denied

```bash
# If you see "permission denied" for Docker:
sudo usermod -aG docker $USER
newgrp docker

# Or log out and log back in
```

### Pods Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n rps-game

# Check logs
kubectl logs <pod-name> -n rps-game

# Check events
kubectl get events -n rps-game --sort-by='.lastTimestamp'
```

### Images Not Pulling

```bash
# Check if images exist in your registry
# Make sure you've pushed images via GitHub Actions first

# Or temporarily use pre-built images for testing:
# Replace image names with publicly available ones
```

### Certificate Not Issuing

```bash
# Check certificate status
kubectl describe certificate rps-game-tls -n rps-game

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager

# For local testing, use self-signed certificates or skip TLS
```

## 📊 Monitoring

### View Logs

```bash
# Backend logs
kubectl logs -f deployment/backend -n rps-game

# Frontend logs
kubectl logs -f deployment/frontend -n rps-game

# All pods
kubectl logs -l app=backend -n rps-game --tail=50
```

### Resource Usage

```bash
# Check pod resources
kubectl top pods -n rps-game

# Check node resources
kubectl top nodes
```

### Port Forwarding (for debugging)

```bash
# Access backend directly
kubectl port-forward deployment/backend 3000:3000 -n rps-game
# Then visit: http://localhost:3000/api/health

# Access frontend directly
kubectl port-forward deployment/frontend 8080:8080 -n rps-game
# Then visit: http://localhost:8080
```

## 🧹 Cleanup

### Remove Application
```bash
kubectl delete namespace rps-game
```

### Remove Cluster
```bash
kind delete cluster --name rps-game-cluster
```

### Remove All Software (if needed)
```bash
# Remove Docker
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io
sudo rm -rf /var/lib/docker
sudo rm -rf /etc/docker

# Remove kubectl
sudo rm /usr/local/bin/kubectl

# Remove Helm
sudo rm /usr/local/bin/helm

# Remove kind
sudo rm /usr/local/bin/kind

# Remove Node.js
sudo apt-get purge -y nodejs
sudo apt-get autoremove -y
```

## 📚 Next Steps

After successful deployment:

1. **Test the application**
   - Place a bet
   - Watch the simulation
   - Verify blockchain integration

2. **Try rolling update** (see K8S-README.md)
   - Update backend image
   - Watch zero-downtime deployment

3. **Try blue-green deployment** (see K8S-README.md)
   - Deploy new version
   - Switch traffic instantly
   - Rollback if needed

4. **Set up CI/CD**
   - Push to GitHub
   - Watch automatic builds
   - Deploy new versions

## 🆘 Getting Help

If you encounter issues:

1. Check this guide's troubleshooting section
2. Review K8S-README.md for detailed information
3. Check pod logs: `kubectl logs <pod-name> -n rps-game`
4. Check events: `kubectl get events -n rps-game`
5. Verify all configuration files are updated correctly

## 📝 Summary Checklist

- [ ] System updated
- [ ] Prerequisites installed (Docker, kubectl, etc.)
- [ ] Kubernetes cluster created
- [ ] Configuration files updated
- [ ] Application deployed
- [ ] All pods running
- [ ] Application accessible
- [ ] Rolling update tested
- [ ] Blue-green deployment tested
- [ ] Documentation complete

---

**Estimated Total Time:** 30-40 minutes from fresh VM to running application

Good luck! 🚀