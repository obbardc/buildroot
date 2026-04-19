#!/bin/sh

qemu-system-x86_64 \
  -M pc \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd \
  -drive file=output/images/disk.img,if=virtio,format=raw \
  -boot menu=on \
  -net nic,model=virtio \
  -net user
