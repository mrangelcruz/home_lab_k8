#!/bin/bash
set -e

echo "🚀 Applying a dynamic Flannel network interface patch..."

# First, delete the existing Flannel configuration to ensure a clean state.
kubectl delete -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml --ignore-not-found=true

echo "   - Waiting for old Flannel resources to be deleted..."
sleep 5

# Re-apply the default manifest first.
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

echo "   - Waiting for Flannel DaemonSet to be created..."
kubectl -n kube-flannel wait --for=condition=available --timeout=60s daemonset/kube-flannel-ds

# Now, patch the DaemonSet using a single, atomic command.
# This is more reliable than using sed to modify the YAML file.
echo "   - Patching the Flannel DaemonSet to use the dynamic interface..."
kubectl -n kube-flannel patch ds kube-flannel-ds --type strategic --patch '
spec:
  template:
    spec:
      containers:
      - name: kube-flannel
        args:
        - --ip-masq
        - --kube-subnet-mgr
        - --iface-can-reach=$(K8S_NODE_IP)
        env:
        - name: K8S_NODE_IP
          valueFrom:
            fieldRef:
              fieldPath: status.hostIP
'

echo "✅ Dynamic Flannel patch has been applied."
echo "   Run 'kubectl get pods -n kube-flannel -w' to monitor the rollout."