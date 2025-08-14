#!/bin/bash

# Setup Auto-Scaling for Laravel App
# This script sets up the HorizontalPodAutoscaler and prepares for load testing

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
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

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi

    # Check if we can connect to the cluster
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi

    print_success "kubectl is available and connected to cluster"
}

# Function to check if namespace exists
check_namespace() {
    if ! kubectl get namespace $NAMESPACE &> /dev/null; then
        print_error "Namespace '$NAMESPACE' does not exist"
        print_status "Please create the namespace first or deploy the Laravel app"
        exit 1
    fi

    print_success "Namespace '$NAMESPACE' exists"
}

# Function to check if deployment exists
check_deployment() {
    if ! kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE &> /dev/null; then
        print_error "Deployment '$DEPLOYMENT_NAME' not found in namespace '$NAMESPACE'"
        print_status "Please deploy the Laravel app first"
        exit 1
    fi

    print_success "Deployment '$DEPLOYMENT_NAME' exists"
}

# Function to check if metrics server is available
check_metrics_server() {
    print_status "Checking if metrics server is available..."

    # Check if metrics server is running
    if kubectl get pods -n kube-system | grep -q metrics-server; then
        print_success "Metrics server is running"
    else
        print_warning "Metrics server not found. Installing..."

        # Install metrics server
        kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

        # Wait for metrics server to be ready
        print_status "Waiting for metrics server to be ready..."
        kubectl wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=120s

        print_success "Metrics server installed and ready"
    fi
}

# Function to apply HPA configuration
apply_hpa() {
    print_status "Applying HPA configuration..."

    if kubectl apply -f k8s/hpa.yaml; then
        print_success "HPA configuration applied successfully"
    else
        print_error "Failed to apply HPA configuration"
        exit 1
    fi
}

# Function to verify HPA is working
verify_hpa() {
    print_status "Verifying HPA is working..."

    # Wait a moment for HPA to be created
    sleep 5

    if kubectl get hpa $HPA_NAME -n $NAMESPACE &> /dev/null; then
        print_success "HPA '$HPA_NAME' created successfully"

        # Show HPA details
        print_status "HPA Details:"
        kubectl get hpa $HPA_NAME -n $NAMESPACE -o wide
        echo ""

        # Show HPA description
        print_status "HPA Description:"
        kubectl describe hpa $HPA_NAME -n $NAMESPACE
        echo ""
    else
        print_error "HPA '$HPA_NAME' not found after creation"
        exit 1
    fi
}

# Function to make scripts executable
make_scripts_executable() {
    print_status "Making scripts executable..."

    chmod +x load-test.sh
    chmod +x monitor-scaling.sh

    print_success "Scripts are now executable"
}

# Function to show next steps
show_next_steps() {
    echo ""
    print_success "Auto-scaling setup completed successfully!"
    echo ""
    print_status "Next steps:"
    echo "1. Start monitoring in one terminal:"
    echo "   ./monitor-scaling.sh"
    echo ""
    echo "2. Run load testing in another terminal:"
    echo "   ./load-test.sh"
    echo ""
    echo "3. Or run a quick manual load test:"
    echo "   ab -t 30 -c 20 -n 200 http://laravel-app.local/"
    echo ""
    print_status "The HPA will automatically scale the deployment based on CPU and memory usage."
    print_status "Scaling thresholds: CPU > 70%, Memory > 80%"
    print_status "Scaling range: 2-10 replicas"
}

# Main execution
main() {
    echo "=========================================="
    echo "Laravel App Auto-Scaling Setup"
    echo "=========================================="
    echo ""

    # Pre-flight checks
    check_kubectl
    check_namespace
    check_deployment
    check_metrics_server

    # Apply HPA configuration
    apply_hpa
    verify_hpa

    # Make scripts executable
    make_scripts_executable

    # Show next steps
    show_next_steps
}

# Run main function
main "$@"
