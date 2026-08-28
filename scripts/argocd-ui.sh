#!/usr/bin/env bash
set -euo pipefail

echo "Argo CD username: admin"
echo -n "Argo CD password: "
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 --decode
echo
echo "Open https://localhost:8443"
kubectl -n argocd port-forward service/argocd-server 8443:443

