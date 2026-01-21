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

# Kubernetes

## Activate Docker
```bash
newgrp docker
# if that fails 
sudo usermod -aG docker $USER
newgrp docker
```

## Create Kubernetes cluster
```bash
./k8s/deploy.sh
```

## Useful commands
```bash
kubectl version --client
kubectl cluster-info
kubectl get nodes

kubectl get pods -n rps-game

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/kind/deploy.yaml

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml

kubectl apply -f k8s/
kubectl delete -f k8s/
```