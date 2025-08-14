# 🚀 Kubernetes GitOps Testing Guide

This guide will help you test the complete Kubernetes GitOps setup with ArgoCD and Laravel.

## 📋 Prerequisites

Make sure you have the following installed:
- Docker
- kubectl
- minikube
- helm

## 🎯 Quick Start Testing

### Option 1: Automated Testing Script
```bash
# Run the complete test script
./test-setup.sh
```

### Option 2: Manual Step-by-Step Testing

#### 1. Start Minikube
```bash
minikube start --driver=docker
```

#### 2. Enable Required Addons
```bash
minikube addons enable metrics-server
minikube addons enable ingress
```

#### 3. Load Laravel Docker Image
```bash
minikube image load laravel-app:latest
```

#### 4. Apply Kubernetes Manifests
```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/mysql-deployment.yaml
kubectl apply -f k8s/laravel-deployment.yaml
kubectl apply -f k8s/ingress.yaml
```

#### 5. Apply ArgoCD Application
```bash
kubectl apply -f k8s/argocd-application.yaml
```

## 🔍 Verification Steps

### Check Pod Status
```bash
# Check ArgoCD pods
kubectl get pods -n argocd

# Check Laravel app pods
kubectl get pods -n laravel-app
```

### Check Services
```bash
# Check all services
kubectl get svc -n laravel-app
kubectl get svc -n argocd
```

### Check Ingress
```bash
kubectl get ingress -n laravel-app
```

## 🌐 Access URLs

### 1. Minikube Dashboard
```bash
minikube dashboard
```
Access: http://localhost:30000

### 2. ArgoCD UI
```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
Access: https://localhost:8080
Username: admin
Password: [from command above]

### 3. Laravel Application
```bash
# Get Minikube IP
minikube ip

# Add to /etc/hosts
echo "$(minikube ip) laravel.local" | sudo tee -a /etc/hosts
```
Access: http://laravel.local

## 🧪 Testing Scenarios

### 1. GitOps Workflow Test
1. Make a change to your Laravel code
2. Push to Git repository
3. Check ArgoCD UI for automatic sync
4. Verify changes are deployed

### 2. Database Connectivity Test
1. Check MySQL pod is running
2. Verify Laravel can connect to database
3. Test database operations

### 3. Load Balancing Test
1. Scale Laravel deployment
2. Verify traffic is distributed
3. Check pod health

### 4. Monitoring Test
1. Access Minikube dashboard
2. Check resource usage
3. Monitor pod logs

## 🔧 Troubleshooting

### Common Issues

#### Docker Permission Issues
```bash
sudo chmod 666 /var/run/docker.sock
```

#### Minikube Not Starting
```bash
minikube delete
minikube start --driver=docker
```

#### Pods Not Starting
```bash
# Check pod logs
kubectl logs -n laravel-app <pod-name>

# Check pod events
kubectl describe pod -n laravel-app <pod-name>
```

#### ArgoCD Not Accessible
```bash
# Check ArgoCD pods
kubectl get pods -n argocd

# Restart ArgoCD if needed
kubectl delete pod -n argocd <argocd-server-pod>
```

### Useful Commands

```bash
# Get all resources
kubectl get all -n laravel-app
kubectl get all -n argocd

# Check logs
kubectl logs -f -n laravel-app deployment/laravel-app
kubectl logs -f -n argocd deployment/argocd-server

# Check events
kubectl get events -n laravel-app
kubectl get events -n argocd

# Check ingress status
kubectl describe ingress -n laravel-app laravel-ingress
```

## 📊 Expected Results

After successful setup, you should see:

### ArgoCD Namespace
- argocd-server pod: Running
- argocd-application-controller pod: Running
- argocd-repo-server pod: Running

### Laravel Namespace
- laravel-app pods: Running (2 replicas)
- mysql pod: Running
- Services: laravel-app, mysql
- Ingress: laravel-ingress

### Access Points
- Minikube Dashboard: ✅ Accessible
- ArgoCD UI: ✅ Accessible with admin credentials
- Laravel App: ✅ Accessible via http://laravel.local

## 🎉 Success Criteria

✅ All pods are in Running state
✅ Services are accessible
✅ Ingress is configured
✅ ArgoCD UI is accessible
✅ Laravel application responds
✅ Database connectivity works
✅ GitOps sync is working

## 🧹 Cleanup

To clean up the setup:
```bash
# Delete ArgoCD application
kubectl delete -f k8s/argocd-application.yaml

# Delete Laravel resources
kubectl delete -f k8s/

# Stop Minikube
minikube stop

# Delete Minikube cluster
minikube delete
``` 
