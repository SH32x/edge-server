# Script to set up Python 3.9 environment for Edge Server implementation
Write-Host "===== Setting up Python 3.9 Environment =====" -ForegroundColor Green

# Check if Python 3.9 is installed
$python39Path = ""
$possiblePaths = @(
    "C:\Python39\python.exe",
    "${env:LOCALAPPDATA}\Programs\Python\Python39\python.exe",
    "${env:ProgramFiles}\Python39\python.exe",
    "${env:ProgramFiles(x86)}\Python39\python.exe"
)

foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $python39Path = $path
        break
    }
}

if (-not $python39Path) {
    Write-Host "Python 3.9 not found. Would you like to download and install it? (y/n)" -ForegroundColor Yellow
    $response = Read-Host
    if ($response -eq "y") {
        Write-Host "Please download Python 3.9 from https://www.python.org/downloads/release/python-3911/" -ForegroundColor Cyan
        Write-Host "After installing, run this script again." -ForegroundColor Cyan
        Start-Process "https://www.python.org/downloads/release/python-3911/"
        exit
    }
    else {
        Write-Host "Continuing with current Python version. TensorFlow Lite may not work correctly." -ForegroundColor Yellow
    }
}
else {
    Write-Host "Found Python 3.9 at: $python39Path" -ForegroundColor Green
}

# Remove previous virtual environment if it exists
if (Test-Path ".venv") {
    Write-Host "Removing existing virtual environment..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force ".venv"
}

# Create a new virtual environment with Python 3.9
if ($python39Path) {
    Write-Host "Creating new virtual environment with Python 3.9..." -ForegroundColor Cyan
    & $python39Path -m venv .venv
    
    # Activate the virtual environment
    Write-Host "Activating virtual environment..." -ForegroundColor Cyan
    & .\.venv\Scripts\Activate.ps1
    
    # Install dependencies
    Write-Host "Installing dependencies..." -ForegroundColor Cyan
    pip install --upgrade pip
    pip install flask numpy psutil prometheus-client requests
    
    # Try to install tflite-runtime (specific to Python 3.9)
    try {
        pip install tflite-runtime
        Write-Host "Successfully installed tflite-runtime" -ForegroundColor Green
    }
    catch {
        Write-Host "Could not install tflite-runtime. Installing TensorFlow instead..." -ForegroundColor Yellow
        pip install tensorflow
        Write-Host "Will use TensorFlow's built-in TFLite functionality" -ForegroundColor Yellow
    }
    
    Write-Host "`n===== Python 3.9 Environment Setup Complete =====" -ForegroundColor Green
    Write-Host "To activate this environment, run: .\.venv\Scripts\Activate.ps1" -ForegroundColor Cyan
}
else {
    Write-Host "Continuing with current Python version" -ForegroundColor Yellow
    # Create virtual environment with current Python
    python -m venv .venv
    & .\.venv\Scripts\Activate.ps1
    pip install --upgrade pip
    pip install flask numpy tensorflow psutil prometheus-client requests
}