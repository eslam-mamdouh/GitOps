#!/bin/bash

# Laravel App Load Testing and Auto-Scaling Test Script
# This script tests the Laravel application under load and monitors auto-scaling behavior

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

# Function to check if required tools are installed
check_dependencies() {
    print_status "Checking dependencies..."
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    # Check if ab (Apache Bench) is available
    if ! command -v ab &> /dev/null; then
        print_warning "Apache Bench (ab) not found. Installing..."
        sudo apt-get update && sudo apt-get install -y apache2-utils
    fi
    
    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        print_warning "jq not found. Installing..."
        sudo apt-get update && sudo apt-get install -y jq
    fi
    
    print_success "All dependencies are available"
}

# Function to check if the app is accessible
check_app_accessibility() {
    print_status "Checking if Laravel app is accessible..."
    
    if curl -s -f "$APP_URL" > /dev/null; then
        print_success "Laravel app is accessible at $APP_URL"
    else
        print_error "Laravel app is not accessible at $APP_URL"
        print_status "Checking pod status..."
        kubectl get pods -n $NAMESPACE
        exit 1
    fi
}

# Function to get current replica count
get_replica_count() {
    kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE -o jsonpath='{.spec.replicas}'
}

# Function to get current running pods
get_running_pods() {
    kubectl get pods -n $NAMESPACE -l app=laravel-app --field-selector=status.phase=Running -o jsonpath='{.items[*].metadata.name}' | wc -w
}

# Function to monitor HPA status
monitor_hpa() {
    print_status "Current HPA status:"
    kubectl get hpa $HPA_NAME -n $NAMESPACE
    echo ""
}

# Function to monitor pod resources
monitor_pod_resources() {
    print_status "Current pod resource usage:"
    kubectl top pods -n $NAMESPACE
    echo ""
}

# Function to run load test with Apache Bench
run_load_test() {
    local duration=$1
    local concurrency=$2
    local requests=$3
    
    print_status "Starting load test..."
    print_status "Duration: ${duration}s, Concurrency: $concurrency, Total requests: $requests"
    
    # Run the load test in background and capture PID
    ab -t $duration -c $concurrency -n $requests "$APP_URL/" > load_test_results.txt 2>&1 &
    local ab_pid=$!
    
    print_status "Load test started with PID: $ab_pid"
    return $ab_pid
}

# Function to monitor scaling during load test
monitor_scaling() {
    local duration=$1
    local ab_pid=$2
    
    print_status "Monitoring scaling behavior for ${duration} seconds..."
    
    local start_time=$(date +%s)
    local end_time=$((start_time + duration))
    
    while [ $(date +%s) -lt $end_time ] && kill -0 $ab_pid 2>/dev/null; do
        local current_time=$(date '+%H:%M:%S')
        local replicas=$(get_replica_count)
        local running_pods=$(get_running_pods)
        
        echo "[$current_time] Replicas: $replicas, Running pods: $running_pods"
        
        # Check if scaling occurred
        if [ "$running_pods" -gt "$replicas" ]; then
            print_success "Scaling detected! Running pods ($running_pods) > configured replicas ($replicas)"
        fi
        
        sleep 5
    done
    
    # Wait for load test to complete
    if kill -0 $ab_pid 2>/dev/null; then
        print_status "Waiting for load test to complete..."
        wait $ab_pid
    fi
}

# Function to run different load test scenarios
run_load_test_scenarios() {
    print_status "Running load test scenarios..."
    
    # Scenario 1: Light load (should not trigger scaling)
    print_status "Scenario 1: Light load test"
    run_load_test 30 5 100
    local ab_pid=$!
    monitor_scaling 35 $ab_pid
    sleep 10
    
    # Scenario 2: Medium load (should trigger scaling)
    print_status "Scenario 2: Medium load test"
    run_load_test 60 20 500
    ab_pid=$!
    monitor_scaling 70 $ab_pid
    sleep 15
    
    # Scenario 3: Heavy load (should trigger maximum scaling)
    print_status "Scenario 3: Heavy load test"
    run_load_test 90 50 1000
    ab_pid=$!
    monitor_scaling 100 $ab_pid
    sleep 20
    
    # Scenario 4: Burst load (rapid scaling test)
    print_status "Scenario 4: Burst load test"
    run_load_test 30 100 200
    ab_pid=$!
    monitor_scaling 35 $ab_pid
}

# Function to generate test report
generate_report() {
    print_status "Generating test report..."
    
    local report_file="load_test_report_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "=== Laravel App Load Test Report ==="
        echo "Date: $(date)"
        echo "App URL: $APP_URL"
        echo ""
        
        echo "=== Initial State ==="
        echo "Initial replicas: $(get_replica_count)"
        echo "Initial running pods: $(get_running_pods)"
        echo ""
        
        echo "=== Final State ==="
        echo "Final replicas: $(get_replica_count)"
        echo "Final running pods: $(get_running_pods)"
        echo ""
        
        echo "=== HPA Status ==="
        kubectl get hpa $HPA_NAME -n $NAMESPACE -o wide
        echo ""
        
        echo "=== Pod Resource Usage ==="
        kubectl top pods -n $NAMESPACE
        echo ""
        
        echo "=== Load Test Results ==="
        if [ -f "load_test_results.txt" ]; then
            cat load_test_results.txt
        fi
        echo ""
        
        echo "=== Recent Pod Events ==="
        kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -20
        
    } > "$report_file"
    
    print_success "Test report generated: $report_file"
}

# Function to cleanup
cleanup() {
    print_status "Cleaning up..."
    rm -f load_test_results.txt
    print_success "Cleanup completed"
}

# Main execution
main() {
    echo "=========================================="
    echo "Laravel App Load Testing & Auto-Scaling Test"
    echo "=========================================="
    echo ""
    
    # Check dependencies
    check_dependencies
    
    # Check app accessibility
    check_app_accessibility
    
    # Show initial state
    print_status "Initial deployment state:"
    kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE
    echo ""
    
    monitor_hpa
    monitor_pod_resources
    
    # Run load test scenarios
    run_load_test_scenarios
    
    # Final monitoring
    print_status "Final state after load testing:"
    monitor_hpa
    monitor_pod_resources
    
    # Generate report
    generate_report
    
    # Cleanup
    cleanup
    
    print_success "Load testing completed successfully!"
    print_status "Check the generated report for detailed results."
}

# Trap to handle script interruption
trap 'print_warning "Script interrupted. Cleaning up..."; cleanup; exit 1' INT TERM

# Run main function
main "$@" 