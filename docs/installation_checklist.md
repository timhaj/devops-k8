# Installation Checklist - Fresh VM to Production

Use this checklist to track your progress from fresh VM to deployed application.

## 🖥️ Phase 1: System Preparation (10-15 minutes)

### System Update
- [ ] Connect to your fresh Ubuntu VM
- [ ] Run: `sudo apt-get update && sudo apt-get upgrade -y`
- [ ] Install git: `sudo apt-get install -y git curl`
- [ ] Reboot if kernel updated (optional): `sudo reboot`

### Repository Setup
- [ ] Clone repository: `git clone https://github.com/YOUR_USERNAME/rps-betting-game.git`
- [ ] Enter directory: `cd rps-betting-game`
- [ ] Make scripts executable: `chmod +x *.sh`

## 🔧 Phase 2: Prerequisites Installation (10-15 minutes)

### Run Installation Script
- [ ] Execute: `./install-prerequisites.sh`
- [ ] Wait for completion (takes ~10 minutes)

### Verify Installations
- [ ] Docker: `docker --version` → Should show v24+
- [ ] kubectl: `kubectl version --client` → Should show v1.24+
- [ ] Helm: `helm version` → Should show v3+
- [ ] kind: `kind version` → Should show v0.20+
- [ ] Node.js: `node --version` → Should show v20+
- [ ] npm: `npm --version` → Should show v10+

### Activate Docker
- [ ] Run: `newgrp docker` (or log out/in)
- [ ] Test: `docker ps` (should work without sudo)

## ☸️ Phase 3: Kubernetes Cluster Setup (5 minutes)

### Create Cluster
- [ ] Run: `./setup-k8s-cluster.sh`
- [ ] Wait for cluster creation (~3 minutes)

### Verify Cluster
- [ ] Check nodes: `kubectl get nodes` → Should show 3 nodes
- [ ] Check system pods: `kubectl get pods -A` → All should be Running
- [ ] Check ingress: `kubectl get pods -n ingress-nginx` → Controller Running
- [ ] Check cert-manager: `kubectl get pods -n cert-manager` → 3 pods Running

## ⚙️ Phase 4: Configuration (5 minutes)

### Redis Configuration
- [ ] Edit `k8s/02-redis-deployment.yaml`
- [ ] Line 8: Change `redis-password` to secure password
- [ ] Save file

### Backend Configuration
- [ ] Edit `k8s/03-backend-deployment.yaml`
- [ ] Line 22: Update `SEPOLIA_RPC_URL` with your Alchemy API key
- [ ] Line 23: Update `PRIVATE_KEY` with your wallet private key
- [ ] Line 24: Update `MNEMONIC` with your wallet mnemonic
- [ ] Line 61: Replace `YOUR_GITHUB_USERNAME` with your GitHub username
- [ ] Save file

### Frontend Configuration
- [ ] Edit `k8s/04-frontend-deployment.yaml`
- [ ] Line 31: Replace `YOUR_GITHUB_USERNAME` with your GitHub username
- [ ] Save file

### Certificate Manager Configuration
- [ ] Edit `k8s/05-cert-manager.yaml`
- [ ] Line 11: Update `email` to your real email
- [ ] Line 25: Update `email` again (staging issuer)
- [ ] Save file

### Ingress Configuration
- [ ] Edit `k8s/06-ingress.yaml`
- [ ] **For local testing:**
  - [ ] Line 19: Set to `localhost`
  - [ ] Line 22: Set to `localhost`
- [ ] **For production:**
  - [ ] Line 19: Set to your domain (e.g., `rps-game.yourdomain.com`)
  - [ ] Line 22: Set to your domain
  - [ ] Ensure DNS A record points to cluster IP
- [ ] Save file

## 🚀 Phase 5: Deployment (5 minutes)

### Deploy Application
- [ ] Run: `./deploy.sh`
- [ ] Confirm configuration when prompted
- [ ] Wait for deployment (~3-5 minutes)

### Monitor Deployment
- [ ] In another terminal: `watch kubectl get pods -n rps-game`
- [ ] Wait until all 7 pods show `Running` status:
  - [ ] 3x backend pods
  - [ ] 3x frontend pods
  - [ ] 1x redis pod

## ✅ Phase 6: Verification (5 minutes)

### Check Deployments
- [ ] All pods running: `kubectl get pods -n rps-game`
- [ ] Services created: `kubectl get svc -n rps-game`
- [ ] Ingress configured: `kubectl get ingress -n rps-game`
- [ ] PersistentVolume bound: `kubectl get pvc -n rps-game`

### Check Application Health
- [ ] Backend health: `kubectl logs deployment/backend -n rps-game --tail=20`
- [ ] Frontend health: `kubectl logs deployment/frontend -n rps-game --tail=20`
- [ ] Redis health: `kubectl logs deployment/redis -n rps-game --tail=20`

### Test Access
- [ ] **For local (kind):**
  - [ ] Visit: http://localhost
  - [ ] Should see frontend
  - [ ] Try placing a bet
  
- [ ] **For production:**
  - [ ] Wait 2-3 minutes for certificate
  - [ ] Check certificate: `kubectl get certificate -n rps-game`
  - [ ] Visit: https://your-domain.com
  - [ ] Should see frontend with valid SSL

## 🔄 Phase 7: Demo Preparation (Optional)

### Prepare Rolling Update Demo
- [ ] Open 3 terminals
- [ ] Terminal 1: `watch kubectl get pods -n rps-game -l app=backend`
- [ ] Terminal 2: `while true; do curl -s http://localhost/api/health && echo " ✓"; sleep 1; done`
- [ ] Terminal 3: Ready for update command

### Prepare Blue-Green Demo
- [ ] Apply blue-green config: `kubectl apply -f k8s/07-blue-green-deployment.yaml`
- [ ] Verify blue running: `kubectl get pods -n rps-game -l version=blue`
- [ ] Green at 0 replicas: `kubectl get pods -n rps-game -l version=green`

### Record Demo
- [ ] Install asciinema: `sudo apt-get install -y asciinema`
- [ ] Start recording: `asciinema rec demo.cast`
- [ ] Perform demos
- [ ] Stop recording: Ctrl+D

## 📸 Phase 8: Documentation (Optional)

### Take Screenshots
- [ ] kubectl get pods output
- [ ] kubectl get services output
- [ ] Application in browser
- [ ] Rolling update in progress
- [ ] Blue-green switch

### Update README
- [ ] Add your domain/localhost instructions
- [ ] Add screenshots
- [ ] Add demo video link

## 🎯 Completion Checklist

### Verify All Requirements Met
- [ ] ✅ 3+ services running (frontend, backend, redis)
- [ ] ✅ 3+ replicas for HA (frontend: 3, backend: 3)
- [ ] ✅ Ingress with TLS configured
- [ ] ✅ PersistentVolume for Redis
- [ ] ✅ Multi-stage Dockerfile exists
- [ ] ✅ CI/CD pipeline configured
- [ ] ✅ Health probes configured
- [ ] ✅ Rolling update works
- [ ] ✅ Blue-green deployment works
- [ ] ✅ Documentation complete

### Test Scenarios
- [ ] Application accessible via browser
- [ ] Can place a bet
- [ ] Bet gets processed
- [ ] Simulation runs
- [ ] Results displayed
- [ ] Rolling update: zero downtime
- [ ] Blue-green: instant switch
- [ ] Blue-green: instant rollback

## 🐛 Troubleshooting Quick Reference

### Common Issues

**Docker permission denied**
```bash
newgrp docker
# or
sudo usermod -aG docker $USER && logout
```

**Cluster not accessible**
```bash
kubectl cluster-info
# If fails, recreate cluster:
kind delete cluster --name rps-game-cluster
./setup-k8s-cluster.sh
```

**Pods not starting**
```bash
kubectl describe pod <pod-name> -n rps-game
kubectl logs <pod-name> -n rps-game
```

**Images not pulling**
```bash
# Check if images exist in registry
# Or use public images for testing temporarily
```

**Certificate not issuing**
```bash
kubectl describe certificate rps-game-tls -n rps-game
kubectl logs -n cert-manager deployment/cert-manager
# For local testing, use self-signed or skip TLS
```

## 📊 Time Estimates

- **Phase 1** (System Prep): 10 minutes
- **Phase 2** (Prerequisites): 15 minutes
- **Phase 3** (Cluster Setup): 5 minutes
- **Phase 4** (Configuration): 5 minutes
- **Phase 5** (Deployment): 5 minutes
- **Phase 6** (Verification): 5 minutes
- **Phase 7** (Demo Prep): 10 minutes
- **Phase 8** (Documentation): 15 minutes

**Total: ~70 minutes** from fresh VM to documented, production-ready deployment

## ✅ Final Sign-Off

- [ ] All phases completed
- [ ] All tests passing
- [ ] Demos recorded
- [ ] Documentation updated
- [ ] Ready for submission

---

**Date Completed:** _______________

**Time Taken:** _______________

**Notes:**

_________________________________________

_________________________________________

_________________________________________