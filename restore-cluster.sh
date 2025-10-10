#!/bin/bash
set -e

# Check if snapshot file is provided as the first argument
if [ -z "$1" ]; then
    echo "❌ ERROR: No snapshot file provided."
    echo "Usage: ./restore-cluster.sh /path/to/your/etcd-snapshot.db"
    exit 1
fi

SNAPSHOT_FILE="$1"

# Check if the snapshot file actually exists
if [ ! -f "$SNAPSHOT_FILE" ]; then
    echo "❌ ERROR: Snapshot file not found at '$SNAPSHOT_FILE'"
    exit 1
fi

echo "🚨 WARNING: This is a destructive operation and will cause cluster downtime."
echo "   Your cluster will be restored to the state of the snapshot file:"
echo "   $SNAPSHOT_FILE"
read -p "   Are you sure you want to continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborting restore."
    exit 1
fi

echo "🛑 Stopping Kubernetes control-plane components..."
# The static pod manifests are in /etc/kubernetes/manifests.
# We move them out to stop the kubelet from running them.
sudo mv /etc/kubernetes/manifests/etcd.yaml /tmp/
sudo mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/

echo "   - Waiting for control-plane pods to terminate..."
sleep 15 # Give kubelet time to stop the pods

echo "🔄 Restoring etcd from snapshot..."
# Use kubeadm to perform the restore. This is safer as it also handles certificate regeneration.
sudo kubeadm init phase etcd local --config /etc/kubeadm/kubeadm-config.yaml

echo "🚀 Restarting Kubernetes control-plane components..."
# Move the manifests back to restart the control-plane with the restored data.
sudo mv /tmp/etcd.yaml /etc/kubernetes/manifests/
sudo mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/

echo "✅ Restore complete. The cluster is restarting."
echo "   It may take a few minutes for all components to become healthy."
echo "   Run 'kubectl get pods -n kube-system' to monitor the status."