#!/bin/bash
set -e

command -v kind >/dev/null
command -v kubectl >/dev/null
docker info >/dev/null

CLUSTER_NAME="rps-game-cluster"

kind get clusters | grep -q "^${CLUSTER_NAME}$" && \
kind delete cluster --name ${CLUSTER_NAME}

cat > kind-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ${CLUSTER_NAME}
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 8080
    protocol: TCP
  - containerPort: 443
    hostPort: 8443
    protocol: TCP
- role: worker
- role: worker
EOF

kind create cluster --config kind-config.yaml

kubectl cluster-info --context kind-${CLUSTER_NAME}
kubectl get nodes

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/kind/deploy.yaml

kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml

kubectl wait --for=condition=ready pod \
  -l app=cert-manager \
  -n cert-manager \
  --timeout=300s || true

kubectl wait --for=condition=ready pod \
  -l app=webhook \
  -n cert-manager \
  --timeout=300s || true

rm kind-config.yaml
