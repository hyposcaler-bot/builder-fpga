#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

echo "=== Starting FPGA Toolchain Installation for Alhambra II ==="

# Update package lists
echo "Updating package lists..."
apt-get update

# Install basic development tools
echo "Installing basic development tools..."
apt-get install -y \
    git \
    make \
    build-essential \
    pkg-config \
    curl \
    wget \
    jq


# Install Python 3 (usually pre-installed in Debian 12, but ensuring it's there)
echo "Installing Python 3..."
apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    pipx

# Install Go
echo "Installing Golang..."
apt-get install -y golang

# Install dependencies for the FPGA toolchain
echo "Installing FPGA toolchain dependencies..."
apt-get install -y \
    libftdi-dev \
    libusb-1.0-0-dev \
    libboost-all-dev \
    cmake \
    libreadline-dev \
    tcl-dev \
    libffi-dev \
    mercurial \
    graphviz \
    xdot \
    clang \
    bison \
    flex \
    gawk \
    libboost-system-dev \
    libboost-python-dev \
    libboost-filesystem-dev \
    zlib1g-dev \
    libeigen3-dev

# Install usbutils
echo "installing usbutils"   
apt-get install -y usbutils
# Install Yosys
echo "Installing Yosys..."
apt-get install -y yosys

# Install IceStorm tools
echo "Installing IceStorm tools..."
apt-get install -y fpga-icestorm

# Install nextpnr-ice40
echo "Installing nextpnr-ice40..."
apt-get install -y nextpnr-ice40

# Install gtkwave
echo "Installing gtkwave"
apt-get install gtkwave

# Install iverilog
echo "Installing iverilog"
apt-get install iverilog

# Install verilator
echo "Installing verilator"
apt-get install verilator

# Create udev rules for FTDI devices (needed for iceprog)
echo "Setting up udev rules for FTDI devices..."
cat > /etc/udev/rules.d/53-lattice-ftdi.rules << 'EOF'
# Alhambra II and other FT2232H based boards
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", MODE="0660", GROUP="plugdev", TAG+="uaccess"
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6014", MODE="0660", GROUP="plugdev", TAG+="uaccess"
EOF

# Reload udev rules
udevadm control --reload-rules
udevadm trigger

# Clean up apt cache to reduce image size
apt-get clean
rm -rf /var/lib/apt/lists/*


# # TODO add these 
# git clone https://github.com/FPGAwars/Alhambra-II-FPGA
# pipx install apio
# #If you want better test automation
# pip install cocotb
# # For UART communication from Go
# go get go.bug.st/serial
# cat >> ~/.bashrc << 'EOF'
# # FPGA aliases
# alias wave='gtkwave'
# alias sim='iverilog -o sim.vvp'
# alias run='vvp sim.vvp'
# EOF