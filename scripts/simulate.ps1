# PowerShell script for running PlatformIO simulation
# Must be run from the project root directory

Write-Host "===== Running PlatformIO Simulation =====" -ForegroundColor Green

# Check if PlatformIO is installed
$pioCmdPath = "$env:USERPROFILE\.platformio\penv\Scripts\pio.exe"
if (-not (Test-Path $pioCmdPath)) {
    Write-Host "✗ PlatformIO not found. Please run setup-platformio.ps1 first." -ForegroundColor Red
    exit 1
}

# Build the project
Write-Host "`nBuilding PlatformIO project..." -ForegroundColor Cyan
Set-Location -Path "platformio"
& $pioCmdPath run --environment windows_simulation
$buildSuccess = $?

if (-not $buildSuccess) {
    Write-Host "✗ Build failed. Please check the errors above." -ForegroundColor Red
    Set-Location -Path ".."
    exit 1
}

Write-Host "`n✓ Build successful" -ForegroundColor Green

# Run the simulation with output monitoring
Write-Host "`nRunning simulation (Press Ctrl+C to stop)..." -ForegroundColor Cyan
Write-Host "--------------------------------------------------------------" -ForegroundColor Gray

# Execute the program and capture output
$programPath = "platformio\.pio\build\windows_simulation\program.exe"
if (Test-Path $programPath) {
    Set-Location -Path ".."
    & "$programPath"
}
else {
    Write-Host "✗ Program not found at $programPath. Build may have been incomplete." -ForegroundColor Red
    Set-Location -Path ".."
    exit 1
}

Write-Host "--------------------------------------------------------------" -ForegroundColor Gray
Write-Host "`nSimulation completed." -ForegroundColor Green

# Provide information about test input
Write-Host "`nSend test data to the simulation with:" -ForegroundColor Cyan
Write-Host '{\"input\": [1.0, 2.0, 3.0, 4.0]}' -ForegroundColor Yellow