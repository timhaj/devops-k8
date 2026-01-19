# Kubernetes Deployment Guide - RPS Betting Game

## Architecture Overview

This deployment consists of:
- **Frontend** (Nginx): 3 replicas for high availability
- **Backend** (Node.js): 3 replicas for high availability  
- **Redis**: 1 replica with persistent storage
- **Ingress**: Nginx Ingress Controller with TLS/SSL
- **Cert-Manager**: Automatic certificate management

## Prerequisites

1. **Kubernetes Cluster** (v1.24+)
   - Minikube, Kind, or cloud provider (GKE, EKS, AKS)
   - At least 4GB RAM and 2 CPUs available

2. **Tools**
   ```bash
   kubectl version --client
   helm version
   ```

3. **Domain Name** (for TLS certificates)
   - Point your domain's A record to your cluster's external IP

## Quick Start

### 1. Install Nginx Ingress Controller

```bash
# For cloud providers (GKE, EKS, AKS)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml

# For Minikube
minikube addons enable ingress

# For Kind
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/kind/deploy.yaml
```

Wait for ingress controller to be ready:
```bash
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

### 2. Update Configuration

Edit the following files with your values:

**k8s/02-redis-deployment.yaml**
```yaml
# Change Redis password
stringData:
  redis-password: "YOUR_SECURE_PASSWORD"
```

**k8s/03-backend-deployment.yaml**
```yaml
# Update with your credentials
stringData:
  SEPOLIA_RPC_URL: "https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY"
  PRIVATE_KEY: "your_private_key_here"
  MNEMONIC: "your mnemonic phrase here"
```

**k8s/05-cert-manager.yaml**
```yaml
# Change email for Let's Encrypt
email: your-email@example.com
```

**k8s/06-ingress.yaml**
```yaml
# Change to your domain
- host: rps-game.yourdomain.com
```

**k8s/03-backend-deployment.yaml & k8s/04-frontend-deployment.yaml**
```yaml
# Update image references
image: ghcr.io/YOUR_GITHUB_USERNAME/rps-betting-game/backend:latest
image: ghcr.io/YOUR_GITHUB_USERNAME/rps-betting-game/frontend:latest
```

### 3. Deploy to Kubernetes

```bash
# Make deploy script executable
chmod +x deploy.sh

# Run deployment
./deploy.sh
```

Or deploy manually:
```bash
kubectl apply -f k8s/00-namespace.yaml
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml
kubectl apply -f k8s/05-cert-manager.yaml
kubectl apply -f k8s/01-redis-pv.yaml
kubectl apply -f k8s/02-redis-deployment.yaml
kubectl apply -f k8s/03-backend-deployment.yaml
kubectl apply -f k8s/04-frontend-deployment.yaml
kubectl apply -f k8s/06-ingress.yaml
```

### 4. Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n rps-game

# Check services
kubectl get svc -n rps-game

# Check ingress
kubectl get ingress -n rps-game

# Check certificate (should show Ready: True after ~2 minutes)
kubectl get certificate -n rps-game
kubectl describe certificate rps-game-tls -n rps-game
```

## Health Probes Configuration

### Why These Values?

#### Redis
- **Liveness**: `initialDelaySeconds: 30` - Redis needs time to load data from disk
- **Readiness**: `initialDelaySeconds: 5` - Quick check if accepting connections
- **Timeout**: `5s` - Redis should respond quickly to PING

#### Backend (Node.js)
- **Liveness**: `initialDelaySeconds: 30` - Node.js app needs time to initialize blockchain connections
- **Readiness**: `initialDelaySeconds: 10` - Shorter delay to serve traffic faster
- **Timeout**: `5s` - Health endpoint is simple and should respond quickly
- **Period**: `10s` for liveness, `5s` for readiness - More frequent readiness checks for faster recovery

#### Frontend (Nginx)
- **Liveness**: `initialDelaySeconds: 10` - Nginx starts very quickly
- **Readiness**: `initialDelaySeconds: 5` - Can serve static files immediately
- **Timeout**: `2-3s` - Nginx is very fast for static content
- **FailureThreshold**: `3` - Allows for temporary issues without killing pods

## Rolling Update Demo

### Current Configuration
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 0  # No pods can be down during update
    maxSurge: 1        # Only 1 extra pod at a time
```

This means:
- With 3 replicas, during update there will be 3-4 pods running
- Updates one pod at a time
- Zero downtime guaranteed

### Performing a Rolling Update

1. **Monitor pods in real-time** (Terminal 1):
```bash
watch kubectl get pods -n rps-game -l app=backend
```

2. **Monitor service availability** (Terminal 2):
```bash
while true; do curl -s https://rps-game.yourdomain.com/api/health && echo " - OK" || echo " - FAIL"; sleep 1; done
```

3. **Update the image** (Terminal 3):
```bash
kubectl set image deployment/backend backend=ghcr.io/YOUR_USERNAME/rps-betting-game/backend:v2.0 -n rps-game
```

**What you'll see:**
- New pod created (4 total)
- New pod becomes ready
- Old pod terminated (back to 3)
- Process repeats for remaining pods
- **No downtime** - service always available

**Expected output from Terminal 1:**
```
NAME                       READY   STATUS    RESTARTS   AGE
backend-5d7c8bf6d9-abc12   1/1     Running   0          5m
backend-5d7c8bf6d9-def34   1/1     Running   0          5m
backend-5d7c8bf6d9-ghi56   1/1     Running   0          5m
backend-789abc1234-jkl78   0/1     Pending   0          0s    ← New pod created
backend-789abc1234-jkl78   0/1     ContainerCreating   0s
backend-789abc1234-jkl78   1/1     Running   0          15s   ← New pod ready
backend-5d7c8bf6d9-abc12   1/1     Terminating   5m    ← Old pod removed
...
```

## Blue-Green Deployment Demo

### Initial State (Blue = Active)
```bash
# Blue deployment running
kubectl get pods -n rps-game -l version=blue
# 3 pods running

# Green deployment not running
kubectl get pods -n rps-game -l version=green
# 0 pods
```

### Steps for Zero-Downtime Blue-Green Switch

1. **Deploy Green version**:
```bash
kubectl apply -f k8s/07-blue-green-deployment.yaml
kubectl scale deployment/frontend-green --replicas=3 -n rps-game
```

2. **Wait for Green to be ready**:
```bash
kubectl wait --for=condition=available --timeout=120s deployment/frontend-green -n rps-game
```

3. **Test Green version** (optional):
```bash
kubectl port-forward deployment/frontend-green 8081:8080 -n rps-game
# Visit http://localhost:8081 to test
```

4. **Switch traffic to Green** (instant cutover):
```bash
kubectl patch service frontend-bluegreen -n rps-game -p '{"spec":{"selector":{"version":"green"}}}'
```

5. **Verify traffic switched**:
```bash
# All traffic now goes to green
curl https://rps-game.yourdomain.com
```

6. **Scale down Blue** (after verifying):
```bash
kubectl scale deployment/frontend-blue --replicas=0 -n rps-game
```

7. **Rollback if needed** (instant):
```bash
kubectl patch service frontend-bluegreen -n rps-game -p '{"spec":{"selector":{"version":"blue"}}}'
kubectl scale deployment/frontend-blue --replicas=3 -n rps-game
```

## CI/CD Pipeline

The GitHub Actions workflow automatically:
1. Builds multi-stage Docker images
2. Pushes to GitHub Container Registry
3. Tags with version, branch, and commit SHA
4. Uses layer caching for faster builds

**Trigger a new build:**
```bash
git add .
git commit -m "Update application"
git push origin main
```

**View build status:**
- Go to GitHub repository → Actions tab
- Images appear at: `ghcr.io/YOUR_USERNAME/rps-betting-game/backend:latest`

## Monitoring & Troubleshooting

### View Logs
```bash
# Backend logs
kubectl logs -f deployment/backend -n rps-game

# Frontend logs
kubectl logs -f deployment/frontend -n rps-game

# Redis logs
kubectl logs -f deployment/redis -n rps-game

# All logs with labels
kubectl logs -l app=backend -n rps-game --tail=100
```

### Check Pod Status
```bash
kubectl describe pod <pod-name> -n rps-game
kubectl get events -n rps-game --sort-by='.lastTimestamp'
```

### Execute Commands in Pods
```bash
# Access backend pod
kubectl exec -it deployment/backend -n rps-game -- sh

# Access Redis
kubectl exec -it deployment/redis -n rps-game -- redis-cli -a YOUR_PASSWORD
```

### Resource Usage
```bash
kubectl top pods -n rps-game
kubectl top nodes
```

## Cleanup

```bash
# Delete namespace (removes everything)
kubectl delete namespace rps-game

# Or delete individually
kubectl delete -f k8s/06-ingress.yaml
kubectl delete -f k8s/04-frontend-deployment.yaml
kubectl delete -f k8s/03-backend-deployment.yaml
kubectl delete -f k8s/02-redis-deployment.yaml
kubectl delete -f k8s/01-redis-pv.yaml
kubectl delete -f k8s/00-namespace.yaml
```

## Production Considerations

### Security
- [ ] Use Kubernetes Secrets (not in YAML)
- [ ] Enable Pod Security Standards
- [ ] Use Network Policies to restrict pod communication
- [ ] Scan images for vulnerabilities
- [ ] Use RBAC for access control

### Monitoring
- [ ] Set up Prometheus + Grafana
- [ ] Configure alerts for pod failures
- [ ] Monitor certificate expiration
- [ ] Track resource usage

### Backup
- [ ] Backup Redis data regularly
- [ ] Backup secrets and configmaps
- [ ] Document disaster recovery procedures

### Scaling
```bash
# Manual scaling
kubectl scale deployment/backend --replicas=5 -n rps-game

# Auto-scaling
kubectl autoscale deployment backend --cpu-percent=70 --min=3 --max=10 -n rps-game
```

## Troubleshooting Common Issues

### Pods not starting
```bash
kubectl describe pod <pod-name> -n rps-game
kubectl logs <pod-name> -n rps-game
```

### Certificate not issued
```bash
kubectl describe certificate rps-game-tls -n rps-game
kubectl describe challenge -n rps-game
kubectl logs -n cert-manager deployment/cert-manager
```

### Service not accessible
```bash
kubectl get svc -n rps-game
kubectl get endpoints -n rps-game
kubectl describe ingress rps-game-ingress -n rps-game
```

## Support

For issues or questions:
1. Check pod logs
2. Review events: `kubectl get events -n rps-game`
3. Verify configurations match your environment