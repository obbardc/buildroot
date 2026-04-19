#!/bin/sh
set -eu

BOARD_DIR="$(dirname "$0")"

# Copy RAUC certificate into target dir.
cp "$BOARD_DIR"/keyring/rauc-bundle.cert.pem "$TARGET_DIR"/etc/rauc/rauc-bundle.cert.pem
