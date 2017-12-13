# Packer Scripts

Common scripts used by my Packer templates

## Setup:
You'll need some packages:
* docker-ce
* kpartx
* qemu-utils
* squashfs-tools
* virtualbox
* xfsprogs
* xorriso
* xz-utils

My image-builder role should cover all dependencies needed to run my
rootfs-builder/templates/scripts.

## Usage:
You don't want to use these by themselves; they're meant to be ran from within
the root directory of a Packer template project.

You should clone Packer template projects recursively to automatically pull
these scripts in.
