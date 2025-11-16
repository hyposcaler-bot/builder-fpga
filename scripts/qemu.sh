#!/bin/sh -eu
export DEBIAN_FRONTEND=noninteractive

echo "==> Install qemu guest agent"
apt-get install -y qemu-guest-agent
