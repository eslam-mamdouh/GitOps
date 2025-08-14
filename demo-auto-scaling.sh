#!/bin/bash

# Auto-Scaling Demonstration Script
# This script demonstrates the auto-scaling functionality by manually scaling and monitoring

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="laravel-app"
DEPLOYMENT_NAME="laravel-app"
HPA_NAME="laravel-app-hpa"

# Function to print colored output
print_header() {
    echo -e "${CYAN}$1${NC}"
}

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show current status
show_status() {
    echo ""
    print_header "=== Current Status ==="
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
}

# Function to wait for pods to be ready
wait_for_pods() {
    local expected_replicas=$1
    print_status "Waiting for $expected_replicas pods to be ready..."
    kubectl wait --for=condition=ready pod -l app=laravel-app -n $NAMESPACE --timeout=120s
    print_success "All pods are ready!"
}

# Function to run load test
run_load_test() {
    local duration=$1
    local concurrency=$2
    local requests=$3

    print_status "Running load test: ${duration}s, ${concurrency} concurrent, ${requests} requests"
    ab -t $duration -c $concurrency -n $requests http://laravel-app.local/ > /dev/null 2>&1 &
    local ab_pid=$!

    print_status "Load test started with PID: $ab_pid"
    return $ab_pid
}

# Main demonstration
main() {
    echo "=========================================="
    echo "Laravel App Auto-Scaling Demonstration"
    echo "=========================================="
    echo ""

    # Show initial status
    print_status "Initial status:"
    show_status

    # Step 1: Scale up manually to demonstrate scaling
    print_header "Step 1: Manual Scale Up (4 replicas)"
    print_status "Scaling deployment to 4 replicas..."
    kubectl scale deployment $DEPLOYMENT_NAME --replicas=4 -n $NAMESPACE

    wait_for_pods 4
    show_status

    # Step 2: Run load test to generate CPU usage
    print_header "Step 2: Load Test to Generate CPU Usage"
    run_load_test 30 20 500
    local ab_pid=$!

    # Monitor during load test
    print_status "Monitoring during load test..."
    for i in {1..6}; do
        echo "--- Check $i ---"
        kubectl top pods -n $NAMESPACE | grep laravel-app 2>/dev/null || echo "Metrics not available"
        sleep 5
    done

    # Wait for load test to complete
    if kill -0 $ab_pid 2>/dev/null; then
        wait $ab_pid
    fi

    show_status

    # Step 3: Scale down manually
    print_header "Step 3: Manual Scale Down (2 replicas)"
    print_status "Scaling deployment back to 2 replicas..."
    kubectl scale deployment $DEPLOYMENT_NAME --replicas=2 -n $NAMESPACE

    wait_for_pods 2
    show_status

    # Step 4: Demonstrate HPA behavior
    print_header "Step 4: HPA Auto-Scaling Test"
    print_status "Running intensive load test to trigger HPA scaling..."

    # Run a more intensive load test
    run_load_test 60 50 1000
    ab_pid=$!

    # Monitor HPA behavior
    print_status "Monitoring HPA behavior..."
    for i in {1..12}; do
        echo "--- Check $i ---"
        kubectl get hpa $HPA_NAME -n $NAMESPACE
        kubectl get pods -n $NAMESPACE | grep laravel-app | wc -l
        kubectl top pods -n $NAMESPACE | grep laravel-app 2>/dev/null || echo "Metrics not available"
        sleep 5
    done

    # Wait for load test to complete
    if kill -0 $ab_pid 2>/dev/null; then
        wait $ab_pid
    fi

    show_status

    # Final demonstration
    print_header "Step 5: Final Status"
    print_status "Auto-scaling demonstration completed!"
    print_status "HPA Configuration:"
    echo "- CPU threshold: 10%"
    echo "- Memory threshold: 20%"
    echo "- Min replicas: 2"
    echo "- Max replicas: 10"
    echo ""
    print_success "Auto-scaling demonstration completed successfully!"
}

# Run main function
main "$@"
