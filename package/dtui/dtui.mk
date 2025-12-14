################################################################################
#
# dtui
#
################################################################################

DTUI_VERSION = 3.0.1
DTUI_SITE = $(call github,Troels51,dtui,v$(DTUI_VERSION))

DTUI_LICENSE = MIT
DTUI_LICENSE_FILES = LICENSE

DTUI_CARGO_BIN = dtui

$(eval $(cargo-package))
