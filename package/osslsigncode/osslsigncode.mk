################################################################################
#
# osslsigncode
#
################################################################################

OSSLSIGNCODE_VERSION = 2.13
OSSLSIGNCODE_SITE = $(call github,mtrojnar,osslsigncode,$(OSSLSIGNCODE_VERSION))
OSSLSIGNCODE_LICENSE = GPL-3.0+ with OpenSSL exception
OSSLSIGNCODE_LICENSE_FILES = COPYING.txt

# osslsigncode is generally used at image assembly time to Authenticode-sign
# PE/EFI binaries (e.g. for UEFI Secure Boot) so only a host build is provided.
HOST_OSSLSIGNCODE_DEPENDENCIES = host-openssl host-zlib

# Upstream installs the bash completion file to an absolute destination; instead
# point it inside $(HOST_DIR).
HOST_OSSLSIGNCODE_CONF_OPTS = \
	-DBASH_COMPLETION_USER_DIR=$(HOST_DIR)/share/bash-completion/completions

$(eval $(host-cmake-package))
