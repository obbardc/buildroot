EFI Boot Guard Example Recipe
=============================

This recipe creates a basic x86 disk image using EFI Boot Guard[1] as the
bootloader with two root filesystem slots.

The image is intended to demonstrate a typical A/B boot layout. The first slot
is populated with the root filesystem generated as part of the Buildroot build.
The second slot is intentionally left empty so that a future update tool can
install an alternate root filesystem there.

The recipe also creates the EFI system partition and installs the EFI Boot Guard
bootloader and configuration needed to select and boot one of the available slots.
Each slot has its own EFI Boot Guard environment, containing the kernel image and
configuration.

This example is deliberately minimal. It is intended as a reference for users who
want to integrate EFI Boot Guard into their own platform-specific images, rather
than as a complete production-ready setup. It was designed to be run in QEMU and
may need additional changes to run on real hardware.

By default this example is built with UEFI Secure Boot support enabled. In that
mode, both the EFI Boot Guard and kernel binaries are signed during image
generation so that they can be verified by the firmware before execution.

Secure Boot support in this recipe is primarily intended for development and
testing. These instructions contain the steps to generate signed EFI binaries,
but a production system should use platform-specific key management, key
enrolment and signing infrastructure, which is out of scope of this document.
In particular, the example keys must not be reused for production images.


Build the image
===============

Configure Buildroot with:

  $ make pc_x86_64_efibootguard_defconfig

Build the image with:

  $ make

The raw disk image is available under output/images/disk.img.


Emulation in QEMU
=================

Emulate the system in QEMU with:

  $ qemu-system-x86_64 \
      -machine q35,smm=on \
      -m size=512M \
      -drive if=pflash,format=raw,readonly=on,file=</path/to/OVMF_CODE.fd> \
      -drive file=output/images/disk.img,if=virtio,format=raw \
      -boot menu=on \
      -device i6300esb \
      -action watchdog=reset

Note that </path/to/OVMF_CODE.fd> needs to point to a valid x86_64 UEFI firmware
image for QEMU. It may be provided by your distribution as an edk2 or OVMF
package, in a path such as /usr/share/OVMF/OVMF_CODE_4M.fd on Debian.


Boot process & slot configuration
=================================

This example uses EFI Boot Guard as the first-stage UEFI boot application for
A/B boot selection. The disk image contains a shared EFI System Partition, two
small EFI Boot Guard configuration partitions and two root filesystem slots:

* EFI System Partition ("EFI")
  Contains the EFI Boot Guard bootloader binary.

* EFI Boot Guard config partition A ("boot-a")
  Contains the boot environment for slot A, including the EFI Boot Guard slot
  configuration and kernel image built by Buildroot.

* EFI Boot Guard config partition B ("boot-b")
  Contains the boot environment for slot B, including the EFI Boot Guard slot
  configuration to disable booting from slot B.

* rootfs A ("system-a")
  First root filesystem slot. Populated with the target filesystem built by
  Buildroot.

* rootfs B ("system-b")
  Second root filesystem slot. Not populated by default.

The firmware first loads EFI Boot Guard from the EFI System Partition. EFI
Boot Guard then reads its slot metadata from the configuration partitions and
selects the best bootable slot. Each slot has an EFI Boot Guard environment
file containing the slot label, revision, ustate, watchdog timeout, boot file
and optional kernel arguments.

The slot's ustate controls whether a slot is considered bootable. A newly installed
slot is normally marked as pending/testing and, if enabled in the slot config,
a watchdog is started on the device. EFI Boot Guard attempts to boot the slot.

Once Linux has booted successfully, user-space must mark the slot's ustate as
OK. If the system fails to boot or the watchdog expires before the slot is
confirmed, EFI Boot Guard can fall back to the previous working slot or refuse
to boot.

The slot environments are generated at image assembly time using the EFI Boot
Guard host tools. They are intentionally generated outside the target rootfs
because they describe the final disk image layout rather than files installed
inside a single root filesystem. By default, the recipe sets slot A with ustate
of OK.

For more information on EFI Boot Guard configuration, see the upstream
documentation[1].


Watchdog
========

EFI Boot Guard can arm a hardware watchdog before handing control to Linux. The
watchdog protects against a system that starts booting a bad slot but then hangs
before userspace can report success or failure.

If Linux boots correctly, userspace must take over or disarm the watchdog before
the timeout expires. With systemd this is usually done by enabling the runtime
watchdog, for example by setting RuntimeWatchdogSec. The runtime watchdog timeout
should be shorter than the EFI Boot Guard watchdog timeout so that systemd starts
feeding the watchdog in time.

By default, the recipe configures EFI Boot Guard to arm a 120 second watchdog and
enables a systemd runtime watchdog value of 60 seconds to give Linux enough time
to boot and take over the device.

EFI Boot Guard has limited support for hardware watchdogs and will refuse to
boot the slot if no supported hardware watchdog is found and the slot has the
watchdog parameter configured to >0. To disable the watchdog at image generation
time, set WATCHDOG_TIMEOUT in post_image.sh to 0. This can be useful during
development but removes one of the main safety mechanisms for A/B rollback
testing.

When testing under QEMU, an emulated watchdog can be enabled with:

  -device i6300esb
  -action watchdog=reset

This causes QEMU to reset the virtual machine if the watchdog expires.


Unified Kernel Image (UKI)
==========================

By default this recipe builds the boot payload as a Unified Kernel Image (UKI).
A UKI bundles a kernel, initramfs, device tree(s) and kernel command line into a
single PE/COFF EFI binary.

For this example recipe, only the kernel image and command line are bundled
into the UKI binary.

When UKI support is disabled, EFI Boot Guard loads a normal kernel image and
passes the kernel command line from the EFI Boot Guard environment.

UKIs are useful when combined with Secure Boot because the whole boot payload
can be signed as one EFI binary.


UEFI Secure Boot
================

The recipe by default will sign the EFI binaries with Secure Boot keys. When
enabled, the recipe:

* uses Secure Boot keys: a Platform Key (PK), Key Exchange Key (KEK) and signature
  database (db) key/certificate pair.
* signs the EFI Boot Guard EFI binary and the UKI (or other EFI boot payload)
  with the db key.
* installs the signed EFI binaries.
* copies the DER certificates needed for UEFI firmware enrolment into the EFI
  System Partition under \keys.

Secure Boot verifies EFI binaries before they are executed. In this setup, the
firmware verifies EFI Boot Guard and EFI Boot Guard then loads the selected
signed boot payload.

The following instructions can be ran on the host to generate dummy self-signed
key/certificate pairs. These are intended for testing only and must not be used
in production:

  $ export KEYS_DIR=output/images/secure-boot-keys
  $ mkdir -p "${KEYS_DIR}"
  $ for name in PK KEK db; do
      openssl req -new -x509 -newkey rsa:2048 -sha256 \
        -days 3650 -nodes \
        -subj "/CN=pc-efibootguard ${name}/" \
        -keyout "${KEYS_DIR}/${name}.key" \
        -out "${KEYS_DIR}/${name}.crt"
      openssl x509 \
        -in "${KEYS_DIR}/${name}.crt" \
        -outform DER \
        -out "${KEYS_DIR}/${name}.cer"
    done

The generated keys are stored under output/images/secure-boot-keys/. They are
created once and reused on subsequent builds. These files are removed with
"make clean".


Testing under QEMU
------------------

Secure Boot must be enforced by the firmware, which in QEMU requires the
"secboot" OVMF build together with SMM and a q35 machine. The OVMF variables
file is persistent, so make a fresh writable copy of the variable store first.
If the disk layout, boot entries or enrolled keys change, remove the old
OVMF_VARS.fd and copy a fresh one before retesting.

  $ cp </path/to/OVMF_VARS_4M.fd> OVMF_VARS.fd

Then run QEMU:

  $ qemu-system-x86_64 \
      -machine q35,smm=on \
      -m 512M \
      -global driver=cfi.pflash01,property=secure,value=on \
      -drive if=pflash,format=raw,unit=0,readonly=on,file=</path/to/OVMF_CODE.secboot.fd> \
      -drive if=pflash,format=raw,unit=1,file=OVMF_VARS.fd \
      -drive file=output/images/disk.img,if=virtio,format=raw \
      -boot menu=on \
      -device i6300esb \
      -action watchdog=reset

On the very first boot Secure Boot is not yet enabled and the keys must first be
enrolled once. The DER certificates are copied into the EFI System Partition
under \keys for convenience. Press ESC at the logo and choose "EFI Firmware Setup"
to reach the UEFI menu, then enrol the keys:

  Device Manager
    -> Secure Boot Configuration
      -> Secure Boot Mode -> Custom Mode
      -> Custom Secure Boot Options
        -> DB Options    -> Enroll Signature -> Enroll Signature Using File
                            -> select FS0:\keys\db.cer  -> Commit Changes
        -> KEK Options   -> ... FS0:\keys\KEK.cer       -> Commit Changes
        -> PK Options    -> ... FS0:\keys\PK.cer        -> Commit Changes

Enrol the db and KEK before the PK. Enrolling the PK switches the firmware into
User Mode and activates Secure Boot. Reset the machine - the firmware now
verifies the signed EFI Boot Guard bootloader, which in turn loads the signed
kernel image.


EFI Boot Guard user-space tools
===============================

The example image includes the EFI Boot Guard user-space tools. These can be
used to inspect and update the slot configuration.

bg_printenv prints the EFI Boot Guard slot config (of all slots):

  # bg_printenv


bg_setenv can be used to update a slot's configuration, including its ustate and
revision. For example, the following commands mark both slots as OK and make
slot 0 (e.g. the first configuration partition) the preferred slot to boot:

  # bg_setenv --preserve --part 0 --ustate OK --revision 1
  # bg_setenv --preserve --part 1 --ustate OK --revision 0


Note that without --preserve bg_setenv will rewrite the slot config rather than
updating only the options specified on the command line. Any omitted settings
may be written with their default or empty values, so make sure to pass all
options to avoid producing an incomplete environment.

An update system could use these tools to switch the preferred boot slot after
installing an update and to mark a slot's ustate as OK once the newly installed
slot boots successfully.

For more information on configuring EFI Boot Guard, see the upstream
documentation[1].

[1]: https://github.com/siemens/efibootguard/blob/master/README.md
