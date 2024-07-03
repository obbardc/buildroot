# EFI Boot Guard Example Recipe

This recipe creates a basic x86 disk image using [EFI Boot Guard](https://github.com/siemens/efibootguard/tree/master)
as the bootloader with two root filesystem slots.

The image is intended to demonstrate a typical A/B boot layout. The first slot is
populated with the root filesystem generated as part of the Buildroot build,
while the second slot is left empty so that it can be used later by an update
tool, which is out-of-scope for this example recipe.

The recipe also creates the EFI system partition and installs the EFI Boot Guard
bootloader components needed to select and boot one of the available slots. Each
slot has its own EFI Boot Guard environment, containing the kernel image and
configuration.

This example is deliberately minimal. It is intended as a reference for users who
want to integrate EFI Boot Guard into their own platform-specific images, rather
than as a complete production-ready update setup.

This recipe was designed to be ran in QEMU and may need additional changes to run
on real hardware.


## Build the image

Configure Buildroot with:

```
$ make pc_x86_64_efibootguard_defconfig
```


Build the image with:

```
$ make
```

The raw disk image is available under `output/images/disk.img`.


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


## EFI Boot Guard userspace tools

The example image includes the EFI Boot Guard userspace tools. These can be used
to inspect and update the boot metadata stored in each slot environment.

`bg_printenv` prints the current EFI Boot Guard boot configuration:

```
# bg_printenv
```

`bg_setenv` updates the state and revision of a slot. For example, the following
commands initialise both slots and prefers booting from slot `0`:

```
# bg_setenv --part 0 --ustate OK --revision 1
# bg_setenv --part 1 --ustate OK --revision 0
```

In this example, both slots are marked as usable, but slot `0` has the higher
revision. EFI Boot Guard will therefore select it before slot `1`.

For more information on configuring EFI Boot Guard, see the
[upstream documentation](https://github.com/siemens/efibootguard/blob/master/README.md).

An update framework (such as RAUC) can use these tools to switch the preferred
boot slot after installing an update and to mark a slot as failed if the updated
system does not boot successfully.
