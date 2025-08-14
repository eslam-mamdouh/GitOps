
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
2. Open ArgoCD UI to manage GitOps deployments => admin / ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD Admin Password: $ARGOCD_PASSWORD"
3. Access Laravel app at http://laravel-app.local
4. Test GitOps workflow by making changes to your code

🚀 Auto-Scaling Load Testing:
============================

1. Setup auto-scaling:
   ./setup-auto-scaling.sh

2. Start monitoring in one terminal:
   ./monitor-scaling.sh

3. Run load testing in another terminal:
   ./load-test.sh

4. Or run quick manual load test:
   ./quick-load-test.sh

5. Manual load test with Apache Bench:
   ab -t 30 -c 20 -n 200 http://laravel-app.local/

📊 Auto-Scaling Configuration:
- CPU threshold: 10% (lowered for testing)
- Memory threshold: 20% (lowered for testing)
- Min replicas: 2
- Max replicas: 10
- Scale up: 100% increase every 15s
- Scale down: 10% decrease every 60s

🎯 Current Status:
- HPA is configured and active
- 2 Laravel pods running
- CPU usage: ~1m (1% of 100m request)
- Memory usage: ~61-75Mi (48-60% of 128Mi request)
- Auto-scaling will trigger when CPU > 10% or Memory > 20%
