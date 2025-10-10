#!/bin/bash
set -e

# Check if KUBEADM_JOIN_COMMAND is set
if [ -z "$KUBEADM_JOIN_COMMAND" ]; then
    echo "❌ ERROR: KUBEADM_JOIN_COMMAND environment variable is not set."
    echo "   Please get the join command from your control-plane by running:"
    echo "   'kubeadm token create --print-join-command'"
    echo "   Then, export it and re-run this script:"
    echo "   export KUBEADM_JOIN_COMMAND='kubeadm join <...your command...>' "
    exit 1
fi

echo "🚀 Preparing Raspberry Pi to join a Kubernetes cluster as a worker node..."

echo "🧹 Performing pre-emptive cleanup to ensure idempotency..."
sudo kubeadm reset -f || true
sudo rm -rf /etc/cni/net.d

echo "🔧 Preparing node for Kubernetes..."

# Load required kernel modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

# Set required sysctl params, and make them persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system

# Fix for DNS resolution issue on Raspberry Pi OS / Debian
echo "🔧 Applying fix for resolv.conf..."
sudo mkdir -p /run/systemd/resolve
sudo ln -sf /etc/resolv.conf /run/systemd/resolve/resolv.conf

echo "🔧 Installing Kubernetes binaries (kubeadm, kubelet, kubectl)..."
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# Use the new community-hosted package repositories
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-mark unhold kubelet kubeadm kubectl || true
sudo apt-get install -y kubelet kubeadm kubectl

# Disable and stop the kubelet service until it's configured by kubeadm.
echo "   - Disabling kubelet service temporarily..."
sudo systemctl disable --now kubelet

sudo apt-mark hold kubelet kubeadm kubectl

echo "🔧 Configuring containerd..."
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

echo "   - Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo "🤝 Joining the cluster..."
sudo $KUBEADM_JOIN_COMMAND

echo "🎉 This node has successfully joined the cluster!"
echo "   Run 'kubectl get nodes' on your control-plane to see this new worker."