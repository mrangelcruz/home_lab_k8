#!/bin/bash
set -e

# Check if NODE_IP is set
if [ -z "$NODE_IP" ]; then
    echo "❌ ERROR: NODE_IP environment variable is not set."
    echo "   Please run this script with NODE_IP set to the machine's IP address."
    echo "   Example: export NODE_IP=192.168.1.50"
    exit 1
fi

echo "🚀 Starting Kubernetes installation for Raspberry Pi (arm64)..."

echo "🧹 Performing pre-emptive cleanup to ensure idempotency..."
sudo kubeadm reset -f || true
sudo rm -rf /etc/cni/net.d /etc/kubernetes /var/lib/etcd ~/.kube

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

echo "🔧 Installing Kubernetes binaries (kubeadm, kubelet, kubectl)..."
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# Use the new community-hosted package repositories
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
# Unhold packages in case they were held from a previous run of the script
sudo apt-mark unhold kubelet kubeadm kubectl || true
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl # Prevents accidental upgrades

echo "🔧 Configuring containerd..."
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

echo "   - Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo "🔥 Generating kubeadm configuration..."
sudo mkdir -p /etc/kubeadm
cat <<EOF | sudo tee /etc/kubeadm/kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
nodeRegistration:
  kubeletExtraArgs:
    cgroup-driver: "systemd"
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: "stable-1.29"
apiServer:
  certSANs:
  - "$NODE_IP"
controlPlaneEndpoint: "$NODE_IP:6443"
networking:
  podSubnet: "10.244.0.0/16" # For Flannel
EOF

echo "🔥 Initializing Kubernetes control-plane with kubeadm..."
sudo kubeadm init --config /etc/kubeadm/kubeadm-config.yaml --upload-certs

echo "✅ Kubeadm init complete. Configuring kubectl for the current user..."
mkdir -p "$HOME/.kube"
sudo cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"
sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"

echo "🌐 Applying Flannel CNI..."
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# On systems with multiple interfaces, Flannel may not pick the right one.
echo "   - Patching Flannel to use the correct interface..."
NODE_INTERFACE=$(ip -4 addr show | grep -oP "$NODE_IP"'.*?\K\S+$')
if [ -n "$NODE_INTERFACE" ]; then
    echo "   - Found interface '$NODE_INTERFACE' for IP $NODE_IP. Waiting for flannel to roll out..."
    # Wait for the daemonset to be scheduled and ready before patching
    kubectl -n kube-flannel rollout status ds/kube-flannel-ds --timeout=120s
    echo "   - Patching flannel daemonset to use the correct interface..."
    kubectl patch ds/kube-flannel-ds -n kube-flannel --type='json' -p="[{\"op\": \"add\", \"path\": \"/spec/template/spec/containers/0/args/-\", \"value\": \"--iface=$NODE_INTERFACE\"}]"
fi


echo "🎨 Untainting control-plane node to allow scheduling pods..."
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

echo "🎉 Kubernetes control-plane has been initialized successfully on your Raspberry Pi!"
echo "   Run 'kubectl get nodes' to see the status of your node."
