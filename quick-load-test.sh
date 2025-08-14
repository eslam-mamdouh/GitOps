#!/bin/bash

# Quick Load Test for Laravel App Auto-Scaling
# Simple script for manual testing of auto-scaling behavior

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_URL="http://laravel-app.local"
NAMESPACE="laravel-app"
DEPLOYMENT_NAME="laravel-app"
HPA_NAME="laravel-app-hpa"

# Function to print colored output
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

# Function to get current replica count
get_replica_count() {
    kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0"
}

# Function to get current running pods
get_running_pods() {
    kubectl get pods -n $NAMESPACE -l app=laravel-app --field-selector=status.phase=Running -o jsonpath='{.items[*].metadata.name}' 2>/dev/null | wc -w
}

# Function to show current status
show_status() {
    local replicas=$(get_replica_count)
    local running_pods=$(get_running_pods)

    echo "Current Status:"
    echo "  Configured Replicas: $replicas"
    echo "  Running Pods: $running_pods"
    echo ""
}

# Function to run a load test
run_load_test() {
    local duration=$1
    local concurrency=$2
    local requests=$3
    local description=$4

    print_status "Running $description..."
    print_status "Duration: ${duration}s, Concurrency: $concurrency, Requests: $requests"

    # Show status before
    print_status "Status before load test:"
    show_status

    # Run the load test
    ab -t $duration -c $concurrency -n $requests "$APP_URL/" 2>/dev/null | grep -E "(Requests per second|Time per request|Complete requests|Failed requests)" || true

    # Wait a moment for scaling to take effect
    sleep 10

    # Show status after
    print_status "Status after load test:"
    show_status

    echo "----------------------------------------"
}

# Function to check if ab is available
check_ab() {
    if ! command -v ab &> /dev/null; then
        print_error "Apache Bench (ab) is not installed"
        print_status "Install it with: sudo apt-get install apache2-utils"
        exit 1
    fi
}

# Function to check if app is accessible
check_app() {
    if ! curl -s -f "$APP_URL" > /dev/null; then
        print_error "Laravel app is not accessible at $APP_URL"
        exit 1
    fi
    print_success "Laravel app is accessible"
}

# Main execution
main() {
    echo "=========================================="
    echo "Quick Load Test for Laravel Auto-Scaling"
    echo "=========================================="
    echo ""

    # Pre-flight checks
    check_ab
    check_app

    print_status "Starting quick load test sequence..."
    echo ""

    # Show initial status
    print_status "Initial status:"
    show_status

    # Test 1: Light load (should not trigger scaling)
    run_load_test 30 5 50 "Light Load Test"

    # Test 2: Medium load (should trigger scaling)
    run_load_test 60 15 200 "Medium Load Test"

    # Test 3: Heavy load (should trigger maximum scaling)
    run_load_test 90 30 500 "Heavy Load Test"

    # Test 4: Burst load (rapid scaling test)
    run_load_test 30 50 100 "Burst Load Test"

    print_success "Quick load test completed!"
    echo ""
    print_status "Check the scaling behavior in another terminal with:"
    print_status "kubectl get hpa -n laravel-app"
    print_status "kubectl get pods -n laravel-app"
}

# Run main function
main "$@"
