#!/bin/bash
# Setup script for the master node

set -e

echo "===== Setting up K3s Master Node ====="

# Install K3s in server mode (master)
echo "Installing K3s..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -

# Wait for K3s to initialize
echo "Waiting for K3s to initialize..."
sleep 10

# Get node token for worker nodes
NODE_TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)
MASTER_IP=$(hostname -I | awk '{print $1}')

echo "===== K3s Master Node Setup Complete ====="
echo "Master Node IP: $MASTER_IP"
echo "Node Token: $NODE_TOKEN"
echo "Use these values when setting up worker nodes."

# Configure kubectl for easy access
mkdir -p $HOME/.kube
sudo cp /etc/rancher/k3s/k3s.yaml $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=$HOME/.kube/config
echo "export KUBECONFIG=$HOME/.kube/config" >> $HOME/.bashrc

# Set up metrics collection
echo "===== Setting up Metrics Collection ====="

# Create InfluxDB credentials secret
kubectl create secret generic influxdb-creds \
  --from-literal=username=admin \
  --from-literal=password=edge-admin-pw

# Apply InfluxDB configuration
kubectl apply -f ../kubernetes/metrics/influxdb.yaml

# Apply Prometheus configuration
kubectl apply -f ../kubernetes/metrics/prometheus.yaml

echo "===== Metrics Collection Setup Complete ====="

# Display kubectl get nodes to verify setup
echo "Cluster nodes:"
kubectl get nodes

echo "Master node setup completed successfully!"
echo ""
echo "Next steps:"
echo "1. Set up worker nodes using scripts/setup-worker.sh"
echo "2. Deploy the application using scripts/deploy.sh"