#!/bin/sh
set -eu

BOARD_DIR="$(dirname "$0")"

# WARNING: the kernel command line cannot currently be changed during an upgrade.
# If required it can be updated from the RAUC bundle hook using `bg_setenv --args`.
KERNEL_CMDLINE="noinitrd rootwait rw"

# Copy efibootguard into EFI partition.
mkdir -p "${BINARIES_DIR}"/efi-part/EFI/BOOT
cp "${BINARIES_DIR}"/efibootguard/efibootguardx64.efi "${BINARIES_DIR}"/efi-part/EFI/BOOT/BOOTX64.efi

# Create efibootguard boot-a slot configuration.
# Since this has a higher revision than boot-b, it is the primary boot slot.
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

# Create efibootguard boot-b configuration.
# efibootguard won't boot from a slot marked as FAILED.
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

# Generate the filesystem & disk image.
support/scripts/genimage.sh -c "${BOARD_DIR}"/genimage.cfg

# Bundle metadata.
BUNDLE_COMPATIBLE="Buildroot EFI Boot Guard RAUC Demo"
BUNDLE_VERSION=$BR2_VERSION_FULL

echo "Building RAUC bundle with:"
echo " - Compatible: $BUNDLE_COMPATIBLE"
echo " - Version: $BUNDLE_VERSION"

# Create RAUC bundle directory.
RAUC_BUNDLE_TMPDIR=${BINARIES_DIR}/rauc-bundle
mkdir -p "${RAUC_BUNDLE_TMPDIR}"/.rauc-workdir

# Create RAUC bundle manifest.
cat <<EOF > "${RAUC_BUNDLE_TMPDIR}"/manifest.raucm
[update]
compatible=$BUNDLE_COMPATIBLE
version=$BUNDLE_VERSION

[bundle]
format=verity

[image.system]
filename=rootfs.ext4.img
hooks=post-install

[hooks]
filename=bundle-hooks.sh
EOF

# Copy images into $RAUC_BUNDLE_TMPDIR.
# RAUC determines how to copy the image at runtime based on the file extension:
# in this case it's a raw ext4 image.
cp "${BINARIES_DIR}"/rootfs.ext2 "$RAUC_BUNDLE_TMPDIR"/rootfs.ext4.img

# Copy kernel into RAUC bundle.
cp "${BINARIES_DIR}"/bzImage "$RAUC_BUNDLE_TMPDIR"/bzImage

# Copy bundle-hooks.sh into RAUC bundle.
cp "${BOARD_DIR}"/rauc-bundle-hooks.sh "$RAUC_BUNDLE_TMPDIR"/bundle-hooks.sh

# Remove any existing bundle.
rm -f "${BINARIES_DIR}"/upgrade_"${BUNDLE_VERSION}".rauc

# Generate bundle.
"${HOST_DIR}"/bin/rauc bundle \
  --cert="${BOARD_DIR}"/keyring/rauc-bundle.cert.pem \
  --key="${BOARD_DIR}"/keyring/rauc-bundle.key.pem \
  "${RAUC_BUNDLE_TMPDIR}" \
  "${BINARIES_DIR}"/upgrade_"${BUNDLE_VERSION}".rauc

# Remove bundle temporary directory.
rm -r "$RAUC_BUNDLE_TMPDIR"
