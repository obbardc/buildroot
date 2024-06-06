################################################################################
#
# efibootguard
#
################################################################################

# There are:
# - host tools & library
# - target tools
# - target library (should these be separate ?)

EFIBOOTGUARD_VERSION = 0.19
EFIBOOTGUARD_SITE = $(call github,siemens,efibootguard,refs/tags/v$(EFIBOOTGUARD_VERSION))
EFIBOOTGUARD_LICENSE = GPL-2.0+
EFIBOOTGUARD_LICENSE_FILES = COPYING

EFIBOOTGUARD_DEPENDENCIES = \
	check \
	gnu-efi \
	pciutils \
	host-autoconf-archive \
	host-python-shtab

# TODO Test BR2_TARGET_EFIBOOTGUARD_INSTALL_TOOLS=n
ifeq ($(BR2_TARGET_EFIBOOTGUARD_INSTALL_TOOLS),y)
EFIBOOTGUARD_INSTALL_TARGET = YES
else
EFIBOOTGUARD_INSTALL_TARGET = NO
endif

EFIBOOTGUARD_IMAGE_DIR = $(BINARIES_DIR)/efibootguard/

EFIBOOTGUARD_INSTALL_IMAGES = YES

EFIBOOTGUARD_AUTORECONF = YES

EFIBOOTGUARD_AUTORECONF_OPTS = \
	-I $(HOST_DIR)/share/autoconf-archive

EFIBOOTGUARD_CONF_OPTS = \
	--with-gnuefi-sys-dir=$(STAGING_DIR) \
	--with-gnuefi-include-dir=$(STAGING_DIR)/usr/include/efi \
	--with-gnuefi-lib-dir=$(STAGING_DIR)/usr/lib

# TODO: Instead we should try https://salsa.debian.org/debian/efibootguard/-/blob/master/debian/patches/always-override-stack-protector-variables-in-EFI-bui.patch?ref_type=heads
EFIBOOTGUARD_CONF_ENV = \
	LDFLAGS="$(LDFLAGS) -no-pie"

define EFIBOOTGUARD_INSTALL_IMAGES_CMDS
	mkdir -p $(EFIBOOTGUARD_IMAGE_DIR)
	cp $(@D)/*.efi $(EFIBOOTGUARD_IMAGE_DIR)
endef

HOST_EFIBOOTGUARD_DEPENDENCIES = \
	host-autoconf-archive \
	host-check

HOST_EFIBOOTGUARD_AUTORECONF = YES

HOST_EFIBOOTGUARD_AUTORECONF_OPTS = \
	-I $(HOST_DIR)/share/autoconf-archive

HOST_EFIBOOTGUARD_CONF_OPTS = \
	--disable-bootloader

$(eval $(autotools-package))
$(eval $(host-autotools-package))
