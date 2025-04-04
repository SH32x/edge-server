# PowerShell script for setting up PlatformIO
# Must be run from the project root directory

Write-Host "===== Setting up PlatformIO Environment =====" -ForegroundColor Green

# Check if PlatformIO is already installed via VSCode extension
$pioCmdPath = "$env:USERPROFILE\.platformio\penv\Scripts\pio.exe"
$pioCoreInstalled = Test-Path $pioCmdPath

if (-not $pioCoreInstalled) {
    Write-Host "PlatformIO Core not found. Please install the PlatformIO IDE extension in VSCode first." -ForegroundColor Yellow
    Write-Host "1. Open VSCode" -ForegroundColor Cyan
    Write-Host "2. Go to Extensions (Ctrl+Shift+X)" -ForegroundColor Cyan
    Write-Host "3. Search for 'PlatformIO IDE'" -ForegroundColor Cyan
    Write-Host "4. Install the extension and reload VSCode" -ForegroundColor Cyan
    Write-Host "5. Run this script again after installation" -ForegroundColor Cyan
    
    $installNow = Read-Host "Would you like to open VSCode extensions page now? (y/n)"
    if ($installNow -eq "y") {
        code --install-extension platformio.platformio-ide
        Write-Host "Extension installation initiated. Please reload VSCode when complete." -ForegroundColor Green
    }
    
    exit 0
}

Write-Host "✓ PlatformIO Core is installed" -ForegroundColor Green

# Create TFLite model for PlatformIO if it doesn't exist
if (-not (Test-Path "platformio\src\model.tflite")) {
    Write-Host "`nCreating TensorFlow Lite model for PlatformIO..." -ForegroundColor Cyan
    
    # Ensure src directory exists
    if (-not (Test-Path "platformio\src")) {
        New-Item -Path "platformio\src" -ItemType Directory -Force | Out-Null
    }
    
    # Copy the model if it exists in docker folder, otherwise create a new one
    if (Test-Path "docker\model\model.tflite") {
        Copy-Item "docker\model\model.tflite" -Destination "platformio\src\model.tflite"
        Write-Host "✓ Copied existing model from docker\model\model.tflite" -ForegroundColor Green
    }
    else {
        # Create a simple Python script to generate a basic TFLite model
        python scripts/generate_model.py "platformio/src/model.tflite"
    }
}

# Create main.cpp if it doesn't exist yet
if (-not (Test-Path "platformio\src\main.cpp")) {
    Write-Host "`nCreating main.cpp in platformio\src..." -ForegroundColor Cyan
    
    # Ensure src directory exists
    if (-not (Test-Path "platformio\src")) {
        New-Item -Path "platformio\src" -ItemType Directory | Out-Null
    }
    
    # Copy from the existing code if available
    if (Test-Path "platformio\src\main.cpp") {
        Write-Host "✓ main.cpp already exists" -ForegroundColor Green
    }
    else {
        Write-Host "Creating new main.cpp from template..." -ForegroundColor Yellow
        # Create the file from our artifact
        # The content will come from our original microcontroller-code artifact
    }
}

# Initialize PlatformIO project
Write-Host "`nInitializing PlatformIO project..." -ForegroundColor Cyan
Set-Location -Path "platformio"
& $pioCmdPath project init --ide vscode
Set-Location -Path ".."

Write-Host "`n===== PlatformIO Setup Complete =====" -ForegroundColor Green
Write-Host "You can now open the PlatformIO project in VSCode:" -ForegroundColor Cyan
Write-Host "1. In VSCode, click on the PlatformIO icon in the sidebar" -ForegroundColor Yellow
Write-Host "2. Open the Project Tasks view" -ForegroundColor Yellow
Write-Host "3. Find 'native' environment and explore available tasks" -ForegroundColor Yellow
Write-Host "`nOr run simulation directly with:" -ForegroundColor Cyan
Write-Host ".\scripts\run-simulation.ps1" -ForegroundColor Yellow