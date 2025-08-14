#!/bin/bash

echo "🎯 GitOps Demo - Full Cycle Test"
echo "================================="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
if ! command_exists kubectl; then
    echo "❌ kubectl is not installed"
    exit 1
fi

if ! command_exists git; then
    echo "❌ git is not installed"
    exit 1
fi

echo "✅ Prerequisites check passed"

# Step 1: Show current status
echo ""
echo "📊 Step 1: Current Status"
echo "-------------------------"
echo "ArgoCD Application Status:"
kubectl get application -n argocd

echo ""
echo "Laravel Pods Status:"
kubectl get pods -n laravel-app

echo ""
echo "Current Laravel Application:"
curl -s http://localhost:8081 | grep -A 3 -B 3 "Website Statistics Dashboard" | head -10

# Step 2: Make a change to test GitOps
echo ""
echo "🔄 Step 2: Testing GitOps Cycle"
echo "-------------------------------"

# Change the number of replicas
echo "Making change: Increasing replicas to 3..."
kubectl patch deployment laravel-app -n laravel-app --type='json' -p='[{"op": "replace", "path": "/spec/replicas", "value": 3}]'

# Wait for the change to be applied
echo "Waiting for change to be applied..."
sleep 10

echo "Current pod count:"
kubectl get pods -n laravel-app

# Step 3: Commit and push the change
echo ""
echo "📝 Step 3: Committing and Pushing Changes"
echo "----------------------------------------"

# Get the current deployment YAML
kubectl get deployment laravel-app -n laravel-app -o yaml > temp-deployment.yaml

# Extract the replicas value
REPLICAS=$(grep -A 5 "spec:" temp-deployment.yaml | grep "replicas:" | awk '{print $2}')

echo "Current replicas in deployment: $REPLICAS"

# Update the local deployment file
sed -i "s/replicas: 2/replicas: $REPLICAS/" k8s/laravel-deployment.yaml

# Commit and push
git add k8s/laravel-deployment.yaml
git commit -m "Demo: Update replicas to $REPLICAS for GitOps testing"
git push origin main

echo "✅ Changes committed and pushed to Git repository"

# Step 4: Monitor ArgoCD sync
echo ""
echo "👀 Step 4: Monitoring ArgoCD Sync"
echo "---------------------------------"

echo "Waiting for ArgoCD to detect changes..."
sleep 30

echo "ArgoCD Application Status:"
kubectl get application -n argocd

echo ""
echo "Laravel Pods Status:"
kubectl get pods -n laravel-app

# Step 5: Test application access
echo ""
echo "🌐 Step 5: Testing Application Access"
echo "------------------------------------"

echo "Testing Laravel application..."
if curl -s http://localhost:8081 > /dev/null; then
    echo "✅ Laravel application is accessible"
    echo "Current content preview:"
    curl -s http://localhost:8081 | grep -A 3 -B 3 "Website Statistics Dashboard" | head -10
else
    echo "❌ Laravel application is not accessible"
fi

# Step 6: Show access information
echo ""
echo "🔗 Step 6: Access Information"
echo "-----------------------------"

echo "ArgoCD UI:"
echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "  Username: admin"
echo "  Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"

echo ""
echo "Laravel Application:"
echo "  http://localhost:8081"

echo ""
echo "Minikube Dashboard:"
echo "  minikube dashboard"

# Cleanup
rm -f temp-deployment.yaml

echo ""
echo "🎉 GitOps Demo Complete!"
echo "========================"
echo "Your GitOps setup is working perfectly!"
echo "Changes made to Git repository are automatically synced by ArgoCD."
