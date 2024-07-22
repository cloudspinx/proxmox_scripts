#!/bin/bash

# List all containers with their IDs and names
echo "Available containers:"
pct list

# Prompt user to enter a container ID
read -p "Enter the container ID you want to modify: " CONTAINER_ID

# Validate that the container ID is valid
if ! pct status $CONTAINER_ID &>/dev/null; then
    echo "Container ID $CONTAINER_ID is not valid."
    exit 1
fi

# Stop the container
echo "Stopping container $CONTAINER_ID..."
pct stop $CONTAINER_ID

# Path to the container's configuration file
CONFIG_FILE="/etc/pve/lxc/$CONTAINER_ID.conf"

# Check if the configuration lines already exist
if ! grep -q "lxc.cgroup2.devices.allow: c 10:200 rwm" "$CONFIG_FILE"; then
    echo "Adding lxc.cgroup2.devices.allow configuration..."
    echo "lxc.cgroup2.devices.allow: c 10:200 rwm" >> "$CONFIG_FILE"
fi

if ! grep -q "lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file" "$CONFIG_FILE"; then
    echo "Adding lxc.mount.entry configuration..."
    echo "lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file" >> "$CONFIG_FILE"
fi

# Start the container
echo "Starting container $CONTAINER_ID..."
pct start $CONTAINER_ID

# Verify the TUN device inside the container
echo "Verifying /dev/net/tun inside the container..."
pct exec $CONTAINER_ID -- sh -c "ls -lh /dev/net/tun"
echo "Done."
