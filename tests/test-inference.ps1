# PowerShell script for testing the edge inference service
# Must be run from the project root directory

Write-Host "===== Testing Edge Inference Service =====" -ForegroundColor Green

# Check if deployment is running
try {
    $podStatus = kubectl get pods -l app=ml-inference -o jsonpath='{.items[0].status.phase}'
    if ($podStatus -ne "Running") {
        Write-Host "✗ Inference service is not running. Please run deploy.ps1 first." -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ Inference service is running" -ForegroundColor Green
}
catch {
    Write-Host "✗ Inference service is not deployed. Please run deploy.ps1 first." -ForegroundColor Red
    exit 1
}

# Determine service URL
$serviceUrl = ""
if (Test-Path ".service_url") {
    $serviceUrl = Get-Content ".service_url"
}
else {
    $nodePort = kubectl get service ml-inference-service -o jsonpath='{.spec.ports[0].nodePort}'
    if ($nodePort) {
        $serviceUrl = "http://localhost:$nodePort"
    }
    else {
        Write-Host "✗ Could not determine service URL" -ForegroundColor Red
        exit 1
    }
}

Write-Host "Service URL: $serviceUrl" -ForegroundColor Cyan

# Test health endpoint
Write-Host "`nTesting health endpoint..." -ForegroundColor Cyan
try {
    $healthResponse = Invoke-RestMethod -Uri "$serviceUrl/health" -Method Get
    Write-Host "Health response: " -NoNewline
    $healthResponse | ConvertTo-Json
}
catch {
    Write-Host "✗ Health endpoint test failed: $_" -ForegroundColor Red
}

# Test inference endpoint
Write-Host "`nTesting inference endpoint..." -ForegroundColor Cyan
try {
    $body = @{
        input = @(1.0, 2.0, 3.0, 4.0)
    } | ConvertTo-Json

    $inferenceResponse = Invoke-RestMethod -Uri "$serviceUrl/predict" -Method Post -Body $body -ContentType "application/json"
    Write-Host "Inference response: " -NoNewline
    $inferenceResponse | ConvertTo-Json
}
catch {
    Write-Host "✗ Inference endpoint test failed: $_" -ForegroundColor Red
}

# Test metrics endpoint
Write-Host "`nTesting metrics endpoint..." -ForegroundColor Cyan
try {
    $metricsResponse = Invoke-RestMethod -Uri "$serviceUrl/metrics" -Method Get
    Write-Host "Metrics response: " -NoNewline
    $metricsResponse | ConvertTo-Json
}
catch {
    Write-Host "✗ Metrics endpoint test failed: $_" -ForegroundColor Red
}

# Setup port forwarding for Prometheus (in background)
Write-Host "`nSetting up port forwarding for Prometheus (background process)..." -ForegroundColor Cyan
$job = Start-Job -ScriptBlock {
    kubectl port-forward service/prometheus 9090:9090
}

# Setup port forwarding for InfluxDB (in background)
Write-Host "Setting up port forwarding for InfluxDB (background process)..." -ForegroundColor Cyan
$job2 = Start-Job -ScriptBlock {
    kubectl port-forward service/influxdb 8086:8086
}

Write-Host "`n===== Testing Complete =====" -ForegroundColor Green
Write-Host "Prometheus UI is available at: http://localhost:9090" -ForegroundColor Yellow
Write-Host "InfluxDB UI is available at: http://localhost:8086" -ForegroundColor Yellow
Write-Host "`nTo stop port forwarding, run:" -ForegroundColor Cyan
Write-Host "Get-Job | Stop-Job; Get-Job | Remove-Job" -ForegroundColor Yellow

# Optional load test
if ($args[0] -eq "--load-test") {
    Write-Host "`nRunning load test (10 requests)..." -ForegroundColor Cyan
    for ($i = 1; $i -le 10; $i++) {
        Write-Host "Request $i" -ForegroundColor Gray
        
        $randomInputs = @(
            [math]::Round((Get-Random -Minimum 0 -Maximum 10) + (Get-Random -Minimum 0 -Maximum 1), 1),
            [math]::Round((Get-Random -Minimum 0 -Maximum 10) + (Get-Random -Minimum 0 -Maximum 1), 1),
            [math]::Round((Get-Random -Minimum 0 -Maximum 10) + (Get-Random -Minimum 0 -Maximum 1), 1),
            [math]::Round((Get-Random -Minimum 0 -Maximum 10) + (Get-Random -Minimum 0 -Maximum 1), 1)
        )
        
        $body = @{
            input = $randomInputs
        } | ConvertTo-Json
        
        try {
            Invoke-RestMethod -Uri "$serviceUrl/predict" -Method Post -Body $body -ContentType "application/json" | Out-Null
            Write-Host "Success" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed: $_" -ForegroundColor Red
        }
        
        Start-Sleep -Seconds 1
    }
    Write-Host "Load test completed." -ForegroundColor Green
}