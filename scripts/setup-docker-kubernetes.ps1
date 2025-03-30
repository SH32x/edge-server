# PowerShell script for setting up the edge inference service on Windows
# Must be run from the project root directory

Write-Host "===== Setting up Edge Inference Service on Windows =====" -ForegroundColor Green

# Check if Docker Desktop is installed and running
try {
    docker version | Out-Null
    Write-Host "✓ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker is not running. Please start Docker Desktop with Kubernetes enabled." -ForegroundColor Red
    exit 1
}

# Check if Kubernetes is available
try {
    kubectl get nodes | Out-Null
    Write-Host "✓ Kubernetes is available" -ForegroundColor Green
} catch {
    Write-Host "✗ Kubernetes is not available. Please enable Kubernetes in Docker Desktop settings." -ForegroundColor Red
    Write-Host "   1. Open Docker Desktop" -ForegroundColor Yellow
    Write-Host "   2. Go to Settings > Kubernetes" -ForegroundColor Yellow
    Write-Host "   3. Check 'Enable Kubernetes'" -ForegroundColor Yellow
    Write-Host "   4. Click Apply & Restart" -ForegroundColor Yellow
    exit 1
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
pip install flask numpy tensorflow tensorflow-lite psutil prometheus-client requests

# Check if virtual environment was successfully activated
if (-not $env:VIRTUAL_ENV) {
    Write-Host "✗ Failed to activate virtual environment. Please run the following manually:" -ForegroundColor Red
    Write-Host "   .\.venv\Scripts\Activate.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n===== Environment Setup Complete =====" -ForegroundColor Green
Write-Host "Next step: Run .\scripts\deploy.ps1 to deploy the services" -ForegroundColor Cyan