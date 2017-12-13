#!/bin/bash

set -eu

read -r name version time < <(
  echo "$PACKER_BUILD_NAME" |
  sed -rn 's/(.+)-docker-([0-9\.]+)-([1-9]+)/\1 \2 \3/p'
)

image="conn/$name:$version-$time"

docker save "$image" | xz -zc - > builds/"$PACKER_BUILD_NAME".tar.xz
docker image rm "$image"
