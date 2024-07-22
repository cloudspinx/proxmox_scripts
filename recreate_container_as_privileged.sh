#!/bin/bash
# List all containers with their IDs and names
echo "Available containers:"
pct list


# Prompt user to enter a container ID
read -p "Enter the container ID you want to recreate as privileged: " CONTAINER_ID

# Prompt user to enter storage pool to use
# List storage pools
echo ""
echo "Available storage pools"
pvesm status
read -p "Enter the storage pool to restore container: " STORAGE_POOL

# Validate that the container ID is valid
if ! pct status $CONTAINER_ID &>/dev/null; then
    echo "Container ID $CONTAINER_ID is not valid."
    exit 1
fi

# Stop the container
echo "Stopping container $CONTAINER_ID..."
pct stop $CONTAINER_ID
if [ $? -ne 0 ]; then
    echo "Failed to stop the container $CONTAINER_ID."
    exit 1
fi

# Backup the container
BACKUP_DIR="/var/lib/vz/dump/$CONTAINER_ID"
mkdir -p $BACKUP_DIR && rm -f $BACKUP_DIR/*
echo "Backing up container $CONTAINER_ID to $BACKUP_DIR..."
vzdump $CONTAINER_ID --dumpdir $BACKUP_DIR

if [ $? -ne 0 ]; then
    echo "Failed to backup the container $CONTAINER_ID."
    exit 1
fi

# Destroy the container
echo "Destroying container $CONTAINER_ID..."
pct destroy $CONTAINER_ID
if [ $? -ne 0 ]; then
    echo "Failed to destroy the container $CONTAINER_ID."
    exit 1
fi

# Restore the container as privileged
echo "Restoring container $CONTAINER_ID as privileged..."
BACKUP_FILE=$( ls /var/lib/vz/dump/$CONTAINER_ID/*.tar)
pct restore $CONTAINER_ID $BACKUP_FILE --storage $STORAGE_POOL --unprivileged 0
if [ $? -ne 0 ]; then
    echo "Failed to restore the container $CONTAINER_ID as privileged."
    exit 1
else
  echo "Container $CONTAINER_ID has been successfully recreated as a privileged container."
  exit 0
fi
