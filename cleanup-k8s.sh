#!/bin/bash
set -e

echo "🔄 Resetting kubeadm..."
sudo kubeadm reset -f

echo "🧹 Removing Kubernetes config directories..."
sudo rm -rf /etc/kubernetes /var/lib/etcd /etc/cni/net.d ~/.kube

echo "🧼 Cleaning up CNI interfaces..."
sudo ip link delete cni0 >/dev/null 2>&1 || true
sudo ip link delete flannel.1 >/dev/null 2>&1 || true

echo "🚫 Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

echo "✅ Cleanup complete. Docker untouched."
