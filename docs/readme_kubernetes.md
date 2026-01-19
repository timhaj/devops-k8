# RPS Betting Game - Kubernetes Edition

A production-ready, highly-available blockchain betting game deployed on Kubernetes with zero-downtime deployments.

## 🎮 What is This?

This is a Rock-Paper-Scissors simulation where autonomous entities battle until only one type remains. Players bet cryptocurrency (test ETH) on which type will win. The application demonstrates:

- **High Availability**: 6 replicas across 2 services
- **Zero-Downtime Deployments**: Rolling updates and blue-green deployments
- **Auto-Scaling**: Ready for horizontal pod autoscaling
- **Persistent Storage**: Redis data survives pod restarts
- **Automatic TLS**: Self-renewing SSL certificates
- **CI/CD Pipeline**: Automated Docker image builds

## 🏗️ Architecture

```
                        Internet
                           |
                      [Ingress + TLS]
                           |
                  ┌────────┴────────┐
                  |                 |
            [Frontend x3]      [Backend x3]
            (Nginx Pods)       (Node.js Pods)
                                    |
                              [Redis x1]
                           (Persistent Storage)
```

**Components:**
- **3 Frontend Pods**: Nginx serving static HTML/JS
- **3 Backend Pods**: Node.js API with Web3 integration
- **1 Redis Pod**: Persistent data storage
- **Ingress**: Nginx with automatic Let's Encrypt certificates
- **cert-manager**: Automatic certificate management

## 🚀 Quick Start

### Option 1: Fresh Ubuntu VM (40 minutes)

Starting from a **completely fresh** Ubuntu 20.04/22.04 VM:

```bash
# 1. Clone repository
git clone https://github.com/YOUR_USERNAME/rps-betting-game.git
cd rps-betting-game

# 2. Install all prerequisites (Docker, kubectl, Helm, kind, Node.js)
chmod +x install-prerequisites.sh
./install-prerequisites.sh

# 3. Activate Docker (IMPORTANT!)
newgrp docker

# 4. Create Kubernetes cluster
chmod +x setup-k8s-cluster.sh
./setup-k8s-cluster.sh

# 5. Edit configuration files (see SETUP-GUIDE.md)
# - k8s/02-redis-deployment.yaml (Redis password)
# - k8s/03-backend-deployment.yaml (Blockchain credentials & image)
# - k8s/04-frontend-deployment.yaml (Image name)
# - k8s/05-cert-manager.yaml (Email)
# - k8s/06-ingress.yaml (Domain or localhost)

# 6. Deploy application
chmod +x deploy.sh
./deploy.sh

# 7. Access application
# Local: http://localhost
# Production: https://your-domain.com
```

**📖 Detailed Instructions**: See [SETUP-GUIDE.md](SETUP-GUIDE.md)

### Option 2: Existing Kubernetes Cluster (10 minutes)

If you already have a Kubernetes cluster:

```bash
# 1. Update configuration files
# 2. Deploy
./deploy.sh
```

**📖 Quick Reference**: See [QUICKSTART.md](QUICKSTART.md)

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| [SETUP-GUIDE.md](SETUP-GUIDE.md) | Complete guide from fresh VM to production |
| [QUICKSTART.md](QUICKSTART.md) | Quick start for experienced users |
| [K8S-README.md](K8S-README.md) | Detailed Kubernetes documentation |
| [REQUIREMENTS-CHECKLIST.md](REQUIREMENTS-CHECKLIST.md) | Assignment requirements tracking |
| [INSTALLATION-CHECKLIST.md](INSTALLATION-CHECKLIST.md) | Installation progress tracking |
| [QUICK-COMMANDS.md](QUICK-COMMANDS.md) | Command reference card |
| [FILES-CREATED.md](FILES-CREATED.md) | Complete list of created files |

## ✅ Requirements Met

All assignment requirements completed:

- ✅ **Ingress with TLS**: Nginx Ingress + cert-manager
- ✅ **3+ Services**: Frontend, Backend, Redis
- ✅ **3+ Replicas for HA**: Frontend (3), Backend (3)
- ✅ **Kubernetes YAML**: All configs in `k8s/` directory
- ✅ **PersistentVolumes**: Redis with 1Gi storage
- ✅ **Multi-stage Builds**: Minimal production images
- ✅ **CI/CD Pipeline**: GitHub Actions automated builds
- ✅ **Health Probes**: Liveness & readiness configured
- ✅ **Rolling Update**: Zero downtime, 1 pod at a time
- ✅ **Blue-Green Deployment**: Instant traffic switching
- ✅ **Complete Documentation**: Multiple guides provided

## 🎬 Demo Videos

### Rolling Update (Zero Downtime)

```bash
# Terminal 1: Watch pods
watch kubectl get pods -n rps-game -l app=backend

# Terminal 2: Monitor availability  
while true; do curl -s http://localhost/api/health && echo " ✓"; sleep 1; done

# Terminal 3: Trigger update
kubectl set image deployment/backend backend=ghcr.io/USER/rps-betting-game/backend:v2 -n rps-game
```

**Result**: All health checks pass during update. No downtime.

### Blue-Green Deployment (Instant Switch)

```bash
# Deploy green version
kubectl scale deployment/frontend-green --replicas=3 -n rps-game

# Switch traffic (instant)
kubectl patch service frontend-bluegreen -n rps-game -p '{"spec":{"selector":{"version":"green"}}}'

# Rollback (instant)
kubectl patch service frontend-bluegreen -n rps-game -p '{"spec":{"selector":{"version":"blue"}}}'
```

**Result**: Instant traffic cutover. Instant rollback capability.

## 🔧 Technology Stack

**Blockchain:**
- Solidity smart contracts
- Web3.js for Ethereum interaction
- MetaMask integration
- Sepolia testnet

**Frontend:**
- HTML5 Canvas for simulation
- Vanilla JavaScript
- Tailwind CSS
- Nginx web server

**Backend:**
- Node.js + Express
- Web3 integration
- RESTful API

**Infrastructure:**
- Kubernetes (kind for local, any cluster for production)
- Docker (multi-stage builds)
- Nginx Ingress Controller
- cert-manager (Let's Encrypt)
- Redis (persistent storage)

**CI/CD:**
- GitHub Actions
- GitHub Container Registry
- Automated builds and tagging

## 📊 Resource Requirements

**Minimum (for local testing):**
- 4GB RAM
- 2 CPU cores
- 20GB disk space

**Production (recommended):**
- 8GB+ RAM
- 4+ CPU cores
- 50GB+ disk space
- Load balancer with public IP

## 🔐 Security Features

- Non-root containers
- Resource limits on all pods
- Secrets for sensitive data
- Network policies (optional)
- TLS/SSL encryption
- Regular security updates via CI/CD

## 📈 Monitoring

```bash
# View pod status
kubectl get pods -n rps-game

# View logs
kubectl logs -f deployment/backend -n rps-game

# View resource usage
kubectl top pods -n rps-game

# View events
kubectl get events -n rps-game
```

## 🐛 Troubleshooting

See detailed troubleshooting in:
- [SETUP-GUIDE.md](SETUP-GUIDE.md) - Common installation issues
- [K8S-README.md](K8S-README.md) - Kubernetes-specific issues
- [QUICK-COMMANDS.md](QUICK-COMMANDS.md) - Debug commands

**Quick fixes:**
```bash
# Pods not starting
kubectl describe pod <pod-name> -n rps-game
kubectl logs <pod-name> -n rps-game

# Ingress not working
kubectl describe ingress rps-game-ingress -n rps-game
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# Certificate issues
kubectl describe certificate rps-game-tls -n rps-game
kubectl logs -n cert-manager deployment/cert-manager
```

## 🧹 Cleanup

```bash
# Remove application only
kubectl delete namespace rps-game

# Remove cluster (kind)
kind delete cluster --name rps-game-cluster

# Remove all software (if needed)
# See SETUP-GUIDE.md for complete removal instructions
```

## 📝 Original Docker Compose

The original Docker Compose deployment is still available:

```bash
# Copy environment file
cp .env.example .env
# Edit .env with your credentials

# Start with Docker Compose
docker-compose up -d
```

See original [README.md](README-ORIGINAL.md) for Docker Compose instructions.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Push to GitHub (triggers CI/CD)
5. Verify builds succeed
6. Test on Kubernetes
7. Submit pull request

## 📄 License

MIT License - see LICENSE file

## 👥 Authors

- Your Name - Kubernetes deployment and infrastructure
- Original Project - RPS Betting Game concept

## 🙏 Acknowledgments

- Kubernetes documentation
- Nginx Ingress Controller
- cert-manager project
- GitHub Actions
- kind (Kubernetes in Docker)

## 📞 Support

- 📖 Documentation: See docs/ directory
- 🐛 Issues: GitHub Issues
- 💬 Discussions: GitHub Discussions

---

**Ready to deploy?** Start with [SETUP-GUIDE.md](SETUP-GUIDE.md)!