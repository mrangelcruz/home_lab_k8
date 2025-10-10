#!/bin/bash
set -e

# Check if NODE_IP is set
if [ -z "$NODE_IP" ]; then
    echo "❌ ERROR: NODE_IP environment variable is not set."
    echo "Please run this script with NODE_IP set to the machine's IP address."
    exit 1
fi

echo "🚀 Starting Kubernetes installation..."

echo "🧹 Performing pre-emptive cleanup to ensure idempotency..."
# Reset any existing cluster state. The '|| true' ensures the script doesn't fail if kubeadm isn't installed yet.
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

echo "🔧 Configuring containerd..."
# Stop containerd and remove its state to ensure a clean start
sudo systemctl stop containerd
sudo rm -rf /var/lib/containerd

# Ensure the containerd config directory exists
sudo mkdir -p /etc/containerd
# Generate the default containerd configuration, overwriting if it exists
sudo containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
# Enable the SystemdCgroup by replacing the line 'SystemdCgroup = false' with 'SystemdCgroup = true'
# The default config may disable the CRI plugin. This ensures it's enabled.
sudo sed -i 's/disabled_plugins = \["cri"\]/#disabled_plugins = \["cri"\]/' /etc/containerd/config.toml
# Use systemd as the cgroup driver
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
# Restart and enable containerd to apply the new configuration
sudo systemctl restart containerd
sudo systemctl enable containerd

# Re-enable swap setting in fstab in case it was commented out
echo "   - Disabling swap..."
sudo swapoff -a
# The cleanup script comments this out, so we ensure it's uncommented for a fresh run
sudo sed -i '/ swap / s/^#//' /etc/fstab 

echo "🔥 Generating kubeadm configuration..."
# Ensure the kubeadm config directory exists
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
kubernetesVersion: "v1.29.15" # Match the version from your error log
apiServer:
  certSANs:
  - "$NODE_IP"
controlPlaneEndpoint: "$NODE_IP:6443"
networking:
  podSubnet: "10.244.0.0/16" # For Flannel
EOF

echo "🔥 Initializing Kubernetes control-plane with kubeadm..."
sudo kubeadm init --config /etc/kubeadm/kubeadm-config.yaml --upload-certs --v=5

echo "✅ Kubeadm init complete. Configuring kubectl for the current user..."
mkdir -p "$HOME/.kube"
sudo cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"
sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"

echo "🌐 Applying Flannel CNI..."
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# On systems with multiple interfaces, Flannel may not pick the right one.
# We'll patch the DaemonSet to explicitly use the interface that has our NODE_IP.
echo "   - Patching Flannel to use the correct interface..."
NODE_INTERFACE=$(ip -4 addr show | grep -oP "$NODE_IP"'.*?\K\S+$')
if [ -n "$NODE_INTERFACE" ]; then
    echo "   - Found interface '$NODE_INTERFACE' for IP $NODE_IP. Waiting for flannel to roll out..."
    # Wait for the daemonset to be scheduled and ready before patching
    kubectl -n kube-flannel rollout status ds/kube-flannel-ds --timeout=120s
    echo "   - Patching flannel daemonset to use the correct interface..."
    kubectl patch ds/kube-flannel-ds -n kube-flannel --type='json' -p="[{\"op\": \"add\", \"path\": \"/spec/template/spec/containers/0/args/-\", \"value\": \"--iface=$NODE_INTERFACE\"}]"
fi


# By default, control-plane nodes are not schedulable.
# The following command removes that "taint" so you can run pods on it.
echo "🎨 Untainting control-plane node to allow scheduling pods..."
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

echo "🎉 Kubernetes control-plane has been initialized successfully!"
echo "   Run 'kubectl get nodes' to see the status of your node."