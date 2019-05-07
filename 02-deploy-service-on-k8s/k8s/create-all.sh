kubectl apply -f user-admin-namespace.yml
./user-admin-secrets.sh
kubectl apply -f user-admin-backend-deployment.yml
kubectl apply -f user-admin-backend-service.yml
