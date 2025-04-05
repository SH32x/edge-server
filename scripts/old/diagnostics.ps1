# PowerShell script for diagnosing Kubernetes deployment issues
# Must be run from the project root directory

Write-Host "===== Diagnosing Kubernetes Deployment Issues =====" -ForegroundColor Green

# Get pod information
Write-Host "`nChecking pod status:" -ForegroundColor Cyan
kubectl get pods -l app=ml-inference

# Get detailed pod description
Write-Host "`nDetailed pod description:" -ForegroundColor Cyan
$podName = kubectl get pods -l app=ml-inference -o jsonpath='{.items[0].metadata.name}' 2>$null
if ($podName) {
    kubectl describe pod $podName
}
else {
    Write-Host "No pods found with label app=ml-inference" -ForegroundColor Red
}

# Get pod logs
Write-Host "`nPod logs:" -ForegroundColor Cyan
if ($podName) {
    kubectl logs $podName
}
else {
    Write-Host "No pods found to get logs from" -ForegroundColor Red
}

# Check Docker image
Write-Host "`nChecking Docker image:" -ForegroundColor Cyan
docker images edge-ml-model

Write-Host "`n===== Diagnostics Complete =====" -ForegroundColor Green
Write-Host "Based on the above information, you may need to fix issues in your Docker image or deployment configuration."