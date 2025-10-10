#!/bin/bash
set -e

echo "🚀 Applying Flannel network interface patch..."

# Find the name of the first node with the 'control-plane' role.
CONTROL_PLANE_NODE_NAME=$(kubectl get nodes -l node-role.kubernetes.io/control-plane -o jsonpath='{.items[0].metadata.name}')

if [ -z "$CONTROL_PLANE_NODE_NAME" ]; then
    echo "❌ ERROR: Could not find a control-plane node."
    exit 1
fi

# Get the internal IP of that control-plane node.
CONTROL_PLANE_IP=$(kubectl get node "$CONTROL_PLANE_NODE_NAME" -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')

# Find the network interface on the local machine that is associated with that IP.
NODE_INTERFACE=$(ip -4 addr show | grep -oP "$CONTROL_PLANE_IP"'.*?\K\S+$')

if [ -n "$NODE_INTERFACE" ]; then
    echo "✅ Found control-plane node '$CONTROL_PLANE_NODE_NAME' with interface '$NODE_INTERFACE'."
    echo "   Patching Flannel to use this interface across the cluster..."
    kubectl patch ds/kube-flannel-ds -n kube-flannel --type='json' -p="[{\"op\": \"add\", \"path\": \"/spec/template/spec/containers/0/args/-\", \"value\": \"--iface=$NODE_INTERFACE\"}]"
    echo "✅ Flannel patch applied. Pods in the 'kube-flannel' namespace will restart with the new configuration."
else
    echo "❌ Could not determine the network interface for Flannel. Please patch it manually."
fi