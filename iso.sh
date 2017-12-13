#!/bin/bash

set -eu

tmp="$(mktemp -d iso.XXX)"

tarball="builds/$PACKER_BUILD_NAME.tar"

for dir in chroot isolinux live; do
  install -o root -g root -m 0755 -d "$tmp/$dir"
done

tar -xp -C "$tmp/chroot" -f "$tarball"

(
  cd "$tmp"

  mksquashfs chroot live/filesystem.squashfs -comp xz -e boot
  cp chroot/boot/vmlinuz-* live/vmlinuz
  cp chroot/boot/initrd.img-* live/initrd
  rm -rf chroot

  cp /usr/lib/ISOLINUX/isolinux.bin \
     /usr/lib/syslinux/modules/bios/menu.c32 \
     /usr/lib/syslinux/modules/bios/ldlinux.c32 \
     /usr/lib/syslinux/modules/bios/libutil.c32 \
     /usr/lib/syslinux/modules/bios/libmenu.c32 \
     /usr/lib/syslinux/modules/bios/libcom32.c32 \
     /usr/lib/syslinux/modules/bios/libgpl.c32 \
     isolinux
)

cp packer/files/isolinux.cfg "$tmp/isolinux/isolinux.cfg"

xorriso \
    -as mkisofs \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    -b isolinux/isolinux.bin \
    -c isolinux/boot.cat \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -output "builds/$PACKER_BUILD_NAME.iso" \
  "$tmp"

rm -rf "$tmp" "$tarball"
