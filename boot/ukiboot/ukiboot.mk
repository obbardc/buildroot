################################################################################
#
# ukiboot
#
################################################################################

UKIBOOT_VERSION = 0.2.1
UKIBOOT_SITE = \
	https://gitlab.com/CentOS/automotive/src/ukiboot/-/archive/$(UKIBOOT_VERSION)
UKIBOOT_SOURCE = ukiboot-$(UKIBOOT_VERSION).tar.bz2

UKIBOOT_LICENSE = LGPL-2.1
UKIBOOT_LICENSE_FILES = COPYING.LIB

UKIBOOT_DEPENDENCIES = \
	gnu-efi \
	host-systemd

UKIBOOT_CONF_OPTS = \
	-Defi-includedir=$(STAGING_DIR)/usr/include/efi \
	-Defi-libdir=$(STAGING_DIR)/usr/lib \
	-Defi-ldsdir=$(STAGING_DIR)/usr/lib

#ifeq ($(BR2_TARGET_UKIBOOT_INSTALL_TOOLS),y)
#UKIBOOT_INSTALL_TARGET = YES

# bg_gen_unified_kernel is mainly useful when assembling a UKI/image - do not
# install it into the runtime target filesystem.
#define UKIBOOT_REMOVE_BG_GEN_UNIFIED_KERNEL
#	rm -rf $(TARGET_DIR)/usr/bin/bg_gen_unified_kernel
#endef
#UKIBOOT_POST_INSTALL_TARGET_HOOKS += UKIBOOT_REMOVE_BG_GEN_UNIFIED_KERNEL
#else
#UKIBOOT_INSTALL_TARGET = NO
#endif

UKIBOOT_INSTALL_IMAGES = YES
#define UKIBOOT_INSTALL_IMAGES_CMDS
#	$(INSTALL) -m 0644 $(@D)/UKIBOOT*.efi $(BINARIES_DIR)
#	$(INSTALL) -m 0644 $(@D)/kernel-stub*.efi $(BINARIES_DIR)
#endef

#HOST_UKIBOOT_DEPENDENCIES = \
#	host-autoconf-archive \
#	host-pkgconf \
#	host-python3

#HOST_UKIBOOT_AUTORECONF = YES

#HOST_UKIBOOT_AUTORECONF_OPTS = --include=$(HOST_DIR)/share/autoconf-archive

#HOST_UKIBOOT_CONF_OPTS = \
#	--disable-bootloader \
#	--disable-completion \
#	--disable-tests

$(eval $(meson-package))
$(eval $(host-meson-package))
