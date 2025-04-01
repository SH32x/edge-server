# PowerShell script to check the status of Kubernetes deployments
Write-Host "===== Checking Kubernetes Deployment Status =====" -ForegroundColor Green

# Check if kubectl is available
try {
    kubectl version --client | Out-Null
}
catch {
    Write-Host "✗ kubectl not available. Please make sure Kubernetes is set up properly." -ForegroundColor Red
    exit 1
}

# Check deployment status
Write-Host "`nChecking ml-inference deployment status:" -ForegroundColor Cyan
$deploymentInfo = kubectl get deployment ml-inference -o json | ConvertFrom-Json

if ($deploymentInfo) {
    $availableReplicas = $deploymentInfo.status.availableReplicas
    $replicas = $deploymentInfo.status.replicas
    $updatedReplicas = $deploymentInfo.status.updatedReplicas
    $readyReplicas = $deploymentInfo.status.readyReplicas
    
    Write-Host "Deployment Name: $($deploymentInfo.metadata.name)" -ForegroundColor White
    Write-Host "Created: $($deploymentInfo.metadata.creationTimestamp)" -ForegroundColor White
    Write-Host "Desired Replicas: $replicas" -ForegroundColor White
    Write-Host "Updated Replicas: $updatedReplicas" -ForegroundColor White
    Write-Host "Ready Replicas: $readyReplicas" -ForegroundColor White
    Write-Host "Available Replicas: $availableReplicas" -ForegroundColor White
    
    # Get the pods associated with this deployment
    Write-Host "`nPods status:" -ForegroundColor Cyan
    kubectl get pods -l app=ml-inference
    
    # Check for any pod errors
    Write-Host "`nChecking for pod issues..." -ForegroundColor Cyan
    $problemPods = kubectl get pods -l app=ml-inference -o json | ConvertFrom-Json
    
    foreach ($pod in $problemPods.items) {
        $podName = $pod.metadata.name
        $podStatus = $pod.status.phase
        
        if ($podStatus -ne "Running") {
            Write-Host "`nWarning: Pod $podName is not running (Status: $podStatus)" -ForegroundColor Yellow
            
            # Check for container issues
            foreach ($containerStatus in $pod.status.containerStatuses) {
                if (-not $containerStatus.ready) {
                    if ($containerStatus.state.waiting) {
                        $reason = $containerStatus.state.waiting.reason
                        $message = $containerStatus.state.waiting.message
                        Write-Host "Container issue: $reason - $message" -ForegroundColor Red
                    }
                    elseif ($containerStatus.state.terminated) {
                        $reason = $containerStatus.state.terminated.reason
                        $exitCode = $containerStatus.state.terminated.exitCode
                        Write-Host "Container terminated: $reason (Exit code: $exitCode)" -ForegroundColor Red
                        
                        # Get logs from failed container
                        Write-Host "`nLogs from failed container:" -ForegroundColor Yellow
                        kubectl logs $podName
                    }
                }
            }
        }
    }
    
    # Show resource usage
    Write-Host "`nResource usage:" -ForegroundColor Cyan
    kubectl top pods -l app=ml-inference
    
    # Show service information
    Write-Host "`nService information:" -ForegroundColor Cyan
    kubectl get service ml-inference-service
    
    $nodePort = kubectl get service ml-inference-service -o jsonpath='{.spec.ports[0].nodePort}'
    if ($nodePort) {
        Write-Host "`nML inference service is accessible at:" -ForegroundColor Green
        Write-Host "http://localhost:$nodePort" -ForegroundColor Yellow
    }
}
else {
    Write-Host "✗ Deployment ml-inference not found" -ForegroundColor Red
}

# Provide troubleshooting tips
Write-Host "`n===== Troubleshooting Tips =====" -ForegroundColor Green
Write-Host "1. To restart deployment:" -ForegroundColor Cyan
Write-Host "   kubectl rollout restart deployment ml-inference" -ForegroundColor Yellow

Write-Host "2. To view detailed logs:" -ForegroundColor Cyan
Write-Host "   kubectl logs -l app=ml-inference" -ForegroundColor Yellow

Write-Host "3. To delete and redeploy:" -ForegroundColor Cyan
Write-Host "   kubectl delete -f kubernetes/deployment.yaml" -ForegroundColor Yellow
Write-Host "   kubectl apply -f kubernetes/deployment.yaml" -ForegroundColor Yellow

Write-Host "4. To check Docker Desktop status:" -ForegroundColor Cyan
Write-Host "   Open Docker Desktop and verify Kubernetes is running" -ForegroundColor Yellow