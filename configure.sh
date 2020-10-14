#!/usr/bin/env bash

set -euo pipefail

boot_partition=/dev/mmcblk0p1
filesys_partition=/dev/mmcblk0p2
mount_dir=/mnt/vattu
user=${USER}

unmount_boot_partition()
{
    sudo umount -v "${mount_dir}"
    trap EXIT
}

mount_boot_partition()
{
    sudo mount -v "${boot_partition}" "${mount_dir}"
    trap unmount_boot_partition EXIT
}

unmount_filesys_partition()
{
    sudo umount -v "${mount_dir}"
    trap EXIT
}

mount_filesys_partition()
{
    sudo mount -v "${filesys_partition}" "${mount_dir}"
    trap unmount_filesys_partition EXIT
}

copy_conf_files()
{
    sudo cp -v conf-files/* "${mount_dir}"/
}

create_wheel_group()
{
    if ! grep -q "wheel:" "${mount_dir}"/etc/group ; then
        sudo groupadd -R "${mount_dir}" wheel
    fi
}

add_user()
{
    if ! grep -q "${user}:" "${mount_dir}"/etc/passwd ; then
        sudo useradd -m -R "${mount_dir}" "${user}"
    fi
}

copy_ssh_key()
{
    sudo mkdir -v -p -m 700 "${mount_dir}"/home/"${user}"/.ssh
    sudo cp -v /home/"${user}"/.ssh/id_rsa.pub "${mount_dir}"/home/"${user}"/.ssh/authorized_keys
    uid=$(grep -m 1 "${user}" "${mount_dir}"/etc/passwd | cut -d ':' -f 3)
    gid=$(grep -m 1 "${user}" "${mount_dir}"/etc/passwd | cut -d ':' -f 4)
    sudo chown -v -R "${uid}":"${gid}" "${mount_dir}"/home/"${user}"/.ssh
}

disable_pi_password()
{
    sudo sed -i 's/\(pi:\)[^:]*\(:.*\)/\1!\2/' "${mount_dir}"/etc/shadow
}

add_user_to_wheel()
{
    sudo sed -i 's/\(^wheel.*:\).*/\1'"${user}"'/' "${mount_dir}"/etc/group
}

nopasswd_sudo_for_wheel()
{
    if ! sudo grep -q '%wheel ALL=(ALL) NOPASSWD: ALL' "${mount_dir}"/etc/sudoers ; then
        echo '%wheel ALL=(ALL) NOPASSWD: ALL' | sudo tee -a "${mount_dir}"/etc/sudoers > /dev/null
        sudo visudo -cf "${mount_dir}"/etc/sudoers
    fi
}

mount_boot_partition
copy_conf_files
unmount_boot_partition

mount_filesys_partition
add_user
copy_ssh_key
disable_pi_password
create_wheel_group
add_user_to_wheel
nopasswd_sudo_for_wheel
unmount_filesys_partition
