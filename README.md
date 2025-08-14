
# Start Minikube Dashboard
minikube dashboard

# Start ArgoCD Port Forwarding
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Add Laravel app to hosts file
echo '192.168.49.2 laravel-app.local' | sudo tee -a /etc/hosts

# Check Laravel app logs
kubectl logs -n laravel-app deployment/laravel-app

# Check MySQL logs
kubectl logs -n laravel-app deployment/mysql

🎯 Testing Steps:
================

1. Open Minikube Dashboard to monitor resources
2. Open ArgoCD UI to manage GitOps deployments
3. Access Laravel app at http://laravel-app.local
4. Test GitOps workflow by making changes to your code
