#!/bin/bash
set -e

echo "🚀 Starting Kubernetes etcd backup (kubeadm method)..."

# Define a backup directory and filename with a timestamp
BACKUP_DIR="/var/backups/k8s"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
SNAPSHOT_FILE="$BACKUP_DIR/etcd-snapshot-$TIMESTAMP.db"

echo "   - Creating backup directory: $BACKUP_DIR"
sudo mkdir -p "$BACKUP_DIR"

echo "   - Creating etcd snapshot..."

# This command uses etcdctl on the host to create a snapshot.
# It uses the certificates that kubeadm places on the control-plane node to securely connect to etcd.
# This is the officially recommended method for kubeadm clusters.
sudo ETCDCTL_API=3 etcdctl snapshot save "$SNAPSHOT_FILE" \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

echo "   - Verifying snapshot integrity..."
sudo ETCDCTL_API=3 etcdctl snapshot status "$SNAPSHOT_FILE"

echo "✅ Backup successful! Snapshot saved to: $SNAPSHOT_FILE"