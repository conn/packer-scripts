#!/bin/bash

set -eu

tmp="$(mktemp -d qcow2.XXX)"
chmod 0755 "$tmp"

tarball="builds/$PACKER_BUILD_NAME.tar"
qcow="builds/$PACKER_BUILD_NAME.qcow2"

nbd="/dev/$(
  comm -3 \
      <(lsblk -nl -I 43 -o NAME | grep -vF p | sort -V) \
      <(find /dev -name 'nbd*' -print0 | xargs -0l basename | sort -V) |
    head -n 1 |
    xargs
)"

nbdp1="/dev/mapper/${nbd#/dev/}p1"

qemu-img create -f qcow2 "$qcow" 20G
qemu-nbd --connect="$nbd" "$qcow"

echo ';' | sfdisk --force "$nbd" 2>/dev/null
kpartx -a "$nbd"

sync
sleep 1

mkfs.xfs -n ftype=1 "$nbdp1"
mount "$nbdp1" "$tmp"

tar -xp -C "$tmp" -f "$tarball"

mount -t proc none "$tmp/proc"
mount -t sysfs none "$tmp/sys"
mount --bind /dev "$tmp/dev"
mount --bind /dev/pts "$tmp/dev/pts"

chroot "$tmp" /bin/bash << COMMANDS
grub-install --recheck "$nbd"
update-grub
COMMANDS

sync
sleep 1

umount -Rl "$tmp"
kpartx -d "$nbd"
qemu-nbd --disconnect "$nbd"

rm -rf "$tmp" "$tarball"
