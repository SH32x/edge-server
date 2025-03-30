# Edge Inference Server

This project implements a lightweight edge server for performing inference on embedded machine learning models using Kubernetes (K3s) and TensorFlow Lite for microcontrollers.

## System Architecture

The system is composed of:
- **1 Master Node**: Higher-performance device running the Kubernetes control plane
- **2 Worker Nodes**: Less powerful devices running the worker services

### Key Components

- **Kubernetes (K3s)**: Lightweight Kubernetes distribution optimized for edge computing
- **TensorFlow Lite**: Optimized version of TensorFlow for microcontroller environments
- **Docker**: Containerization for the ML model
- **Prometheus & InfluxDB**: Metrics collection and storage
- **PlatformIO**: Simulator for the microcontroller environment

## Prerequisites

- Three devices with Linux installed (one master, two workers)
- Docker installed on all nodes
- Git
- PlatformIO (for simulation)
- Internet connection for downloading packages

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/edge-inference-server.git
cd edge-inference-server
```

### 2. Set Up the Master Node

```bash
chmod +x scripts/setup-master.sh
./scripts/setup-master.sh
```

The script will output the Master IP and Node Token that you'll need for the worker nodes.

### 3. Set Up the Worker Nodes

On each worker node, run:

```bash
chmod +x scripts/setup-worker.sh
./scripts/setup-worker.sh <master_ip> <node_token>
```

Replace `<master_ip>` and `<node_token>` with the values from the master node setup.

### 4. Deploy the Application

On the master node, run:

```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

This will build the Docker image, deploy it to Kubernetes, and set up the services.

### 5. Test the Inference Service

Run the test script to verify that the inference service is working:

```bash
chmod +x tests/test-inference.sh
./tests/test-inference.sh
```

## PlatformIO Simulation

To run the microcontroller simulation with PlatformIO:

```bash
cd platformio
pio run
```

This will compile the code. To upload and run the simulation:

```bash
pio run -t upload
pio device monitor
```

## Metrics Collection

The system collects the following metrics:
- **Simulation clock speed**: CPU frequency of the nodes
- **Memory usage**: RAM used by the inference service
- **Bandwidth**: Data transferred for inference requests
- **Inference time**: Time taken to process each inference request

### Accessing Metrics

#### Prometheus Dashboard

```bash
kubectl port-forward service/prometheus 9090:9090
```

Then open `http://localhost:9090` in your browser.

#### InfluxDB Dashboard

```bash
kubectl port-forward service/influxdb 8086:8086
```

Then open `http://localhost:8086` in your browser.

## API Endpoints

The inference service exposes the following endpoints:

- **POST /predict**: Run inference on the model
  ```
  curl -X POST -H "Content-Type: application/json" -d '{"input": [1.0, 2.0, 3.0, 4.0]}' http://<service_ip>/predict
  ```

- **GET /health**: Check the health of the service
  ```
  curl http://<service_ip>/health
  ```

- **GET /metrics**: Get current metrics
  ```
  curl http://<service_ip>/metrics
  ```

## Project Structure

```
edge-inference-server/
├── kubernetes/          # Kubernetes configuration files
├── docker/              # Docker configuration 
├── platformio/          # PlatformIO project
├── scripts/             # Setup and deployment scripts
└── tests/               # Test scripts
```

## Customizing the ML Model

To use your own TensorFlow Lite model:

1. Convert your model to TensorFlow Lite format
2. Place the `.tflite` file in `docker/model/`
3. Update the `inference.py` script if your model has different input/output requirements
4. Rebuild and redeploy using the deployment script

## Troubleshooting

### Common Issues

- **Nodes not joining the cluster**: Verify that the correct master IP and node token are being used
- **Docker image not building**: Check Docker installation and ensure the Dockerfile is correct
- **Service not accessible**: Verify the service is running with `kubectl get services`
- **Metrics not collecting**: Check that Prometheus and InfluxDB pods are running

### Logs

To view logs for the inference service:

```bash
kubectl logs -l app=ml-inference
```

## License

MIT