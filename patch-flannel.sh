#!/bin/bash
set -e

echo "🚀 Resetting Flannel configuration to default..."

# The most reliable way to fix a bad patch is to re-apply the original manifest.
# This allows Flannel's default auto-detection logic to run on each node independently.
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

echo "✅ Default Flannel manifest has been re-applied."
echo "   Run 'kubectl get pods -n kube-flannel -w' to monitor the rollout."