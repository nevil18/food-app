#!/bin/bash

set -e

echo "================================================"
echo "   ArgoCD Setup Script"
echo "   Run after DNS is configured"
echo "================================================"

# ─── STEP 1: Verify DNS ───────────────────────────────
echo ""
echo "=== Step 1: Verifying DNS ==="
ARGOCD_IP=$(nslookup argocd.nevilanghan.me 8.8.8.8 | grep Address | tail -1 | awk '{print $2}')
if [ -z "$ARGOCD_IP" ]; then
  echo "❌ DNS not ready for argocd.nevilanghan.me"
  echo "Please update DNS in Namecheap and try again"
  exit 1
fi
echo "✅ DNS resolved: argocd.nevilanghan.me → $ARGOCD_IP"

# ─── STEP 2: Install ArgoCD CLI if not installed ──────
echo ""
echo "=== Step 2: Checking ArgoCD CLI ==="
if ! command -v argocd &> /dev/null; then
  echo "Installing ArgoCD CLI..."
  curl -sSL -o argocd \
    https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
  chmod +x argocd
  sudo mv argocd /usr/local/bin/
  echo "✅ ArgoCD CLI installed"
else
  echo "✅ ArgoCD CLI already installed"
fi

# ─── STEP 3: Get ArgoCD password ──────────────────────
echo ""
echo "=== Step 3: Getting ArgoCD password ==="
ARGOCD_PASSWORD=$(kubectl get secret argocd-initial-admin-secret \
  -n argocd \
  -o jsonpath="{.data.password}" | base64 --decode)
echo "✅ Password retrieved"

# ─── STEP 4: Login to ArgoCD ──────────────────────────
echo ""
echo "=== Step 4: Logging in to ArgoCD ==="
argocd login argocd.nevilanghan.me \
  --username admin \
  --password $ARGOCD_PASSWORD \
  --insecure \
  --grpc-web
echo "✅ Logged in successfully"

# ─── STEP 5: Create project ───────────────────────────
echo ""
echo "=== Step 5: Creating ArgoCD project ==="
argocd proj create food-delivery \
  --description "Food Delivery App" \
  --grpc-web 2>/dev/null || true

# Add source repo
argocd proj add-source food-delivery \
  https://github.com/nevil18/food-app.git \
  --grpc-web 2>/dev/null || true

# Add destination
argocd proj add-destination food-delivery \
  https://kubernetes.default.svc \
  food \
  --grpc-web 2>/dev/null || true

# Allow cluster resources
argocd proj allow-cluster-resource food-delivery "*" "*" \
  --grpc-web 2>/dev/null || true
echo "✅ Project configured"

# ─── STEP 6: Add GitHub repo ──────────────────────────
echo ""
echo "=== Step 6: Adding GitHub repo ==="
argocd repo add https://github.com/nevil18/food-app.git \
  --project food-delivery \
  --grpc-web 2>/dev/null || true
echo "✅ GitHub repo added"

# ─── STEP 7: Create ArgoCD application ───────────────
# Applied directly to the cluster (no dependency on the
# load balancer / DNS). Automated sync deploys it.
echo ""
echo "=== Step 7: Creating ArgoCD application ==="
kubectl apply -f - <<'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: fooddelivery
  namespace: argocd
spec:
  project: food-delivery
  source:
    repoURL: https://github.com/nevil18/food-app.git
    path: k8s
    targetRevision: HEAD
  destination:
    server: https://kubernetes.default.svc
    namespace: food
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
echo "✅ Application created (automated sync will deploy it)"

# ─── STEP 8: Verify ───────────────────────────────────
echo ""
echo "=== Step 8: Verifying ==="
argocd app list --grpc-web

echo ""
echo "================================================"
echo "✅ ArgoCD Setup Complete!"
echo "================================================"
echo "ArgoCD URL : https://argocd.nevilanghan.me"
echo "Username   : admin"
echo "Password   : $ARGOCD_PASSWORD"
echo "================================================"
