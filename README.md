# DevOPS - RPS Betting Game

This project demonstrates a fully functional blockchain-based betting game with smart contract technology. Players bet cryptocurrency (test, not real money) on the outcome of an autonomous Rock-Paper-Scissors simulation where they battle until only one type remains.

# Manual installation

## 1. Clone the repository
```bash
git clone https://github.com/timhaj/devops-k8
cd devops-k8
```

## 2. Install all prerequisites
```bash
cd docs
chmod +x install-prerequisites.sh
./install-prerequisites.sh
```
## 3. Activate Docker (IMPORTANT!)
```bash
newgrp docker
# if that fails 
sudo usermod -aG docker $USER
newgrp docker
```
## 4. Create Kubernetes cluster
```bash
chmod +x setup-k8s-cluster.sh
./setup-k8s-cluster.sh
```

## 5. Edit configuration files (see SETUP-GUIDE.md)
### - k8s/02-redis-deployment.yaml (Redis password)
### - k8s/03-backend-deployment.yaml (Blockchain credentials & image)
### - k8s/04-frontend-deployment.yaml (Image name)
### - k8s/05-cert-manager.yaml (Email)
### - k8s/06-ingress.yaml (Domain or localhost)

## 6. Create Kubernetes cluster
```bash
chmod +x deploy.sh
./deploy.sh
```

### 7. Access application
