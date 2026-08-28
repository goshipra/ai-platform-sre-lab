#!/usr/bin/env bash
set -euo pipefail

kubectl wait --for=condition=Available deployment/qdrant -n rag-platform --timeout=180s
kubectl wait --for=condition=Available deployment/rag-service -n rag-platform --timeout=600s
curl --fail --silent http://localhost:8080/healthz
echo
kubectl get application rag-platform -n argocd
kubectl get pods -n rag-platform

