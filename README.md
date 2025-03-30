# edge-server

## Overview

This project implements an edge server with a master node and two worker nodes using lightweight Kubernetes (K3s) and PlatformIO simulator. The edge server is designed to carry out simple inference on an embedded machine learning model using Tensorflow lite for microcontrollers.

## Architecture

The architecture consists of three nodes:
- **Master Node**: A higher-performance device that serves as the master node. It includes the API server, Kube-scheduler, controller manager, and cluster state.
- **Worker Nodes**: Two less powerful devices that serve as worker nodes.

## Setup Instructions

### Prerequisites

- Visual Studio Code (VSCode) installed on Windows 11
- Docker installed
- Python installed

### Step 1: Install and Configure K3s

Run the `k3s-setup.sh` script to install and configure K3s on the master and worker nodes.

```sh
./k3s-setup.sh
```

### Step 2: Build and Run the Docker Image

Build the Docker image containing the neural network model using Tensorflow lite for microcontrollers.

```sh
docker build -t edge-server-model .
docker run -d --name edge-server-model edge-server-model
```

### Step 3: Configure PlatformIO

Use the `platformio.ini` file to configure the PlatformIO simulator and the target microcontroller.

### Step 4: Collect Metrics

Run the `metrics-collector.py` script to collect metrics such as simulation clock speed, memory use, and bandwidth from the Kubernetes API and store them in a simple database.

```sh
python metrics-collector.py
```

## VSCode Extensions and Dependencies

To work on this project in Visual Studio Code, you will need to install the following extensions and dependencies:

### VSCode Extensions

- PlatformIO IDE
- Docker
- Python

### Python Dependencies

Install the required Python dependencies using the `requirements.txt` file.

```sh
pip install -r requirements.txt
```
