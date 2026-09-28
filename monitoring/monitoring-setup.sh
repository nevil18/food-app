#!/bin/bash

set -e

echo "================================================"
echo "   Monitoring Setup"
echo "   Prometheus + Grafana"
echo "================================================"


# ─── STEP 1: Install Helm ──────────────────────────────
echo ""
echo "=== Step 1: Checking Helm ==="

if ! command -v helm &> /dev/null; then

    echo "Installing Helm..."

    curl -fsSL -o get_helm.sh \
        https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3

    chmod 700 get_helm.sh

    ./get_helm.sh

    rm -f get_helm.sh

    echo "✅ Helm installed successfully"

else

    echo "✅ Helm already installed"

fi


# ─── STEP 2: Add Prometheus Helm Repository ────────────
echo ""
echo "=== Step 2: Adding Prometheus Helm repository ==="

helm repo add prometheus-community \
    https://prometheus-community.github.io/helm-charts 2>/dev/null || true

helm repo update

echo "✅ Prometheus repository ready"


# ─── STEP 3: Create Prometheus Namespace ───────────────
echo ""
echo "=== Step 3: Creating prometheus namespace ==="

kubectl create namespace prometheus 2>/dev/null || true

echo "✅ Namespace ready"


# ─── STEP 4: Install Prometheus + Grafana ──────────────
# Slimmed down for a small single node:
#  - Alertmanager disabled
#  - Operator admission webhooks disabled (removes hook jobs)
#  - Short Prometheus retention + explicit resource requests
#  - Relaxed probes so a busy node doesn't kill pods
echo ""
echo "=== Step 4: Installing Prometheus + Grafana ==="

helm upgrade --install stable \
    prometheus-community/kube-prometheus-stack \
    -n prometheus \
    --set alertmanager.enabled=false \
    --set prometheusOperator.admissionWebhooks.enabled=false \
    --set prometheus.prometheusSpec.retention=3d \
    --set prometheus.prometheusSpec.resources.requests.cpu=100m \
    --set prometheus.prometheusSpec.resources.requests.memory=400Mi \
    --set kube-state-metrics.resources.requests.cpu=50m \
    --set kube-state-metrics.resources.requests.memory=64Mi \
    --set kube-state-metrics.livenessProbe.timeoutSeconds=10 \
    --set kube-state-metrics.livenessProbe.failureThreshold=5 \
    --set kube-state-metrics.readinessProbe.timeoutSeconds=10 \
    --set kube-state-metrics.readinessProbe.failureThreshold=5 \
    --set grafana.livenessProbe.initialDelaySeconds=120 \
    --set grafana.livenessProbe.failureThreshold=15 \
    --set grafana.readinessProbe.initialDelaySeconds=90 \
    --set grafana.readinessProbe.failureThreshold=15 \
    --set prometheusOperator.livenessProbe.timeoutSeconds=10 \
    --set prometheusOperator.livenessProbe.failureThreshold=5 \
    --set prometheusOperator.readinessProbe.timeoutSeconds=10 \
    --set prometheusOperator.readinessProbe.failureThreshold=5 \
    --set prometheus-node-exporter.livenessProbe.timeoutSeconds=10 \
    --set prometheus-node-exporter.livenessProbe.failureThreshold=5 \
    --set prometheus-node-exporter.readinessProbe.timeoutSeconds=10 \
    --set prometheus-node-exporter.readinessProbe.failureThreshold=5

echo "✅ Prometheus + Grafana installed successfully"


# ─── STEP 5: Wait for Grafana ──────────────────────────
echo ""
echo "=== Step 5: Waiting for Grafana ==="

kubectl wait \
    --namespace prometheus \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/name=grafana \
    --timeout=180s || true

echo "✅ Grafana startup check completed"


# ─── STEP 6: Verify Monitoring ─────────────────────────
echo ""
echo "=== Step 6: Checking monitoring pods ==="

kubectl get pods -n prometheus

echo ""
echo "=== Monitoring services ==="

kubectl get svc -n prometheus


# ─── STEP 7: Get Grafana Password ──────────────────────
echo ""
echo "=== Step 7: Getting Grafana admin password ==="

GRAFANA_PASSWORD=$(kubectl get secret \
    --namespace prometheus \
    stable-grafana \
    -o jsonpath="{.data.admin-password}" | base64 --decode)

echo "✅ Grafana password retrieved"


# ─── STEP 8: Start Grafana Port Forward ────────────────
echo ""
echo "=== Step 8: Starting Grafana port-forward ==="

if pgrep -f "kubectl port-forward.*stable-grafana" > /dev/null; then

    echo "Grafana port-forward is already running"

else

    nohup kubectl port-forward \
        svc/stable-grafana \
        -n prometheus \
        3000:80 \
        --address 0.0.0.0 \
        > /tmp/grafana-port-forward.log 2>&1 &

    echo "✅ Grafana port-forward started"

fi


# ─── STEP 9: Start Prometheus Port Forward ─────────────
echo ""
echo "=== Step 9: Starting Prometheus port-forward ==="

if pgrep -f "kubectl port-forward.*stable-kube-prometheus-sta-prometheus" > /dev/null; then

    echo "Prometheus port-forward is already running"

else

    nohup kubectl port-forward \
        svc/stable-kube-prometheus-sta-prometheus \
        -n prometheus \
        9090:9090 \
        --address 0.0.0.0 \
        > /tmp/prometheus-port-forward.log 2>&1 &

    echo "✅ Prometheus port-forward started"

fi


# ─── STEP 10: Get Public IP ────────────────────────────
echo ""
echo "=== Step 10: Getting server public IP ==="

PUBLIC_IP=$(curl -s --max-time 5 ifconfig.me || echo "<MASTER_PUBLIC_IP>")


# ─── FINAL OUTPUT ──────────────────────────────────────
echo ""
echo "================================================"
echo "   Monitoring Setup Complete!"
echo "================================================"

echo ""
echo "Grafana"
echo "------------------------------------------------"
echo "URL:      http://${PUBLIC_IP}:3000"
echo "Username: admin"
echo "Password: ${GRAFANA_PASSWORD}"

echo ""
echo "Prometheus"
echo "------------------------------------------------"
echo "URL:      http://${PUBLIC_IP}:9090"

echo ""
echo "Port-forward logs:"
echo "Grafana:    /tmp/grafana-port-forward.log"
echo "Prometheus: /tmp/prometheus-port-forward.log"

echo ""
echo "Make sure ports 3000 and 9090 are allowed"
echo "in the server Security Group."

echo ""
echo "================================================"
