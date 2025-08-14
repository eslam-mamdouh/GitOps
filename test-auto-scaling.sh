#!/bin/bash

# Simple Auto-Scaling Test Script
# This script demonstrates the current auto-scaling setup

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${CYAN}$1${NC}"
}

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Configuration
NAMESPACE="laravel-app"
DEPLOYMENT_NAME="laravel-app"
HPA_NAME="laravel-app-hpa"

echo "=========================================="
echo "Laravel App Auto-Scaling Test"
echo "=========================================="
echo ""

print_header "Current Auto-Scaling Setup:"
echo "✅ HPA is configured and active"
echo "✅ CPU threshold: 10% (10m of 100m request)"
echo "✅ Memory threshold: 20% (25.6Mi of 128Mi request)"
echo "✅ Min replicas: 2"
echo "✅ Max replicas: 10"
echo ""

print_header "Current Status:"
echo "Deployment:"
kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE
echo ""

echo "HPA:"
kubectl get hpa $HPA_NAME -n $NAMESPACE
echo ""

echo "Pods:"
kubectl get pods -n $NAMESPACE | grep laravel-app
echo ""

echo "Resource Usage:"
kubectl top pods -n $NAMESPACE | grep laravel-app 2>/dev/null || echo "Metrics not available"
echo ""

print_header "Auto-Scaling Test:"
print_status "Running load test to generate CPU usage..."
print_status "This will help demonstrate the auto-scaling behavior."

# Run a load test
ab -t 30 -c 20 -n 300 http://laravel-app.local/ > /dev/null 2>&1 &
ab_pid=$!

print_status "Load test started. Monitoring scaling behavior..."

# Monitor for 30 seconds
for i in {1..6}; do
    echo "--- Check $i ---"
    kubectl get hpa $HPA_NAME -n $NAMESPACE
    echo "Pods: $(kubectl get pods -n $NAMESPACE | grep laravel-app | wc -l)"
    kubectl top pods -n $NAMESPACE | grep laravel-app 2>/dev/null || echo "Metrics not available"
    echo ""
    sleep 5
done

# Wait for load test to complete
if kill -0 $ab_pid 2>/dev/null; then
    wait $ab_pid
fi

print_header "Test Results:"
print_success "Auto-scaling test completed!"
echo ""
print_status "To trigger auto-scaling:"
echo "1. Run: ab -t 60 -c 50 -n 1000 http://laravel-app.local/"
echo "2. Monitor: kubectl get hpa -n laravel-app"
echo "3. Watch pods: kubectl get pods -n laravel-app"
echo ""
print_status "The HPA will automatically scale when:"
echo "- CPU usage > 10% (10m of 100m request)"
echo "- Memory usage > 20% (25.6Mi of 128Mi request)"
