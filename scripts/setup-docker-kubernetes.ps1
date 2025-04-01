# PowerShell script for setting up the edge inference service on Windows
# Must be run from the project root directory

Write-Host "===== Setting up Edge Inference Service on Windows =====" -ForegroundColor Green

# Check if Docker Desktop is installed and running
$dockerRunning = $false
try {
    $dockerOutput = docker version 2>&1
    if ($LASTEXITCODE -eq 0) {
        $dockerRunning = $true
        Write-Host "✓ Docker is running" -ForegroundColor Green
    }
    else {
        Write-Host "✗ Docker is not running properly. Error output:" -ForegroundColor Red
        Write-Host $dockerOutput -ForegroundColor Yellow
    }
}
catch {
    Write-Host "✗ Docker is not running or not installed. Error: $_" -ForegroundColor Red
}

if (-not $dockerRunning) {
    $continueWithoutDocker = Read-Host "Continue without Docker? (y/n)"
    if ($continueWithoutDocker -ne "y") {
        Write-Host "Please start Docker Desktop with Kubernetes enabled and try again." -ForegroundColor Yellow
        exit 1
    }
    else {
        Write-Host "Continuing setup without Docker verification..." -ForegroundColor Yellow
    }
}

# Check if Kubernetes is available
$k8sRunning = $false
try {
    $k8sOutput = kubectl get nodes 2>&1
    if ($LASTEXITCODE -eq 0) {
        $k8sRunning = $true
        Write-Host "✓ Kubernetes is available" -ForegroundColor Green
    }
    else {
        Write-Host "✗ Kubernetes is not running properly. Error output:" -ForegroundColor Red
        Write-Host $k8sOutput -ForegroundColor Yellow
    }
}
catch {
    Write-Host "✗ Kubernetes is not available. Error: $_" -ForegroundColor Red
}

if (-not $k8sRunning) {
    $continueWithoutK8s = Read-Host "Continue without Kubernetes? (y/n)"
    if ($continueWithoutK8s -ne "y") {
        Write-Host "Please enable Kubernetes in Docker Desktop settings:" -ForegroundColor Yellow
        Write-Host "   1. Open Docker Desktop" -ForegroundColor Yellow
        Write-Host "   2. Go to Settings > Kubernetes" -ForegroundColor Yellow
        Write-Host "   3. Check 'Enable Kubernetes'" -ForegroundColor Yellow
        Write-Host "   4. Click Apply & Restart" -ForegroundColor Yellow
        exit 1
    }
    else {
        Write-Host "Continuing setup without Kubernetes verification..." -ForegroundColor Yellow
        Write-Host "Note: Some functionality will be limited without Kubernetes." -ForegroundColor Yellow
    }
}

# Setup Python virtual environment
Write-Host "`nSetting up Python environment..." -ForegroundColor Cyan
if (-not (Test-Path ".venv")) {
    Write-Host "Creating Python virtual environment..."
    python -m venv .venv
}

# Activate virtual environment
Write-Host "Activating virtual environment..."
& .\.venv\Scripts\Activate.ps1

# Install Python dependencies
Write-Host "Installing Python dependencies..."
pip install flask numpy tensorflow tflite-runtime psutil prometheus-client requests

# If tflite-runtime fails to install (common on Windows), provide alternatives
if ($LASTEXITCODE -ne 0) {
    Write-Host "Note: tflite-runtime installation failed, installing without it..." -ForegroundColor Yellow
    pip install flask numpy tensorflow psutil prometheus-client requests
    
    Write-Host "TensorFlow Lite will be used from the main TensorFlow package" -ForegroundColor Yellow
}

# Check if virtual environment was successfully activated
if (-not $env:VIRTUAL_ENV) {
    Write-Host "✗ Failed to activate virtual environment. Please run the following manually:" -ForegroundColor Red
    Write-Host "   .\.venv\Scripts\Activate.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n===== Environment Setup Complete =====" -ForegroundColor Green
Write-Host "Next step: Run .\scripts\deploy.ps1 to deploy the services" -ForegroundColor Cyan