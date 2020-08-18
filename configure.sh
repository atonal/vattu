#!/usr/bin/env bash

set -euo pipefail

boot_partition=/dev/mmcblk0p1
filesys_partition=/dev/mmcblk0p2
mount_dir=/mnt/vattu
user=${USER}

sudo mount -v "${boot_partition}" "${mount_dir}"
sudo cp -v conf-files/* "${mount_dir}"/
sudo umount -v "${mount_dir}"

sudo mount -v "${filesys_partition}" "${mount_dir}"
sudo mkdir -v -p -m 700 "${mount_dir}"/home/pi/.ssh
sudo cp -v /home/"${user}"/.ssh/id_rsa.pub "${mount_dir}"/home/pi/.ssh/authorized_keys
sudo chown -v -R 1000:1000 "${mount_dir}"/home/pi/.ssh
sudo umount -v "${mount_dir}"
