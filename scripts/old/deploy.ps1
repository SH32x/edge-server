# PowerShell script for deploying the edge inference service
# Must be run from the project root directory

Write-Host "===== Deploying Edge Inference Service =====" -ForegroundColor Green

# Verify Docker and Kubernetes are running
<# try {
    docker version | Out-Null
    kubectl get nodes | Out-Null
    Write-Host "✓ Docker and Kubernetes are running" -ForegroundColor Green
}
catch {
    Write-Host "✗ Docker or Kubernetes is not running. Please run setup-docker-kubernetes.ps1 first." -ForegroundColor Red
    exit 1
} #>

# Create a sample TensorFlow Lite model if not present
if (-not (Test-Path "docker\model\model.tflite")) {
    Write-Host "`nCreating sample TFLite model..." -ForegroundColor Cyan
    
    if (-not (Test-Path "docker\model")) {
        New-Item -Path "docker\model" -ItemType Directory | Out-Null
    }
    
    # Use the model generator script
    python scripts/generate_model.py "docker/model/model.tflite"
}

# Build the Docker image
Write-Host "`nBuilding Docker image..." -ForegroundColor Cyan
Set-Location -Path "docker"
docker build -t edge-ml-model:latest .
Set-Location -Path ".."

# Apply Kubernetes configurations
Write-Host "`nDeploying Kubernetes configurations..." -ForegroundColor Cyan

# First create the metrics components
if (-not (kubectl get deployment prometheus 2>$null)) {
    Write-Host "Creating Prometheus deployment..."
    kubectl apply -f kubernetes/metrics/prometheus.yaml
}

if (-not (kubectl get deployment influxdb 2>$null)) {
    Write-Host "Creating InfluxDB deployment..."
    kubectl apply -f kubernetes/metrics/influxdb.yaml
}

# Then create the inference service
Write-Host "Deploying ML inference service..."
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml

# Wait for the deployment to be ready
Write-Host "`nWaiting for deployment to be ready..." -ForegroundColor Cyan
kubectl rollout status deployment/ml-inference

# Get service information
Write-Host "`n===== Service Information =====" -ForegroundColor Green
kubectl get service ml-inference-service

# If service type is NodePort, provide the URL
$nodePort = kubectl get service ml-inference-service -o jsonpath='{.spec.ports[0].nodePort}'
if ($nodePort) {
    Write-Host "`nML inference service is available at:" -ForegroundColor Cyan
    Write-Host "http://localhost:$nodePort" -ForegroundColor Yellow
    
    # Save service URL to file for test script
    "http://localhost:$nodePort" | Out-File -FilePath ".service_url" -Encoding utf8
}

Write-Host "`n===== Deployment Complete =====" -ForegroundColor Green
Write-Host "Next step: Run .\tests\test-inference.ps1 to test the service" -ForegroundColor Cyan