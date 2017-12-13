#!/bin/bash

set -eu

tmp="$(mktemp -d erased.XXX)"
chmod 0755 "$tmp"

tarball="builds/$PACKER_BUILD_NAME.tar"


tar -xp -C "$tmp" -f "$tarball"

for file in hostname hosts resolv.conf; do
  install -o root -g root -m 0644 /dev/null "$tmp/etc/$file"
done

cat > "$tmp/etc/resolv.conf" << 'CONF'
nameserver 8.8.8.8
nameserver 8.8.4.4
CONF

cat > "$tmp/etc/hosts" << 'CONF'
127.0.0.1 localhost
CONF

cat > "$tmp/etc/hostname" << 'CONF'
localhost
CONF

tar -p --numeric-owner -C "$tmp" -f "$tarball" -c .

rm -rf "$tmp"
