# From your build host
```
scp debian-12-bios-x86_64.qcow2 root@$PROXMOXHOST:/tmp/
```

## 1. Create VM with agent enabled
```
qm create 9000 \
  --name alhambra-debian12-template \
  --memory 16384 \
  --cores 4 \
  --cpu host \
  --net0 virtio,bridge=vmbr0 \
  --scsihw virtio-scsi-pci \
  --ostype l26 \
  --bios seabios \
  --machine pc \
  --vga std \
  --agent enabled=1,fstrim_cloned_disks=1
```
## 2. Import disk
```
qm importdisk 9000 /tmp/debian-12-bios-x86_64.qcow2 local-lvm
rm /tmp/debian-12-bios-x86_64.qcow2
```
## 3. Attach disk
```
qm set 9000 --scsi0 local-lvm:vm-9000-disk-0
```
## 4. Set boot order
```
qm set 9000 --boot order=scsi0
```
## 5. Add cloud-init
```
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --ciuser eda
qm set 9000 --ipconfig0 ip=dhcp
```
## 6. Add USB passthrough
```
qm set 9000 --usb0 host=3-5
```
## 7. Convert to template
```
qm template 9000
```