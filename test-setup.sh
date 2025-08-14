#!/bin/bash

echo "🚀 Testing Kubernetes GitOps Setup with ArgoCD and Laravel"
echo "=========================================================="

# Function to check command status
check_status() {
    if [ $? -eq 0 ]; then
        echo "✅ $1"
    else
        echo "❌ $1"
        exit 1
    fi
}

# 1. Check Minikube status
echo "📋 1. Checking Minikube status..."
minikube status
check_status "Minikube status check"

# 2. Start Minikube if not running
echo "📋 2. Starting Minikube..."
minikube start --driver=docker
check_status "Minikube start"

# 3. Enable addons
echo "📋 3. Enabling Minikube addons..."
minikube addons enable metrics-server
minikube addons enable ingress
check_status "Addons enabled"

# 4. Load Docker image
echo "📋 4. Loading Laravel Docker image..."
minikube image load laravel-app:latest
check_status "Docker image loaded"

# 5. Apply Kubernetes manifests
echo "📋 5. Applying Kubernetes manifests..."
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/mysql-deployment.yaml
kubectl apply -f k8s/laravel-deployment.yaml
kubectl apply -f k8s/ingress.yaml
check_status "Kubernetes manifests applied"

# 6. Check ArgoCD status
echo "📋 6. Checking ArgoCD status..."
kubectl get pods -n argocd
check_status "ArgoCD pods check"

# 7. Get ArgoCD admin password
echo "📋 7. Getting ArgoCD admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD Admin Password: $ARGOCD_PASSWORD"
check_status "ArgoCD password retrieved"

# 8. Apply ArgoCD application
echo "📋 8. Applying ArgoCD application..."
kubectl apply -f k8s/argocd-application.yaml
check_status "ArgoCD application applied"

# 9. Check Laravel app status
echo "📋 9. Checking Laravel application status..."
kubectl get pods -n laravel-app
check_status "Laravel pods check"

# 10. Check services
echo "📋 10. Checking services..."
kubectl get svc -n laravel-app
kubectl get svc -n argocd
check_status "Services check"

# 11. Check ingress
echo "📋 11. Checking ingress..."
kubectl get ingress -n laravel-app
check_status "Ingress check"

# 12. Get access URLs
echo "📋 12. Getting access URLs..."
echo ""
echo "🌐 Access URLs:"
echo "==============="
echo "Minikube Dashboard: $(minikube dashboard --url)"
echo "ArgoCD UI: https://localhost:8080 (admin/$ARGOCD_PASSWORD)"
echo "Laravel App: http://laravel.local"
echo ""
echo "📝 To access Laravel app, add to /etc/hosts:"
echo "   $(minikube ip) laravel.local"
echo ""

# 13. Port forward ArgoCD
echo "📋 13. Setting up ArgoCD port forwarding..."
echo "ArgoCD will be available at: https://localhost:8080"
echo "Username: admin"
echo "Password: $ARGOCD_PASSWORD"
echo ""
echo "🎉 Setup complete! You can now:"
echo "1. Access Minikube Dashboard for monitoring"
echo "2. Access ArgoCD UI for GitOps management"
echo "3. Access Laravel application"
echo ""
echo "Press Ctrl+C to stop port forwarding when done"
kubectl port-forward svc/argocd-server -n argocd 8080:443
