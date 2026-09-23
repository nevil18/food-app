#!/bin/bash

set -e

echo "================================================"
echo "   Food Delivery App - Cluster Setup Script"
echo "================================================"

REGION="ap-south-1"
CLUSTER_NAME="food-delivery-eks"

# ─── STEP 1: Connect kubectl ──────────────────────────
echo ""
echo "=== Step 1: Connecting kubectl to EKS ==="
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME
echo "✅ kubectl connected"

# ─── STEP 2: Install Metrics Server ───────────────────
echo ""
echo "=== Step 2: Installing Metrics Server ==="
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
echo "✅ Metrics Server installed"

# ─── STEP 3: Install Nginx Ingress Controller ─────────
echo ""
echo "=== Step 3: Installing Nginx Ingress Controller ==="
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/aws/deploy.yaml
echo "✅ Nginx Ingress Controller installed"

# ─── STEP 4: Make Load Balancer internet-facing ───────
echo ""
echo "=== Step 4: Creating internet-facing Load Balancer ==="
kubectl delete svc ingress-nginx-controller -n ingress-nginx 2>/dev/null || true

cat << 'SVCEOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: ingress-nginx-controller
  namespace: ingress-nginx
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: nlb
    service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: tcp
spec:
  type: LoadBalancer
  selector:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/name: ingress-nginx
  ports:
  - name: http
    port: 80
    targetPort: http
    protocol: TCP
  - name: https
    port: 443
    targetPort: https
    protocol: TCP
  externalTrafficPolicy: Local
SVCEOF
echo "✅ Load Balancer service created"

# ─── STEP 5: Wait for Ingress Controller ──────────────
echo ""
echo "=== Step 5: Waiting for Ingress Controller to be ready ==="
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s
echo "✅ Ingress Controller ready"

# ─── STEP 6: Install cert-manager ─────────────────────
echo ""
echo "=== Step 6: Installing cert-manager ==="
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.0/cert-manager.yaml
echo "Waiting for cert-manager pods..."
kubectl wait --namespace cert-manager \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=cert-manager \
  --timeout=120s
echo "✅ cert-manager installed"

# ─── STEP 7: Install ArgoCD ───────────────────────────
echo ""
echo "=== Step 7: Installing ArgoCD ==="
kubectl create namespace argocd 2>/dev/null || true
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml \
  --server-side --force-conflicts
echo "Waiting for ArgoCD pods..."
kubectl wait --namespace argocd \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=argocd-server \
  --timeout=180s
echo "✅ ArgoCD installed"

# ─── STEP 8: Apply K8s manifests ──────────────────────
echo ""
echo "=== Step 8: Applying Kubernetes manifests ==="
kubectl apply -f ~/web-dev/food_delivery/k8s/namespace.yml
kubectl apply -f ~/web-dev/food_delivery/k8s/backend_secret.yml
kubectl apply -f ~/web-dev/food_delivery/k8s/backend_deployment.yml
kubectl apply -f ~/web-dev/food_delivery/k8s/frontend_deployment.yml
kubectl apply -f ~/web-dev/food_delivery/k8s/admin_deployment.yml
kubectl apply -f ~/web-dev/food_delivery/k8s/backend_service.yml
kubectl apply -f ~/web-dev/food_delivery/k8s/frontend_service.yml
kubectl apply -f ~/web-dev/food_delivery/k8s/admin_service.yml
echo "✅ Manifests applied"

# ─── STEP 9: Apply HPA ────────────────────────────────
echo ""
echo "=== Step 9: Applying HPA ==="
kubectl apply -f ~/web-dev/food_delivery/k8s/backend_hpa.yml
kubectl apply -f ~/web-dev/food_delivery/k8s/frontend_hpa.yml
kubectl apply -f ~/web-dev/food_delivery/k8s/admin_hpa.yml
echo "✅ HPA applied"

# ─── STEP 10: Apply ClusterIssuer ─────────────────────
echo ""
echo "=== Step 10: Applying ClusterIssuer ==="
kubectl apply -f ~/web-dev/food_delivery/k8s/cert_manager.yml
echo "✅ ClusterIssuer applied"

# ─── STEP 11: Apply Ingress ───────────────────────────
echo ""
echo "=== Step 11: Applying Ingress ==="
kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission 2>/dev/null || true
kubectl apply -f ~/web-dev/food_delivery/k8s/ingress.yml
kubectl apply -f ~/web-dev/food_delivery/argocd/argocd-ingress.yml
echo "✅ Ingress applied"

# ─── STEP 12: Get Load Balancer DNS ───────────────────
echo ""
echo "=== Step 12: Getting Load Balancer DNS ==="
sleep 30
LB_DNS=$(kubectl get svc ingress-nginx-controller \
  -n ingress-nginx \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "✅ Load Balancer DNS: $LB_DNS"

# ─── STEP 13: Restart backend ─────────────────────────
echo ""
echo "=== Step 13: Restarting backend ==="
kubectl rollout restart deployment backend-deployment -n food
echo "✅ Backend restarted"

# ─── STEP 14: Verify ──────────────────────────────────
echo ""
echo "=== Step 14: Verifying ==="
kubectl get pods -n food
kubectl get pods -n argocd
kubectl get hpa -n food
kubectl get ingress -n food
kubectl get ingress -n argocd
kubectl get certificate -n food
kubectl get certificate -n argocd

echo ""
echo "================================================"
echo "✅ Setup Complete!"
echo "================================================"
echo "Frontend : https://food.nevilanghan.me"
echo "Admin    : https://food.nevilanghan.me/admin"
echo "API      : https://food.nevilanghan.me/api/food/list"
echo "ArgoCD   : https://argocd.nevilanghan.me"
echo ""
echo "⚠️  IMPORTANT: Update DNS Records in Namecheap"
echo "================================================"
echo "Go to: Namecheap → nevilanghan.me → Advanced DNS"
echo "Update CNAME records:"
echo "  Name: food    Value: $LB_DNS"
echo "  Name: argocd  Value: $LB_DNS"
echo "================================================"
echo ""
echo "After DNS update run:"
echo "  ~/web-dev/argocd-setup.sh"
echo "================================================"
