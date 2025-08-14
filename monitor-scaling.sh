#!/bin/bash

# Real-time Auto-Scaling Monitor for Laravel App
# Run this script in a separate terminal to monitor scaling behavior

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

print_info() {
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

# Function to get current pending pods
get_pending_pods() {
    kubectl get pods -n $NAMESPACE -l app=laravel-app --field-selector=status.phase=Pending -o jsonpath='{.items[*].metadata.name}' 2>/dev/null | wc -w
}

# Function to get HPA current replicas
get_hpa_current_replicas() {
    kubectl get hpa $HPA_NAME -n $NAMESPACE -o jsonpath='{.status.currentReplicas}' 2>/dev/null || echo "0"
}

# Function to get HPA target replicas
get_hpa_target_replicas() {
    kubectl get hpa $HPA_NAME -n $NAMESPACE -o jsonpath='{.status.desiredReplicas}' 2>/dev/null || echo "0"
}

# Function to get CPU usage percentage
get_cpu_usage() {
    kubectl get hpa $HPA_NAME -n $NAMESPACE -o jsonpath='{.status.currentMetrics[?(@.type=="Resource")].resource.current.averageUtilization}' 2>/dev/null || echo "0"
}

# Function to get memory usage percentage
get_memory_usage() {
    kubectl get hpa $HPA_NAME -n $NAMESPACE -o jsonpath='{.status.currentMetrics[?(@.type=="Resource")].resource.current.averageUtilization}' 2>/dev/null || echo "0"
}

# Function to display current status
display_status() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local replicas=$(get_replica_count)
    local running_pods=$(get_running_pods)
    local pending_pods=$(get_pending_pods)
    local hpa_current=$(get_hpa_current_replicas)
    local hpa_target=$(get_hpa_target_replicas)
    local cpu_usage=$(get_cpu_usage)
    local memory_usage=$(get_memory_usage)
    
    # Clear screen and move to top
    clear
    
    print_header "=========================================="
    print_header "Laravel App Auto-Scaling Monitor"
    print_header "=========================================="
    echo ""
    
    print_header "Timestamp: $timestamp"
    echo ""
    
    print_header "=== Deployment Status ==="
    echo "Configured Replicas: $replicas"
    echo "Running Pods: $running_pods"
    echo "Pending Pods: $pending_pods"
    echo ""
    
    print_header "=== HPA Status ==="
    echo "HPA Current Replicas: $hpa_current"
    echo "HPA Target Replicas: $hpa_target"
    echo "CPU Usage: ${cpu_usage}%"
    echo "Memory Usage: ${memory_usage}%"
    echo ""
    
    # Show scaling status
    if [ "$hpa_target" -gt "$replicas" ]; then
        print_success "🔄 SCALING UP: HPA target ($hpa_target) > configured replicas ($replicas)"
    elif [ "$hpa_target" -lt "$replicas" ]; then
        print_warning "📉 SCALING DOWN: HPA target ($hpa_target) < configured replicas ($replicas)"
    else
        print_info "✅ STABLE: No scaling in progress"
    fi
    
    echo ""
    
    # Show recent events
    print_header "=== Recent Events (Last 10) ==="
    kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -10 2>/dev/null || echo "No events found"
    
    echo ""
    print_header "Press Ctrl+C to stop monitoring"
    echo ""
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
}

# Function to check if namespace exists
check_namespace() {
    if ! kubectl get namespace $NAMESPACE &> /dev/null; then
        print_error "Namespace '$NAMESPACE' does not exist"
        exit 1
    fi
}

# Function to check if HPA exists
check_hpa() {
    if ! kubectl get hpa $HPA_NAME -n $NAMESPACE &> /dev/null; then
        print_warning "HPA '$HPA_NAME' not found in namespace '$NAMESPACE'"
        print_info "Make sure to apply the HPA configuration first:"
        print_info "kubectl apply -f k8s/hpa.yaml"
        exit 1
    fi
}

# Main monitoring loop
main() {
    print_header "Starting Laravel App Auto-Scaling Monitor..."
    echo ""
    
    # Pre-flight checks
    check_kubectl
    check_namespace
    check_hpa
    
    print_success "All checks passed. Starting monitoring..."
    echo ""
    
    # Initial display
    display_status
    
    # Main monitoring loop
    while true; do
        sleep 3
        display_status
    done
}

# Trap to handle script interruption
trap 'echo ""; print_info "Monitoring stopped. Goodbye!"; exit 0' INT TERM

# Run main function
main "$@" 