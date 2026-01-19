# Quick Start Guide - RPS Betting Game on Kubernetes

## 🎯 What You're Deploying

A blockchain betting game with:
- **3 Frontend pods** (Nginx serving static files)
- **3 Backend pods** (Node.js API with blockchain integration)
- **1 Redis pod** (with persistent storage)
- **HTTPS** (automatic SSL certificates)
- **Zero-downtime** deployments

## 📋 Prerequisites

### Fresh VM Setup (30 minutes)

If you have a **completely fresh Ubuntu VM**, follow the **[SETUP-GUIDE.md](SETUP-GUIDE.md)** for complete step-by-step instructions from scratch.

**Quick summary:**
```bash
# 1. Clone repository
git clone https://github.com/YOUR_USERNAME/rps-betting-game.git
cd rps-betting-game

# 2. Install all prerequisites (Docker, kubectl, Helm, etc.)
chmod +x install-prerequisites.sh
./install-prerequisites.sh
newgrp docker  # Activate Docker group

# 3. Create Kubernetes cluster
chmod +x setup-k8s-cluster.sh
./setup-k8s-cluster.sh

# 4. Update configuration files (see below)

# 5. Deploy
chmod +x deploy.sh
./deploy.sh
```

### Already Have Everything Installed?

If you already have:
- ✅ Docker running
- ✅ kubectl installed
- ✅ Kubernetes cluster available
- ✅ Helm installed (optional)

Skip to **Step 1: Update Configuration** below.

## 🚀 Deployment Steps (10 minutes)

### Step 0: Verify Prerequisites (if already installed)

```bash
# Check Docker
docker version

# Check kubectl
kubectl version --client

# Check cluster access
kubectl get nodes

# If any of these fail, see SETUP-GUIDE.md
```

### Step 1: Update Configuration Files

**Edit these 5 files with your actual values:**

1. `k8s/02-redis-deployment.yaml` - Line 8
   ```yaml
   redis-password: "YOUR_SECURE_PASSWORD"  # ← Change this
   ```

2. `k8s/03-backend-deployment.yaml` - Lines 22-24
   ```yaml
   SEPOLIA_RPC_URL: "https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY"  # ← Change
   PRIVATE_KEY: "your_key"  # ← Change
   MNEMONIC: "your mnemonic"  # ← Change
   ```

3. `k8s/05-cert-manager.yaml` - Line 11
   ```yaml
   email: your-email@example.com  # ← Change this
   ```

4. `k8s/06-ingress.yaml` - Lines 19 & 22
   ```yaml
   - host: rps-game.yourdomain.com  # ← Change this
   ```

5. Update image names in `k8s/03-backend-deployment.yaml` and `k8s/04-frontend-deployment.yaml`
   ```yaml
   image: ghcr.io/YOUR_GITHUB_USERNAME/rps-betting-game/backend:latest
   ```

5. **Update image names** in `k8s/03-backend-deployment.yaml` (line 61) and `k8s/04-frontend-deployment.yaml` (line 31)
   ```yaml
   image: ghcr.io/YOUR_GITHUB_USERNAME/rps-betting-game/backend:latest
   image: ghcr.io/YOUR_GITHUB_USERNAME/rps-betting-game/frontend:latest
   ```

### Step 2: Deploy Everything
```bash
# Make script executable
chmod +x deploy.sh

# Run deployment
./deploy.sh
```

**Or deploy manually:**
```bash
kubectl apply -f k8s/00-namespace.yaml
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml
sleep 30  # Wait for cert-manager
kubectl apply -f k8s/05-cert-manager.yaml
kubectl apply -f k8s/01-redis-pv.yaml
kubectl apply -f k8s/02-redis-deployment.yaml
kubectl apply -f k8s/03-backend-deployment.yaml
kubectl apply -f k8s/04-frontend-deployment.yaml
kubectl apply -f k8s/06-ingress.yaml
```

### Step 3: Verify Deployment
```bash
# Check pods (should see 7 total: 3 frontend, 3 backend, 1 redis)
kubectl get pods -n rps-game

# Check services
kubectl get svc -n rps-game

# Check certificate (wait 2 minutes, then check)
kubectl get certificate -n rps-game
# Should show: rps-game-tls   True
```

### Step 4: Access Your Application
```bash
# Get ingress IP
kubectl get ingress -n rps-game

# Visit in browser
https://rps-game.yourdomain.com
```

## 🔄 Demo: Rolling Update (Zero Downtime)

### Terminal 1: Watch pods update
```bash
watch -n 1 kubectl get pods -n rps-game -l app=backend
```

### Terminal 2: Monitor availability
```bash
while true; do 
  curl -s https://rps-game.yourdomain.com/api/health && echo " ✓" || echo " ✗"
  sleep 1
done
```

### Terminal 3: Trigger update
```bash
# Update backend to new version
kubectl set image deployment/backend \
  backend=ghcr.io/YOUR_USERNAME/rps-betting-game/backend:v2.0 \
  -n rps-game

# Watch the magic happen!
```

**What you'll see:**
```
BEFORE:
backend-xxx-aaa   Running  ← Old version
backend-xxx-bbb   Running  ← Old version
backend-xxx-ccc   Running  ← Old version

DURING:
backend-xxx-aaa   Running  ← Old
backend-xxx-bbb   Running  ← Old
backend-xxx-ccc   Running  ← Old
backend-yyy-ddd   Running  ← NEW (4th pod created)

backend-xxx-bbb   Running  ← Old
backend-xxx-ccc   Running  ← Old
backend-yyy-ddd   Running  ← NEW (old pod removed)
backend-yyy-eee   Running  ← NEW (5th pod created)

... continues until all updated ...

AFTER:
backend-yyy-ddd   Running  ← New version
backend-yyy-eee   Running  ← New version
backend-yyy-fff   Running  ← New version
```

**Result:** ✅ No requests failed, zero downtime!

## 🔵🟢 Demo: Blue-Green Deployment

### Step 1: Deploy green version
```bash
kubectl apply -f k8s/07-blue-green-deployment.yaml
kubectl scale deployment/frontend-green --replicas=3 -n rps-game
```

### Step 2: Test green version (optional)
```bash
kubectl port-forward deployment/frontend-green 8081:8080 -n rps-game
# Visit http://localhost:8081
```

### Step 3: Switch traffic (INSTANT cutover)
```bash
kubectl patch service frontend-bluegreen -n rps-game \
  -p '{"spec":{"selector":{"version":"green"}}}'
```

### Step 4: Verify
```bash
curl https://rps-game.yourdomain.com
# Should show green version
```

### Step 5: Rollback if needed (INSTANT)
```bash
kubectl patch service frontend-bluegreen -n rps-game \
  -p '{"spec":{"selector":{"version":"blue"}}}'
```

## 📊 Monitoring

```bash
# View logs
kubectl logs -f deployment/backend -n rps-game
kubectl logs -f deployment/frontend -n rps-game

# Check resource usage
kubectl top pods -n rps-game

# Get pod details
kubectl describe pod <pod-name> -n rps-game
```

## 🐛 Troubleshooting

### Pods not starting?
```bash
kubectl describe pod <pod-name> -n rps-game
kubectl logs <pod-name> -n rps-game
```

### Certificate not issued?
```bash
# Check certificate status
kubectl describe certificate rps-game-tls -n rps-game

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager

# Common issue: DNS not pointing to cluster IP
nslookup rps-game.yourdomain.com
```

### Can't access application?
```bash
# Get ingress details
kubectl describe ingress rps-game-ingress -n rps-game

# Check services
kubectl get endpoints -n rps-game

# Verify ingress controller
kubectl get pods -n ingress-nginx
```

## 🧹 Cleanup

```bash
# Delete everything
kubectl delete namespace rps-game

# Remove cert-manager (optional)
kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml
```

## 📚 Next Steps

- Read full documentation: `K8S-README.md`
- Check requirements checklist: `REQUIREMENTS-CHECKLIST.md`
- Set up monitoring (Prometheus + Grafana)
- Configure auto-scaling (HPA)
- Add more environments (staging, production)

## 🎥 Recording Your Demo

For the assignment, record:

1. **Terminal showing deployment**
   ```bash
   # Record with asciinema
   asciinema rec deployment-demo.cast
   ./deploy.sh
   # Press Ctrl+D when done
   ```

2. **Rolling update demo**
   - Split screen: pods + availability check
   - Show update command
   - Highlight zero downtime

3. **Blue-green demo**
   - Show blue running
   - Deploy green
   - Instant traffic switch
   - Instant rollback

## ✅ Assignment Checklist

- [ ] 3+ services deployed (frontend, backend, redis)
- [ ] 3+ replicas for HA (frontend: 3, backend: 3)
- [ ] Ingress with TLS working
- [ ] PersistentVolume for Redis
- [ ] Multi-stage Dockerfile used
- [ ] CI/CD pipeline configured
- [ ] Health probes configured
- [ ] Rolling update demonstrated
- [ ] Blue-green deployment demonstrated
- [ ] Documentation complete
- [ ] Screenshots/video recorded

## 🆘 Help

If stuck:
1. Check pod logs: `kubectl logs <pod-name> -n rps-game`
2. Check events: `kubectl get events -n rps-game --sort-by='.lastTimestamp'`
3. Verify configuration files match your setup
4. Ensure domain DNS is pointing to cluster IP
5. Wait 2-3 minutes for certificates to be issued

Good luck! 🚀