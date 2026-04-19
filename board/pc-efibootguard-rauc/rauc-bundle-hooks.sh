#!/bin/sh
set -eu

fail() { echo 1>&2 "Error:" "$@"; exit 10; }

case $1 in
  slot-post-install)
    RAUC_BUNDLE_DIR="$RAUC_MOUNT_PREFIX/bundle"
    echo "slot-post-install for $RAUC_SLOT_CLASS ($RAUC_SLOT_NAME)"

    # Copy kernel
    if [ "$RAUC_SLOT_CLASS" = "system" ] ; then
      ls -lah "$RAUC_BUNDLE_DIR"

      mkdir -p /run/boot

      # Mount the right kernel slot
      if [ "$RAUC_SLOT_NAME" = "system.a" ]; then
        mount /dev/disk/by-partlabel/boot-a /run/boot
      elif [ "$RAUC_SLOT_NAME" = "system.b" ]; then
        mount /dev/disk/by-partlabel/boot-b /run/boot
      else
        fail "Can't determine rootfs slot name for $RAUC_SLOT_NAME"
      fi

      # Copy kernel into kernel slot
      cp "$RAUC_BUNDLE_DIR"/bzImage /run/boot

      # unmount
      umount /run/boot
    fi
    ;;

  *)
    fail "unsupported hook: $1"
    ;;
esac
