#!/bin/sh

set -e

# Kernel cmdline to append
KERNEL_CMDLINE=""

# Create efibootguard boot-a slot configuration
mkdir -p "${BINARIES_DIR}"/boot-a-part
printf "boot-a" | iconv -f ascii -t UTF-16LE > "${BINARIES_DIR}"/boot-a-part/EFILABEL
"${HOST_DIR}"/bin/bg_setenv \
    --verbose \
    --watchdog=0 \
    --filepath="${BINARIES_DIR}"/boot-a-part/BGENV.DAT \
    --revision=2 \
    --ustate=OK \
    --kernel="C:boot-a:bzImage" \
    --args="root=PARTLABEL=system-a $KERNEL_CMDLINE"

# Create efibootguard boot-a slot configuration (unbootable)
mkdir -p "${BINARIES_DIR}"/boot-b-part
printf "boot-b" | iconv -f ascii -t UTF-16LE > "${BINARIES_DIR}"/boot-b-part/EFILABEL
"${HOST_DIR}"/bin/bg_setenv \
    --verbose \
    --watchdog=0 \
    --filepath="${BINARIES_DIR}"/boot-b-part/BGENV.DAT \
    --revision=1 \
    --ustate=FAILED \
    --kernel="C:boot-b:bzImage" \
    --args="root=PARTLABEL=system-b $KERNEL_CMDLINE"

# Copy kernel into boot-a.
cp "${BINARIES_DIR}"/bzImage "${BINARIES_DIR}"/boot-a-part/
