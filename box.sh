#!/bin/bash

set -eu

if echo "$PACKER_BUILD_NAME" | grep -q 'amd64'; then
  ostype='Debian_64'
elif echo "$PACKER_BUILD_NAME" | grep -q 'i386'; then
  ostype='Debian'
else
  >&2 echo "Virtualbox only works with amd64 or i386 guests"
  exit 1
fi

tmp="$(mktemp -d box.XXX)"

ova="builds/$PACKER_BUILD_NAME.ova"
vmdk="builds/$PACKER_BUILD_NAME.vmdk"

vboxmanage createvm --name "$PACKER_BUILD_NAME" \
                    --ostype "$ostype" \
                    --register

vboxmanage modifyvm "$PACKER_BUILD_NAME" --boot1 disk \
                                         --boot2 dvd \
                                         --boot3 none \
                                         --boot4 none

vboxmanage modifyvm "$PACKER_BUILD_NAME" --cpus 1
vboxmanage modifyvm "$PACKER_BUILD_NAME" --memory 512

vboxmanage storagectl "$PACKER_BUILD_NAME" --name 'SATA Controller' \
                                           --add sata \
                                           --portcount 4

vboxmanage storageattach "$PACKER_BUILD_NAME" --storagectl 'SATA Controller' \
                                              --port 0 \
                                              --device 0 \
                                              --type hdd \
                                              --nonrotational on \
                                              --discard on \
                                              --medium "$vmdk"

vboxmanage export "$PACKER_BUILD_NAME" --output "$ova"

vboxmanage unregistervm "$PACKER_BUILD_NAME" --delete

tar -xf "$ova" -C "$tmp"

mv "$tmp/$PACKER_BUILD_NAME.ovf" "$tmp/box.ovf"

mac_address="$(
  sed -rn 's/<Adapter slot="0".+?MACAddress="(.+?)".+?type="82540EM">/\1/p' \
          "$tmp/box.ovf" |
    xargs
)"

cat > "$tmp/Vagrantfile" << FILE
# The contents below were provided by the Packer Vagrant post-processor
Vagrant.configure("2") do |config|
  config.vm.base_mac = "$mac_address"
end
FILE

if echo "$PACKER_BUILD_NAME" | grep -q 'box-iso'; then
cat >> "$tmp/Vagrantfile" << FILE
# The contents below (if any) are custom contents provided by the
# Packer template during image build.
Vagrant.configure("2") do |config|
  config.ssh.insert_key = false
end
FILE
fi

cat > "$tmp/metadata.json" << 'FILE'
{"provider":"virtualbox"}
FILE

tar -cJf "builds/$PACKER_BUILD_NAME.box" -C "$tmp" .

rm -rf "$tmp" "$ova" "$vmdk"
