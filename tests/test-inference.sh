#!/bin/bash
# Test script for the ML inference service

set -e

# Determine the service URL
SERVICE_IP=$(kubectl get service ml-inference-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

if [ -z "$SERVICE_IP" ]; then
    # If external IP is not available, use NodePort
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
    NODE_PORT=$(kubectl get service ml-inference-service -o jsonpath='{.spec.ports[0].nodePort}')
    SERVICE_URL="http://$NODE_IP:$NODE_PORT"
else
    SERVICE_URL="http://$SERVICE_IP"
fi

echo "Using service URL: $SERVICE_URL"

# Test health endpoint
echo "Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s "$SERVICE_URL/health")
echo "Health response: $HEALTH_RESPONSE"

# Run inference test with sample input
echo "Testing inference endpoint..."
INFERENCE_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d '{"input": [1.0, 2.0, 3.0, 4.0]}' \
    "$SERVICE_URL/predict")

echo "Inference response: $INFERENCE_RESPONSE"

# Test metrics endpoint
echo "Testing metrics endpoint..."
METRICS_RESPONSE=$(curl -s "$SERVICE_URL/metrics")
echo "Metrics response: $METRICS_RESPONSE"

echo "===== Test Completed ====="

# Run a load test (optional)
if [ "$1" == "--load-test" ]; then
    echo "Running load test (10 requests)..."
    for i in {1..10}; do
        echo "Request $i"
        curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "{\"input\": [$(($RANDOM % 10)).0, $(($RANDOM % 10)).0, $(($RANDOM % 10)).0, $(($RANDOM % 10)).0]}" \
            "$SERVICE_URL/predict" > /dev/null
        echo "Done"
        sleep 1
    done
    echo "Load test completed."
fi