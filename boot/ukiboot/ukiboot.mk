################################################################################
#
# ukiboot
#
################################################################################

EFIBOOTGUARD_VERSION = 0.22
EFIBOOTGUARD_SITE = $(call github,siemens,efibootguard,refs/tags/v$(EFIBOOTGUARD_VERSION))
EFIBOOTGUARD_LICENSE = GPL-2.0-only
EFIBOOTGUARD_LICENSE_FILES = COPYING
EFIBOOTGUARD_CPE_ID_VENDOR = siemens

EFIBOOTGUARD_DEPENDENCIES = \
	gnu-efi \
	pciutils \
	host-autoconf-archive \
	host-pkgconf

EFIBOOTGUARD_AUTORECONF = YES

EFIBOOTGUARD_AUTORECONF_OPTS = --include=$(HOST_DIR)/share/autoconf-archive

EFIBOOTGUARD_CONF_OPTS = \
	--with-gnuefi-sys-dir=$(STAGING_DIR) \
	--with-gnuefi-include-dir=$(STAGING_DIR)/usr/include/efi \
	--with-gnuefi-lib-dir=$(STAGING_DIR)/usr/lib \
	--disable-completion \
	--disable-tests

EFIBOOTGUARD_CONF_ENV = \
	LDFLAGS="$(LDFLAGS) -no-pie"

ifeq ($(BR2_TARGET_EFIBOOTGUARD_INSTALL_TOOLS),y)
EFIBOOTGUARD_INSTALL_TARGET = YES

# bg_gen_unified_kernel is mainly useful when assembling a UKI/image - do not
# install it into the runtime target filesystem.
define EFIBOOTGUARD_REMOVE_BG_GEN_UNIFIED_KERNEL
	rm -rf $(TARGET_DIR)/usr/bin/bg_gen_unified_kernel
endef
EFIBOOTGUARD_POST_INSTALL_TARGET_HOOKS += EFIBOOTGUARD_REMOVE_BG_GEN_UNIFIED_KERNEL
else
EFIBOOTGUARD_INSTALL_TARGET = NO
endif

EFIBOOTGUARD_INSTALL_IMAGES = YES
define EFIBOOTGUARD_INSTALL_IMAGES_CMDS
	$(INSTALL) -m 0644 $(@D)/efibootguard*.efi $(BINARIES_DIR)
	$(INSTALL) -m 0644 $(@D)/kernel-stub*.efi $(BINARIES_DIR)
endef

HOST_EFIBOOTGUARD_DEPENDENCIES = \
	host-autoconf-archive \
	host-pkgconf \
	host-python3

HOST_EFIBOOTGUARD_AUTORECONF = YES

HOST_EFIBOOTGUARD_AUTORECONF_OPTS = --include=$(HOST_DIR)/share/autoconf-archive

HOST_EFIBOOTGUARD_CONF_OPTS = \
	--disable-bootloader \
	--disable-completion \
	--disable-tests

$(eval $(autotools-package))
$(eval $(host-autotools-package))
