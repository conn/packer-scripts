#!/bin/bash

set -eu

src="$(
  find builds \
      \( -name "$PACKER_BUILD_NAME.iso" -o -name "$PACKER_BUILD_NAME.qcow2" \) \
    -print -quit
)"

vmdk="builds/$PACKER_BUILD_NAME.vmdk"

qemu-img convert -O vmdk "$src" "$vmdk"

rm "$src"
