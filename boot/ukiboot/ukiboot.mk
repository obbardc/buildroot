################################################################################
#
# ukiboot
#
################################################################################

UKIBOOT_VERSION = 0.22
UKIBOOT_SITE = $(call github,siemens,ukiboot,refs/tags/v$(UKIBOOT_VERSION))
UKIBOOT_LICENSE = GPL-2.0-only
UKIBOOT_LICENSE_FILES = COPYING
UKIBOOT_CPE_ID_VENDOR = siemens

UKIBOOT_DEPENDENCIES = \
	gnu-efi \
	pciutils \
	host-autoconf-archive \
	host-pkgconf

UKIBOOT_AUTORECONF = YES

UKIBOOT_AUTORECONF_OPTS = --include=$(HOST_DIR)/share/autoconf-archive

UKIBOOT_CONF_OPTS = \
	--with-gnuefi-sys-dir=$(STAGING_DIR) \
	--with-gnuefi-include-dir=$(STAGING_DIR)/usr/include/efi \
	--with-gnuefi-lib-dir=$(STAGING_DIR)/usr/lib \
	--disable-completion \
	--disable-tests

UKIBOOT_CONF_ENV = \
	LDFLAGS="$(LDFLAGS) -no-pie"

ifeq ($(BR2_TARGET_UKIBOOT_INSTALL_TOOLS),y)
UKIBOOT_INSTALL_TARGET = YES

# bg_gen_unified_kernel is mainly useful when assembling a UKI/image - do not
# install it into the runtime target filesystem.
define UKIBOOT_REMOVE_BG_GEN_UNIFIED_KERNEL
	rm -rf $(TARGET_DIR)/usr/bin/bg_gen_unified_kernel
endef
UKIBOOT_POST_INSTALL_TARGET_HOOKS += UKIBOOT_REMOVE_BG_GEN_UNIFIED_KERNEL
else
UKIBOOT_INSTALL_TARGET = NO
endif

UKIBOOT_INSTALL_IMAGES = YES
define UKIBOOT_INSTALL_IMAGES_CMDS
	$(INSTALL) -m 0644 $(@D)/UKIBOOT*.efi $(BINARIES_DIR)
	$(INSTALL) -m 0644 $(@D)/kernel-stub*.efi $(BINARIES_DIR)
endef

HOST_UKIBOOT_DEPENDENCIES = \
	host-autoconf-archive \
	host-pkgconf \
	host-python3

HOST_UKIBOOT_AUTORECONF = YES

HOST_UKIBOOT_AUTORECONF_OPTS = --include=$(HOST_DIR)/share/autoconf-archive

HOST_UKIBOOT_CONF_OPTS = \
	--disable-bootloader \
	--disable-completion \
	--disable-tests

$(eval $(autotools-package))
$(eval $(host-autotools-package))
