#!/bin/bash

set -e

# Configuration
VM_NAME="debian-12-bios-x86_64"
VM_IMAGE_PATH="/var/lib/libvirt/images/${VM_NAME}.qcow2"
SOURCE_IMAGE="../build/output-${VM_NAME}/${VM_NAME}.qcow2"

# Check for required commands
for cmd in virsh virt-install qemu-img jq; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: Required command '$cmd' not found. Please install it first."
        exit 1
    fi
done

# Check if source image exists
if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "Error: Source image not found at $SOURCE_IMAGE"
    echo "Please run 'make build' first to create the VM image."
    exit 1
fi

# Check if VM already exists
if virsh dominfo "$VM_NAME" &>/dev/null; then
    echo "VM '$VM_NAME' already exists. Exiting."
    
    # Show IP address even if VM exists
    virsh qemu-agent-command "$VM_NAME" '{"execute":"guest-network-get-interfaces"}' | jq -r '.return[] | select(.name != "lo") | .name as $name | .["hardware-address"] as $mac | .["ip-addresses"][] | select(.["ip-address-type"] == "ipv4") | "\($name) (\($mac)): \(.["ip-address"])/\(.prefix)"'
    
    exit 0
fi

echo "Creating VM '$VM_NAME'..."

sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    "$SOURCE_IMAGE" \
    "$VM_IMAGE_PATH"

# Check if br0 network bridge exists
if ! ip link show br0 &>/dev/null; then
    echo "Warning: Network bridge 'br0' not found. Using default network."
    NETWORK_ARG="--network default,model=virtio"
else
    NETWORK_ARG="--network bridge=br0,model=virtio"
fi

virt-install \
  --connect qemu:///system \
  --name "$VM_NAME" \
  --memory 16384 \
  --vcpus 12 \
  --os-variant debian12 \
  --disk "$VM_IMAGE_PATH",bus=virtio \
  $NETWORK_ARG \
  --graphics spice \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

echo "VM created. Waiting for it to become ready..."

# Wait for VM to be running and guest agent to be responsive
MAX_WAIT=60  # Maximum seconds to wait
for ((i=1; i<=MAX_WAIT; i++)); do
    # Check if VM is running
    if ! virsh domstate "$VM_NAME" | grep -q "running"; then
        echo "Waiting for VM to start... ($i/$MAX_WAIT seconds)"
        sleep 1
        continue
    fi
    
    # Check if guest agent is responsive
    if virsh qemu-agent-command "$VM_NAME" '{"execute":"guest-ping"}' &>/dev/null; then
        echo "VM is up and guest agent is responsive!"
        break
    fi
    
    echo "Waiting for guest agent... ($i/$MAX_WAIT seconds)"
    sleep 1
    
    # If we've reached the timeout
    if [ $i -eq $MAX_WAIT ]; then
        echo "Warning: Timed out waiting for guest agent. Network information may not be available."
    fi
done

echo "Fetching network information..."
virsh qemu-agent-command "$VM_NAME" '{"execute":"guest-network-get-interfaces"}' | jq -r '.return[] | select(.name != "lo") | .name as $name | .["hardware-address"] as $mac | .["ip-addresses"][] | select(.["ip-address-type"] == "ipv4") | "\($name) (\($mac)): \(.["ip-address"])/\(.prefix)"'
