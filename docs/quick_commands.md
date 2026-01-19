# Quick Command Reference

Essential commands for managing your RPS Betting Game Kubernetes deployment.

## 🚀 Initial Setup

```bash
# Full setup from scratch (fresh VM)
git clone https://github.com/YOUR_USERNAME/rps-betting-game.git
cd rps-betting-game
chmod +x *.sh
./install-prerequisites.sh
newgrp docker
./setup-k8s-cluster.sh
# Edit config files (see SETUP-GUIDE.md)
./deploy.sh
```

## 📊 Monitoring Commands

```bash
# View all pods
kubectl get pods -n rps-game

# Watch pods in real-time
watch kubectl get pods -n rps-game

# View services
kubectl get svc -n rps-game

# View ingress
kubectl get ingress -n rps-game

# View persistent volumes
kubectl get pvc -n rps-game

# View certificates
kubectl get certificate -n rps-game

# View all resources
kubectl get all -n rps-game
```

## 📋 Logs & Debugging

```bash
# Backend logs (live)
kubectl logs -f deployment/backend -n rps-game

# Frontend logs (live)
kubectl logs -f deployment/frontend -n rps-game

# Redis logs (live)
kubectl logs -f deployment/redis -n rps-game

# All backend pod logs
kubectl logs -l app=backend -n rps-game --tail=100

# Describe pod (for troubleshooting)
kubectl describe pod <pod-name> -n rps-game

# Get recent events
kubectl get events -n rps-game --sort-by='.lastTimestamp'

# Execute command in pod
kubectl exec -it deployment/backend -n rps-game -- sh

# Port forward for direct access
kubectl port-forward deployment/backend 3000:3000 -n rps-game
kubectl port-forward deployment/frontend 8080:8080 -n rps-game
```

## 🔄 Rolling Update Demo

```bash
# Terminal 1: Watch pods
watch kubectl get pods -n rps-game -l app=backend

# Terminal 2: Monitor availability
while true; do curl -s http://localhost/api/health && echo " ✓" || echo " ✗"; sleep 1; done

# Terminal 3: Trigger update
kubectl set image deployment/backend backend=ghcr.io/YOUR_USERNAME/rps-betting-game/backend:v2.0 -n rps-game

# Check rollout status
kubectl rollout status deployment/backend -n rps-game

# View rollout history
kubectl rollout history deployment/backend -n rps-game

# Rollback if needed
kubectl rollout undo deployment/backend -n rps-game
```

## 🔵🟢 Blue-Green Deployment Demo

```bash
# Apply blue-green configuration
kubectl apply -f k8s/07-blue-green-deployment.yaml

# Check current state
kubectl get pods -n rps-game -l version=blue
kubectl get pods -n rps-game -l version=green

# Scale up green deployment
kubectl scale deployment/frontend-green --replicas=3 -n rps-game

# Wait for green to be ready
kubectl wait --for=condition=available deployment/frontend-green -n rps-game --timeout=120s

# Test green version (optional)
kubectl port-forward deployment/frontend-green 8081:8080 -n rps-game

# Switch traffic to green (INSTANT)
kubectl patch service frontend-bluegreen -n rps-game -p '{"spec":{"selector":{"version":"green"}}}'

# Verify switch
kubectl describe service frontend-bluegreen -n rps-game | grep Selector

# Rollback to blue if needed (INSTANT)
kubectl patch service frontend-bluegreen -n rps-game -p '{"spec":{"selector":{"version":"blue"}}}'

# Scale down old version
kubectl scale deployment/frontend-blue --replicas=0 -n rps-game
```

## ⚙️ Scaling Commands

```bash
# Manual scaling
kubectl scale deployment/backend --replicas=5 -n rps-game
kubectl scale deployment/frontend --replicas=5 -n rps-game

# Auto-scaling (HPA)
kubectl autoscale deployment backend --cpu-percent=70 --min=3 --max=10 -n rps-game

# Check HPA status
kubectl get hpa -n rps-game
```

## 🔍 Resource Management

```bash
# Check resource usage
kubectl top pods -n rps-game
kubectl top nodes

# Edit deployment
kubectl edit deployment/backend -n rps-game

# Update image
kubectl set image deployment/backend backend=newimage:tag -n rps-game

# Update environment variable
kubectl set env deployment/backend REDIS_HOST=new-redis-host -n rps-game
```

## 🔐 Secrets & ConfigMaps

```bash
# View secrets
kubectl get secrets -n rps-game

# View secret details (base64 encoded)
kubectl get secret backend-secret -n rps-game -o yaml

# Decode secret
kubectl get secret backend-secret -n rps-game -o jsonpath='{.data.PRIVATE_KEY}' | base64 -d

# View configmaps
kubectl get configmap -n rps-game

# Edit configmap
kubectl edit configmap backend-config -n rps-game

# Restart pods to pick up config changes
kubectl rollout restart deployment/backend -n rps-game
```

## 🌐 Ingress & Networking

```bash
# View ingress details
kubectl describe ingress rps-game-ingress -n rps-game

# View ingress controller logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# Test service endpoints
kubectl get endpoints -n rps-game

# Test service resolution
kubectl run test-pod --image=busybox -i --tty --rm -n rps-game -- nslookup backend
```

## 📜 Certificate Management

```bash
# Check certificate status
kubectl get certificate -n rps-game
kubectl describe certificate rps-game-tls -n rps-game

# Check certificate request
kubectl get certificaterequest -n rps-game

# Check ACME challenge
kubectl get challenge -n rps-game

# View cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager

# Delete and recreate certificate
kubectl delete certificate rps-game-tls -n rps-game
kubectl apply -f k8s/06-ingress.yaml
```

## 🔄 Update Application

```bash
# Pull latest code
git pull origin main

# Rebuild and push images (via GitHub Actions)
git commit -am "Update application"
git push origin main

# Or build locally and push
docker build -t ghcr.io/YOUR_USERNAME/rps-betting-game/backend:latest -f Dockerfile.backend.multistage .
docker push ghcr.io/YOUR_USERNAME/rps-betting-game/backend:latest

# Force pull new image
kubectl rollout restart deployment/backend -n rps-game

# Wait for rollout
kubectl rollout status deployment/backend -n rps-game
```

## 🧹 Cleanup Commands

```bash
# Delete application (keeps cluster)
kubectl delete namespace rps-game

# Delete cluster
kind delete cluster --name rps-game-cluster

# Delete cert-manager
kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml

# Delete ingress controller
kubectl delete namespace ingress-nginx

# Full reset (everything)
kind delete cluster --name rps-game-cluster
docker system prune -a --volumes -f
```

## 🐛 Emergency Troubleshooting

```bash
# Pod stuck in pending
kubectl describe pod <pod-name> -n rps-game

# Pod crashing
kubectl logs <pod-name> -n rps-game --previous
kubectl describe pod <pod-name> -n rps-game

# Service not accessible
kubectl get endpoints -n rps-game
kubectl describe service backend -n rps-game

# Image pull errors
kubectl describe pod <pod-name> -n rps-game
# Check Events section for image pull errors

# DNS not working
kubectl run test-pod --image=busybox -i --tty --rm -n rps-game -- nslookup kubernetes.default

# Storage issues
kubectl get pvc -n rps-game
kubectl describe pvc redis-pvc -n rps-game

# Delete stuck pod
kubectl delete pod <pod-name> -n rps-game --force --grace-period=0

# Delete stuck namespace
kubectl get namespace rps-game -o json | jq '.spec.finalizers = []' | kubectl replace --raw "/api/v1/namespaces/rps-game/finalize" -f -
```

## 📊 Resource Quotas & Limits

```bash
# View resource usage
kubectl describe node

# View pod resource requests/limits
kubectl describe pod <pod-name> -n rps-game | grep -A 5 "Limits:\|Requests:"

# Check if pods are being throttled
kubectl top pods -n rps-game --containers
```

## 🎬 Recording Demos

```bash
# Install asciinema
sudo apt-get install -y asciinema

# Start recording
asciinema rec deployment-demo.cast

# Do your demo...

# Stop recording (Ctrl+D)

# Play recording
asciinema play deployment-demo.cast

# Upload to asciinema.org
asciinema upload deployment-demo.cast
```

## 📁 File Operations

```bash
# Copy files to pod
kubectl cp local-file.txt rps-game/pod-name:/tmp/

# Copy files from pod
kubectl cp rps-game/pod-name:/tmp/file.txt ./local-file.txt

# Create configmap from file
kubectl create configmap my-config --from-file=config.json -n rps-game
```

## 🔧 Cluster Management

```bash
# View cluster info
kubectl cluster-info
kubectl version

# View all namespaces
kubectl get namespaces

# View all resources across all namespaces
kubectl get all -A

# Change context (if multiple clusters)
kubectl config get-contexts
kubectl config use-context <context-name>

# View current context
kubectl config current-context
```

## 💾 Backup & Restore

```bash
# Backup namespace
kubectl get all -n rps-game -o yaml > backup.yaml

# Backup persistent volume data (exec into pod)
kubectl exec -it deployment/redis -n rps-game -- redis-cli --rdb /data/dump.rdb
kubectl cp rps-game/redis-xxx:/data/dump.rdb ./redis-backup.rdb

# Restore from backup
kubectl apply -f backup.yaml
```

---

## 🔖 Bookmarks

**Essential URLs:**
- Kind docs: https://kind.sigs.k8s.io/
- kubectl cheatsheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Ingress-nginx docs: https://kubernetes.github.io/ingress-nginx/
- cert-manager docs: https://cert-manager.io/docs/

**Your application:**
- Local: http://localhost
- Production: https://your-domain.com
- GitHub repo: https://github.com/YOUR_USERNAME/rps-betting-game