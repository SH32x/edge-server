# PowerShell script for quick deployment
# Must be run from the project root directory
Write-Host "===== Quick Deployment for Edge Inference Service =====" -ForegroundColor Green

$skipDocker = $false
$skipKubernetes = $false

foreach ($arg in $args) {
    if ($arg -eq "--skip-docker") {
        $skipDocker = $true
    }
    elseif ($arg -eq "--skip-kubernetes") {
        $skipKubernetes = $true
    }
}

# Check Docker and Kubernetes status (but don't fail if they're not available)
$dockerRunning = $false
$k8sRunning = $false

try {
    $dockerVersion = docker version 2>&1
    if ($LASTEXITCODE -eq 0) {
        $dockerRunning = $true
        Write-Host "✓ Docker is running" -ForegroundColor Green
    }
    else {
        Write-Host "✗ Docker is not running" -ForegroundColor Yellow
        $skipDocker = $true
    }
}
catch {
    Write-Host "✗ Docker is not available" -ForegroundColor Yellow
    $skipDocker = $true
}

if (-not $skipDocker -and -not $skipKubernetes) {
    try {
        $k8sVersion = kubectl version --client 2>&1
        if ($LASTEXITCODE -eq 0) {
            $k8sRunning = $true
            Write-Host "✓ Kubernetes is available" -ForegroundColor Green
        }
        else {
            Write-Host "✗ Kubernetes is not running" -ForegroundColor Yellow
            $skipKubernetes = $true
        }
    }
    catch {
        Write-Host "✗ Kubernetes is not available" -ForegroundColor Yellow
        $skipKubernetes = $true
    }
}

# Make sure model directory exists
if (-not (Test-Path "docker\model")) {
    New-Item -Path "docker\model" -ItemType Directory | Out-Null
}

# Create a dummy model file if needed
if (-not (Test-Path "docker\model\model.tflite")) {
    Write-Host "`nCreating dummy model file..." -ForegroundColor Cyan
    [byte[]]$dummyBytes = @(0) * 1024
    [System.IO.File]::WriteAllBytes("docker\model\model.tflite", $dummyBytes)
}

# Build Docker image if Docker is running
if (-not $skipDocker) {
    Write-Host "`nBuilding Docker image..." -ForegroundColor Cyan
    Set-Location -Path "docker"
    docker build -t edge-ml-model:latest .
    Set-Location -Path ".."
}
else {
    Write-Host "`nSkipping Docker build" -ForegroundColor Yellow
}

# Deploy to Kubernetes if both Docker and Kubernetes are running
if (-not $skipDocker -and -not $skipKubernetes) {
    Write-Host "`nDeploying to Kubernetes..." -ForegroundColor Cyan
    
    # If services don't exist yet, create them
    $servicesExist = kubectl get service ml-inference-service 2>&1
    if ($LASTEXITCODE -ne 0) {
        kubectl apply -f kubernetes/service.yaml
    }
    else {
        Write-Host "Service already exists, skipping creation" -ForegroundColor Yellow
    }
    
    # Apply the deployment
    kubectl apply -f kubernetes/deployment.yaml
    
    # Start monitoring the deployment
    $timeout = 30  # seconds
    $elapsed = 0
    $deploymentReady = $false
    
    Write-Host "`nWaiting for deployment to be ready (timeout: ${timeout}s)..." -ForegroundColor Cyan
    
    while ($elapsed -lt $timeout -and -not $deploymentReady) {
        $deploymentStatus = kubectl get deployment ml-inference -o jsonpath='{.status.readyReplicas}'
        if ($deploymentStatus -eq "1") {
            $deploymentReady = $true
        }
        else {
            Start-Sleep -Seconds 2
            $elapsed += 2
            Write-Host "." -NoNewline
        }
    }
    
    Write-Host ""
    if ($deploymentReady) {
        Write-Host "✓ Deployment ready!" -ForegroundColor Green
    }
    else {
        Write-Host "! Deployment not ready within timeout period" -ForegroundColor Yellow
        Write-Host "  Run .\scripts\deployment-status.ps1 to check status" -ForegroundColor Yellow
    }
    
    # Get service information
    Write-Host "`n===== Service Information =====" -ForegroundColor Green
    kubectl get service ml-inference-service
    
    # Display service URL
    $nodePort = kubectl get service ml-inference-service -o jsonpath='{.spec.ports[0].nodePort}'
    if ($nodePort) {
        Write-Host "`nML inference service is available at:" -ForegroundColor Cyan
        Write-Host "http://localhost:$nodePort" -ForegroundColor Yellow
        
        # Save service URL to file for test script
        "http://localhost:$nodePort" | Out-File -FilePath ".service_url" -Encoding utf8
    }
}
else {
    Write-Host "`nSkipping Kubernetes deployment" -ForegroundColor Yellow
}

# Set up the simulation environment
Write-Host "`n===== Setting up simulation environment =====" -ForegroundColor Green

# Run the PlatformIO script if PlatformIO is installed
$pioCmdPath = "$env:USERPROFILE\.platformio\penv\Scripts\pio.exe"
if (Test-Path $pioCmdPath) {
    Write-Host "PlatformIO is installed, setting up simulation..." -ForegroundColor Cyan
    if (-not (Test-Path "platformio")) {
        New-Item -Path "platformio" -ItemType Directory | Out-Null
    }
    if (-not (Test-Path "platformio\src")) {
        New-Item -Path "platformio\src" -ItemType Directory | Out-Null
    }
}
else {
    Write-Host "PlatformIO not found. Skipping simulation setup." -ForegroundColor Yellow
}

Write-Host "`n===== Quick Deployment Complete =====" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. To test the service: .\tests\test-inference.ps1" -ForegroundColor Yellow
Write-Host "2. To check deployment status: .\scripts\deployment-status.ps1" -ForegroundColor Yellow
Write-Host "3. To run the simulation: .\scripts\run-simulation.ps1" -ForegroundColor Yellow