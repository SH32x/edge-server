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

For load testing, add the `--load-test` flag:

```powershell
.\tests\test-inference.ps1 --load-test
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

### Debugging Python Code

You can debug the inference service directly in VSCode:
1. Open `docker/inference.py`
2. Press F5 or use the Run and Debug sidebar

## Monitoring and Metrics

The test script automatically sets up port forwarding for metrics services:

- **Prometheus Dashboard**: http://localhost:9090
- **InfluxDB Dashboard**: http://localhost:8086

## API Endpoints

The inference service exposes these endpoints:

- **POST /predict**: Run inference on the model
  ```powershell
  Invoke-RestMethod -Uri "http://localhost:<port>/predict" -Method Post -Body '{"input": [1.0, 2.0, 3.0, 4.0]}' -ContentType "application/json"
  ```

- **GET /health**: Check the health of the service
  ```powershell
  Invoke-RestMethod -Uri "http://localhost:<port>/health" -Method Get
  ```

- **GET /metrics**: Get current metrics
  ```powershell
  Invoke-RestMethod -Uri "http://localhost:<port>/metrics" -Method Get
  ```

## Customizing the ML Model

To use your own TensorFlow Lite model:

1. Convert your model to TensorFlow Lite format
2. Place the `.tflite` file in `docker/model/`
3. Update the `inference.py` script if your model has different input/output requirements
4. Redeploy using the deployment script

## Troubleshooting

### Common Issues

- **Docker Desktop not running**: Start Docker Desktop and enable Kubernetes
- **Permission errors**: Run PowerShell as Administrator or use `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`
- **Network errors**: Check that your ports (8086, 9090, etc.) aren't in use by other applications
- **Docker build errors**: Ensure Docker has enough resources in Docker Desktop settings

### Logs

To view logs for the inference service:

```powershell
kubectl logs -l app=ml-inference
```

## PlatformIO Simulation

The project includes a PlatformIO environment for microcontroller simulation:

### Directory Structure
```
platformio/
├── platformio.ini          # PlatformIO configuration
└── src/                    # Source code
    ├── main.cpp            # Microcontroller code
    └── model.tflite        # TensorFlow Lite model
```

### Simulation Features
- TensorFlow Lite for microcontrollers
- JSON-based communication
- Metrics reporting
- Compatible with x86 Windows (native environment)
- Optional ESP32 support for hardware deployment

### Testing the Simulation

When the simulation is running, you can send test data via the serial monitor:
```json
{"input": [1.0, 2.0, 3.0, 4.0]}
```

The simulation will process the input through the TensorFlow Lite model and return a result:
```json
{"status":"success","inference_time_ms":5,"output":[2.34567]}
```

## Clean Up

To remove all deployed resources:

```powershell
kubectl delete -f kubernetes/deployment.yaml
kubectl delete -f kubernetes/service.yaml
kubectl delete -f kubernetes/metrics/prometheus.yaml
kubectl delete -f kubernetes/metrics/influxdb.yaml
```

To stop port forwarding:

```powershell
Get-Job | Stop-Job; Get-Job | Remove-Job
```