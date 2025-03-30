#!/bin/bash
# Deployment script for the ML inference application

set -e

echo "===== Deploying ML Inference Application ====="

# Build the Docker image
echo "Building Docker image for ML inference..."
cd ../docker
docker build -t edge-ml-model:latest .

# Deploy the application to Kubernetes
echo "Deploying to Kubernetes..."
cd ../kubernetes
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# Wait for the deployment to be ready
echo "Waiting for deployment to be ready..."
kubectl rollout status deployment/ml-inference

# Get service information
echo "===== Service Information ====="
kubectl get service ml-inference-service

# Check if the service is of type LoadBalancer
SERVICE_TYPE=$(kubectl get service ml-inference-service -o jsonpath='{.spec.type}')
if [ "$SERVICE_TYPE" == "LoadBalancer" ]; then
    echo "Service type is LoadBalancer. Waiting for external IP..."
    external_ip=""
    while [ -z $external_ip ]; do
        echo "Waiting for external IP..."
        external_ip=$(kubectl get service ml-inference-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
        [ -z "$external_ip" ] && sleep 10
    done
    echo "ML inference service is available at http://$external_ip"
else
    # If not LoadBalancer, get NodePort
    NODE_PORT=$(kubectl get service ml-inference-service -o jsonpath='{.spec.ports[0].nodePort}')
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
    echo "ML inference service is available at http://$NODE_IP:$NODE_PORT"
fi

echo "===== Deployment Complete ====="
echo ""
echo "To test the inference service, use:"
echo "curl -X POST -H \"Content-Type: application/json\" -d '{\"input\": [1.0, 2.0, 3.0, 4.0]}' http://<service_ip>/predict"
echo ""
echo "To access Prometheus metrics, run:"
echo "kubectl port-forward service/prometheus 9090:9090"
echo "Then open http://localhost:9090 in your browser"
echo ""
echo "To access InfluxDB, run:"
echo "kubectl port-forward service/influxdb 8086:8086"
echo "Then open http://localhost:8086 in your browser"