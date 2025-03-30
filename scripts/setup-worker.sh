#!/bin/bash
# Setup script for worker nodes

set -e

# Check if the required parameters are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <master_ip> <node_token>"
    echo "Example: $0 192.168.1.100 K10abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
    exit 1
fi

MASTER_IP=$1
NODE_TOKEN=$2

echo "===== Setting up K3s Worker Node ====="
echo "Master IP: $MASTER_IP"
echo "Using provided node token"

# Install K3s in agent mode (worker)
echo "Installing K3s..."
curl -sfL https://get.k3s.io | K3S_URL=https://${MASTER_IP}:6443 K3S_TOKEN=${NODE_TOKEN} sh -

echo "===== K3s Worker Node Setup Complete ====="
echo "Worker node has joined the cluster"
echo ""
echo "Note: To verify the node has joined successfully, run the following on the master node:"
echo "kubectl get nodes"