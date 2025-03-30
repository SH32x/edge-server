#!/bin/bash

# Install K3s on the master node
curl -sfL https://get.k3s.io | sh -

# Get the K3s token and IP address of the master node
MASTER_IP=$(hostname -I | awk '{print $1}')
K3S_TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)

# Install K3s on the worker nodes
for WORKER_IP in worker1_ip worker2_ip; do
  ssh root@$WORKER_IP "curl -sfL https://get.k3s.io | K3S_URL=https://$MASTER_IP:6443 K3S_TOKEN=$K3S_TOKEN sh -"
done

# Set up the API server, Kube-scheduler, controller manager, and cluster state on the master node
kubectl apply -f https://raw.githubusercontent.com/kubernetes/website/main/content/en/examples/admin/kube-scheduler.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/website/main/content/en/examples/admin/kube-controller-manager.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/website/main/content/en/examples/admin/cluster-state.yaml
