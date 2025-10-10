# home_lab_k8

## Launch cluster via Terraform

    terr init
    terr fmt
    terr validate
    terr plan
    terr apply -auto-approve

The terraform state is uploaded to S3, and tfstate lock is regsitered in dynamodb, both in us-west-2 region.

### Raspberry Pi join the cluser

#### On the Controller:

    scp join-k8s-pi.sh pi@raspberrypi:/home/pi/

#### On the Raspberry Pi:

    ssh pi@raspberrypi
    ./join-k8s-pi.sh

#### On the Controller

    ./patch-flannel.sh


#### On the Raspberry Pi:

    ssh pi@raspberrypi
    ./join-k8s-pi.sh

##### NOTE:
ignore install-k8s-pi.sh (this sets up a controller on the raspberry pi)

## DISASTER RECOVERY
Since your cluster was created with kubeadm, the entire state of your cluster—all the deployments, services, configs, secrets, etc.—is stored in an etcd database running on your ac-dream control-plane node.

The best way to save the state of your controller is to create a snapshot of the etcd database. This is a safe, online operation that doesn't require you to shut down your cluster.

Here is a step-by-step guide on how to back up and restore your cluster's state.

Creating a Backup Script
It's best practice to create a script for this process so you can run it easily and consistently. I'll create a new script for you called backup-cluster.sh to be placed on your ac-dream control-plane node.

New file: backup-cluster.sh

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
    sudo kubectl exec -n kube-system "$ETCD_POD_NAME" -- etcdctl snapshot save "/var/lib/etcd/snapshot.db"
    sudo mv /var/lib/etcd/snapshot.db "$BACKUP_FILE"

    echo "✅ Backup successful! Snapshot saved to: $BACKUP_FILE"

## How to Use the Backup Script

Place the script on your ac-dream control-plane node.
Make it executable: chmod +x backup-cluster.sh
Run it:

bash

    ./backup-cluster.sh

This will create a timestamped snapshot file in /var/backups/k8s/. You can run this periodically or whenever you're about to make a significant change to your cluster.
How to Restore from a Backup
Restoring is more involved and requires downtime, as you need to stop the control-plane to replace the database. Here is the process:

🚨 Important: Only perform a restore if your cluster is truly broken.

SSH into your ac-dream control-plane node.

Identify the snapshot file you want to restore from (e.g., /var/backups/k8s/etcd-snapshot-2024-10-26_10-30-00.db).

Stop the Kubernetes control-plane components. The easiest way to do this is to temporarily move their manifest files so kubelet stops them.

bash
 Show full code block 
sudo mv /etc/kubernetes/manifests/etcd.yaml /tmp/
sudo mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/
sudo mv /etc/kubernetes/manifests/kube-controller-manager.yaml /tmp/
sudo mv /etc/kubernetes/manifests/kube-scheduler.yaml /tmp/
# Wait a moment for the pods to terminate
sleep 15
Run the etcdctl restore command. This command will create a new etcd data directory from your snapshot.

bash
 Show full code block 
# Remove the old, corrupted data directory
sudo rm -rf /var/lib/etcd/

# Restore from your backup file
sudo etcdctl snapshot restore /var/backups/k8s/<your-snapshot-file.db> \
  --data-dir /var/lib/etcd
(Note: etcdctl should be installed on your control-plane. If not, run sudo apt-get install etcd-client)

Restart the control-plane. Move the manifests back into place, and kubelet will restart everything with the restored data.

bash
sudo mv /tmp/etcd.yaml /etc/kubernetes/manifests/
sudo mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/
sudo mv /tmp/kube-controller-manager.yaml /etc/kubernetes/manifests/
sudo mv /tmp/kube-scheduler.yaml /etc/kubernetes/manifests/
Your cluster will come back online in the exact state it was in when you took the snapshot.