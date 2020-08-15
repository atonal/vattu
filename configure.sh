#!/usr/bin/env bash

set -euo pipefail

boot_partition=/dev/mmcblk0p1
mount_dir=/mnt/vattu

sudo mount -v "${boot_partition}" "${mount_dir}"
sudo cp -v conf-files/* "${mount_dir}"/
sudo umount -v "${mount_dir}"
