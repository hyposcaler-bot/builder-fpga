packer {
  required_plugins {
    qemu = {
      version = "~> 1"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variable "efi_boot" {
  type    = bool
  default = false
}

variable "efi_firmware_code" {
  type    = string
  default = null
}

variable "efi_firmware_vars" {
  type    = string
  default = null
}

variable "cpus" {
  type        = number
  default     = 8
}

variable "memory" {
  type        = number
  default     = 16384
}

variable "headless" {
  type    = bool
  default = true
}

variable "ssh_username" {
  type    = string
  default = "eda"
}

variable "ssh_password" {
  type    = string
  default = "eda"
}

variable "vm_name" {
  type    = string
  default = "debian-12-x86_64"
}

# use cloud_init to create docker group and add eda user
source "file" "user_data" {
  content = <<EOF
#cloud-config
user: ${var.ssh_username}
password: ${var.ssh_password}
chpasswd: { expire: False }
ssh_pwauth: True
system_info:
  default_user:
    name: ${var.ssh_username}
    groups: [adm,dialout,plugdev,cdrom,sudo,dip,lxd]
EOF
  target  = "${path.cwd}/build/boot-${var.vm_name}/user-data"
}

source "file" "meta_data" {
  content = <<EOF
instance-id: fpga-dev
local-hostname: fpga-dev
EOF
  target  = "${path.cwd}/build/boot-${var.vm_name}/meta-data"
}

build {
  sources = ["sources.file.user_data", "sources.file.meta_data"]

  provisioner "shell-local" {
    inline = ["genisoimage -output ${path.cwd}/build/boot-${var.vm_name}/cidata.iso -input-charset utf-8 -volid cidata -joliet -r  ${path.cwd}/build/boot-${var.vm_name}/user-data  ${path.cwd}/build/boot-${var.vm_name}/meta-data"]
  }
}

variable "iso_checksum" {
  type    = string
  default = "file:https://cloud.debian.org/images/cloud/bookworm/latest/SHA512SUMS"
}

variable "iso_url" {
  type    = string
  default = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
}

source "qemu" "debian" {
  accelerator      = "kvm"
  cpus             = var.cpus
  memory           = var.memory
  disk_compression = true
  disk_image       = true
  disk_size        = "25G" 
  headless         = var.headless
  iso_checksum     = var.iso_checksum
  iso_url          = var.iso_url
  qemuargs = [
    ["-cdrom", "${path.cwd}/build/boot-${var.vm_name}/cidata.iso"], 
    ["-cpu", "host,+ssse3"]
  ]
  output_directory  = "${path.cwd}/build/output-${var.vm_name}"
  shutdown_command  = "echo '${var.ssh_password}' | sudo -S shutdown -P now"
  ssh_password      = var.ssh_password
  ssh_timeout       = "120s"
  ssh_username      = var.ssh_username
  vm_name           = "${var.vm_name}.qcow2"
  efi_boot          = var.efi_boot
  efi_firmware_code = var.efi_firmware_code
  efi_firmware_vars = var.efi_firmware_vars
}

build {
  sources = ["source.qemu.debian"]

  # cloud-init may still be running when we start executing scripts
  # To avoid race conditions, make sure cloud-init is done first
  provisioner "shell" {
    execute_command = "echo '${var.ssh_password}' | {{ .Vars }} sudo -S -E sh -eux '{{ .Path }}'"
    scripts = [
      "${path.root}/../scripts/cloud-init-wait.sh",
      "${path.root}/../scripts/reconfigure-cloud-init.sh"
    ]
  }

  # Update package lists before installing packages
  provisioner "shell" {
    execute_command = "echo '${var.ssh_password}' | {{ .Vars }} sudo -S -E sh -eux '{{ .Path }}'"
    inline = [
      "apt-get update"
    ]
  }

  provisioner "shell" {
    execute_command = "echo '${var.ssh_password}' | {{ .Vars }} sudo -S -E sh -eux '{{ .Path }}'"
    scripts = [
      "${path.root}/../scripts/qemu.sh"
    ]
  }

  provisioner "shell" {
    execute_command   = "echo '${var.ssh_password}' | {{ .Vars }} sudo -S -E sh -eux '{{ .Path }}'"
    expect_disconnect = true
    scripts = [
      "${path.root}/../scripts/fpga-toolchain-provisioner.sh"
    ]
  }

  provisioner "shell" {
    execute_command   = "echo '${var.ssh_password}' | {{ .Vars }} sudo -S -E sh -eux '{{ .Path }}'"
    expect_disconnect = true
    scripts = [
      "${path.root}/../scripts/clear-machine-information.sh"
    ]
  }

}
