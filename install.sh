#!/usr/bin/env bash

set -euo pipefail

root_dir=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
raspbian_image="${root_dir}"/raspbian/2020-02-13-raspbian-buster.zip
memory_card_dev=/dev/mmcblk0

unzip -p "${raspbian_image}" | sudo dd of="${memory_card_dev}" bs=4M conv=fsync status=progress
