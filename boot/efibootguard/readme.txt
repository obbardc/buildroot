TODO



Create Unified Kernel image:
```
# Create Unified Kernel Image for boot-a.
${HOST_DIR}/bin/python3 ${HOST_DIR}/bin/bg_gen_unified_kernel \
    --cmdline "root=PARTLABEL=system-a $KERNEL_CMDLINE" \
    ${BINARIES_DIR}/efibootguard/kernel-stubx64.efi \
    ${BINARIES_DIR}/bzImage \
    ${BINARIES_DIR}/boot-a-part/linux.efi
```
