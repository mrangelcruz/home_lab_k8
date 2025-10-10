#!/bin/bash
set -e

echo "🚀 Starting Kubernetes etcd backup..."

# Define a backup directory and filename with a timestamp
BACKUP_DIR="/var/backups/k8s"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="$BACKUP_DIR/etcd-snapshot-$TIMESTAMP.db"

echo "   - Creating backup directory: $BACKUP_DIR"
sudo mkdir -p "$BACKUP_DIR"

echo "   - Finding the etcd pod..."
ETCD_POD_NAME=$(kubectl get pods -n kube-system -l component=etcd -o jsonpath='{.items[0].metadata.name}')

if [ -z "$ETCD_POD_NAME" ]; then
    echo "❌ ERROR: Could not find the etcd pod."
    exit 1
fi

echo "   - Creating etcd snapshot from pod '$ETCD_POD_NAME'..."
sudo kubectl --kubeconfig="$HOME/.kube/config" exec -n kube-system "$ETCD_POD_NAME" -- etcdctl snapshot save "/var/lib/etcd/snapshot.db"
sudo mv /var/lib/etcd/snapshot.db "$BACKUP_FILE"

echo "✅ Backup successful! Snapshot saved to: $BACKUP_FILE"