################################################################################
#
# efibootguard
#
################################################################################

EFIBOOTGUARD_VERSION = 0.22
EFIBOOTGUARD_SITE = $(call github,siemens,efibootguard,refs/tags/v$(EFIBOOTGUARD_VERSION))
EFIBOOTGUARD_LICENSE = GPL-2.0-only
EFIBOOTGUARD_LICENSE_FILES = COPYING

EFIBOOTGUARD_DEPENDENCIES = \
	gnu-efi \
	host-autoconf-archive

ifeq ($(BR2_TARGET_EFIBOOTGUARD_INSTALL_TOOLS),y)
EFIBOOTGUARD_DEPENDENCIES += pciutils
EFIBOOTGUARD_INSTALL_TARGET = YES
else
EFIBOOTGUARD_INSTALL_TARGET = NO
endif

EFIBOOTGUARD_INSTALL_IMAGES = YES

EFIBOOTGUARD_AUTORECONF = YES

EFIBOOTGUARD_AUTORECONF_OPTS = \
	-I $(HOST_DIR)/share/autoconf-archive

EFIBOOTGUARD_CONF_OPTS = \
	--with-gnuefi-sys-dir=$(STAGING_DIR) \
	--with-gnuefi-include-dir=$(STAGING_DIR)/usr/include/efi \
	--with-gnuefi-lib-dir=$(STAGING_DIR)/usr/lib \
	--disable-completion \
	--disable-tests

# TODO: Perhaps take inspiration from Debian patch https://salsa.debian.org/debian/efibootguard/-/blob/master/debian/patches/always-override-stack-protector-variables-in-EFI-bui.patch?ref_type=heads
EFIBOOTGUARD_CONF_ENV = \
	LDFLAGS="$(LDFLAGS) -no-pie"

define EFIBOOTGUARD_INSTALL_IMAGES_CMDS
	$(INSTALL) -d $(BINARIES_DIR)/efibootguard
	$(INSTALL) -m 0644 $(@D)/efibootguardx64.efi $(BINARIES_DIR)/efibootguard/
endef

HOST_EFIBOOTGUARD_DEPENDENCIES = \
	host-autoconf-archive

HOST_EFIBOOTGUARD_AUTORECONF = YES

HOST_EFIBOOTGUARD_AUTORECONF_OPTS = \
	-I $(HOST_DIR)/share/autoconf-archive

HOST_EFIBOOTGUARD_CONF_OPTS = \
	--disable-bootloader \
	--disable-completion \
	--disable-tests

$(eval $(autotools-package))
$(eval $(host-autotools-package))
