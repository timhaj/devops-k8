#!/bin/bash
set -e

command -v kubectl >/dev/null

kubectl cluster-info >/dev/null

kubectl apply -f k8s/00-namespace.yaml

grep -q "YOUR_SECURE_PASSWORD" k8s/02-redis-deployment.yaml && exit 1
grep -q "your_private_key_here" k8s/03-backend-deployment.yaml && exit 1
grep -q "your-email@example.com" k8s/05-cert-manager.yaml && exit 1
grep -q "yourdomain.com" k8s/06-ingress.yaml && exit 1
grep -q "YOUR_USERNAME" k8s/03-backend-deployment.yaml && exit 1

kubectl get namespace cert-manager >/dev/null || \
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml

sleep 30

kubectl wait --for=condition=ready pod -l app=cert-manager -n cert-manager --timeout=300s || true
kubectl wait --for=condition=ready pod -l app=webhook -n cert-manager --timeout=300s || true

kubectl apply -f k8s/05-cert-manager.yaml

kubectl apply -f k8s/01-redis-pv.yaml
kubectl apply -f k8s/02-redis-deployment.yaml

kubectl apply -f k8s/03-backend-deployment.yaml

kubectl apply -f k8s/04-frontend-deployment.yaml

kubectl apply -f k8s/06-ingress.yaml