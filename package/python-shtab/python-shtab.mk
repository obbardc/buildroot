################################################################################
#
# python-shtab
#
################################################################################

PYTHON_SHTAB_VERSION = 1.7.1
PYTHON_SHTAB_SOURCE = shtab-$(PYTHON_SHTAB_VERSION).tar.gz
PYTHON_SHTAB_SITE = https://files.pythonhosted.org/packages/a9/e4/13bf30c7c30ab86a7bc4104b1c943ff2f56c1a07c6d82a71ad034bcef1dc
PYTHON_SHTAB_SETUP_TYPE = pep517
PYTHON_SHTAB_LICENSE = Apache-2.0
PYTHON_SHTAB_LICENSE_FILES = LICENCE

HOST_PYTHON_SHTAB_DEPENDENCIES = host-python-setuptools-scm

$(eval $(host-python-package))
