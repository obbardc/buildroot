# EFI Boot Guard RAUC Integration Example Recipe

This recipe creates a basic x86 disk image using [EFI Boot Guard](https://github.com/siemens/efibootguard/tree/master)
as the bootloader and [RAUC](https://rauc.io/) as the update tool.

The image is intended to demonstrate a typical A/B update layout. It contains two
root filesystem slots managed by EFI Boot Guard. The first slot is populated with
the root filesystem generated as part of the Buildroot build, while the second
slot is left available for testing updates using RAUC.

A RAUC bundle is also generated as part of the Buildroot build. This bundle can
be installed into the inactive slot to exercise the update flow and verify the
interaction between RAUC and EFI Boot Guard.

The recipe also creates the EFI system partition and installs the EFI Boot Guard
bootloader components needed to select and boot one of the available slots. Each
slot has its own EFI Boot Guard environment, containing the kernel image and
configuration.

This example is deliberately minimal. It is intended as a reference for users who
want to integrate EFI Boot Guard and RAUC into their own platform-specific
images, rather than as a complete production-ready update setup.

This recipe was designed to be run in QEMU and may need additional changes to run
on real hardware.


## Keyring

RAUC bundles must be signed. The example recipe expects a key and certificate to
be available under `board/pc-efibootguard-rauc/keyring/`.

Generate a demo keyring from the Buildroot root directory with:

```
$ openssl req -x509 
    -newkey rsa:4096 
    -days 3650 -nodes 
    -keyout board/pc-efibootguard-rauc/keyring/rauc-bundle.key.pem 
    -out board/pc-efibootguard-rauc/keyring/rauc-bundle.cert.pem 
    -subj "/CN=Buildroot EFI Boot Guard RAUC Demo Key/"
```

The generated keyring is suitable for local testing only. Production systems
should use their own key management and signing process.


## Build the image

Configure Buildroot with:

```
$ make pc_x86_64_efibootguard_rauc_defconfig
```


Build the image and RAUC bundle with:

```
$ make
```

The raw disk image is available under `output/images/disk.img`.

The RAUC bundle is generated under `output/images/upgrade_{VERSION}.rauc`.

By default, the RAUC bundle version is derived from the Buildroot version. To
override the bundle version, for example when building multiple bundles for
testing, set `BR2_LOCALVERSION`:

```
$ make BR2_LOCALVERSION="test-1.0.0"
```


## Emulation in QEMU

Emulate the system in QEMU with:

```
$ qemu-system-x86_64 \
    -M pc \
    -drive if=pflash,format=raw,readonly=on,file=</path/to/OVMF_CODE.fd> \
    -drive file=output/images/disk.img,if=virtio,format=raw \
    -boot menu=on \
    -net nic,model=virtio \
    -net user
```

Note that `</path/to/OVMF.fd>` needs to point to a valid x86_64 UEFI
firmware image for qemu. It may be provided by your distribution as a
edk2 or OVMF package, in a path such as `/usr/share/OVMF/OVMF_CODE_4M.fd` in
Debian.


## RAUC bundle installation

After booting the image, RAUC can be used to inspect the current slot state:

```
# rauc status
```

The output should show that the currently booted slot is `system.a`.


The first root filesystem slot is populated by the initial image. The second slot
is available as the inactive slot and a RAUC bundle can be installed to this slot.

It is recommended to build another RAUC bundle with a distinct version string to
make testing easier and to clearly identify which bundle has been installed.

Copy the generated RAUC bundle into the running system (out of scope for this
guide) and install the bundle with:

```
# rauc install /tmp/*.raucb
```

RAUC will install the bundle into the inactive slot and update the EFI Boot Guard
metadata so that the updated slot is selected on the next boot.

Reboot the system to boot into the updated slot:

```
# reboot
```

After rebooting, inspect the system state again:

```
# rauc status
```

The output should show that the currently booted slot is `system.b`.
