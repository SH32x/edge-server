# Edge Inference Server

This project implements a lightweight edge server for performing inference on embedded machine learning models using Docker Desktop Kubernetes and TensorFlow Lite.

## Prerequisites

- Windows 10/11
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) with Kubernetes enabled
- [Python 3.8+](https://www.python.org/downloads/)
- [Visual Studio Code](https://code.visualstudio.com/)
- Git

## VSCode Extensions

Open the project in VSCode and install the recommended extensions:
- Docker
- Kubernetes
- Python
- Remote - WSL (optional)
- PowerShell
- PlatformIO IDE

## Quick Start

### 1. Clone the Repository

```powershell
git clone https://github.com/sh32x/edge-server.git
cd edge-server
```

### 2. Set Up the Environment

```powershell
# Open PowerShell in VSCode terminal and run:
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\setup-docker-kubernetes.ps1
```

### 3. Deploy the Application

```powershell
.\scripts\deploy.ps1
```

### 4. Test the Inference Service

```powershell
.\tests\test-inference.ps1
```


### 5. Set Up and Run PlatformIO Simulation

```powershell
# Set up PlatformIO environment
.\scripts\setup-platformio.ps1

# Run microcontroller simulation
.\scripts\run-simulation.ps1
```

## Running from VSCode

1. Open the project in VSCode
2. Press `Ctrl+Shift+P` and type "Terminal: Create New Terminal" to open a PowerShell terminal
3. Run the scripts as shown above

### Using PlatformIO in VSCode
PlatformIO is fully integrated with VSCode:

Click on the PlatformIO icon in the sidebar (ant-like logo)
Under "Project Tasks", you'll find:

Build: Compile the simulation
Upload: Build and upload to device (for ESP32)
Monitor: Serial monitor
Clean: Clean build files
Test: Run unit tests

For quick access, the PlatformIO toolbar at the bottom of VSCode provides shortcuts for common operations.

