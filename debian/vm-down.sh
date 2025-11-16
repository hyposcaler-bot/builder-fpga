#!/bin/bash

set -e

# Configuration
VM_NAME="debian-12-bios-x86_64"

# Check for required commands
if ! command -v virsh &>/dev/null; then
    echo "Error: virsh command not found. Please install libvirt-clients."
    exit 1
fi

# Check if VM exists
if ! virsh dominfo "$VM_NAME" &>/dev/null; then
    echo "VM '$VM_NAME' does not exist. Nothing to do."
    exit 0
fi

echo "Removing VM '$VM_NAME'..."

# Check if VM is running
if virsh domstate "$VM_NAME" | grep -q "running"; then
    echo "Attempting graceful shutdown..."
    virsh shutdown "$VM_NAME"
    
    # Wait for up to 30 seconds for VM to shutdown
    MAX_WAIT=30
    ELAPSED=0
    while [ $ELAPSED -lt $MAX_WAIT ]; do
        sleep 2
        ELAPSED=$((ELAPSED + 2))
        if ! virsh domstate "$VM_NAME" 2>/dev/null | grep -q "running"; then
            echo "VM shutdown successfully."
            break
        fi
        echo "Waiting for shutdown... ($ELAPSED/$MAX_WAIT seconds)"
    done

    # Force destroy if still running
    if virsh domstate "$VM_NAME" 2>/dev/null | grep -q "running"; then
        echo "Graceful shutdown timed out. Forcing VM destruction..."
        virsh destroy "$VM_NAME"
    fi
else
    echo "VM is not running."
fi

# Undefine the domain and remove storage
echo "Removing VM definition and storage..."
# Use --nvram only if VM has UEFI firmware, otherwise it will fail
if virsh dumpxml "$VM_NAME" 2>/dev/null | grep -q "<loader"; then
    echo "Removing VM with UEFI firmware..."
    virsh undefine "$VM_NAME" --nvram --remove-all-storage
else
    echo "Removing VM with BIOS firmware..."
    virsh undefine "$VM_NAME" --remove-all-storage
fi

echo "VM '$VM_NAME' has been completely removed."
