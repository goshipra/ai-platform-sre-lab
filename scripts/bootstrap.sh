#!/usr/bin/env bash
set -euo pipefail

readonly CLUSTER_NAME="ai-platform"
readonly ARGOCD_VERSION="v3.1.5"
readonly ARGOCD_MANIFEST="https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"

for command_name in docker kind kubectl; do
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "Missing required command: ${command_name}" >&2
    exit 1
  fi
done

if ! kind get clusters | grep -qx "${CLUSTER_NAME}"; then
  kind create cluster --name "${CLUSTER_NAME}" --config kind/cluster.yaml
fi

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f "${ARGOCD_MANIFEST}"
kubectl rollout status deployment/argocd-server -n argocd --timeout=300s
kubectl apply -f platform/argocd/application.yaml

echo
echo "Bootstrap complete. Argo CD is reconciling the Git repository."
echo "RAG service: http://localhost:8080/healthz"
echo "Argo CD UI: run scripts/argocd-ui.sh"

