#!/usr/bin/env bash

set -euo pipefail

boot_partition=/dev/mmcblk0p1
filesys_partition=/dev/mmcblk0p2
mount_dir=/mnt/vattu
tmp_dir=$(mktemp -d)
user=${USER}

unmount_boot_partition()
{
    sudo umount -v "${mount_dir}"
    trap EXIT
}

mount_boot_partition()
{
    sudo mount -v -o uid="$(id -u)",gid="$(id -g)" "${boot_partition}" "${mount_dir}"
    trap unmount_boot_partition EXIT
}

unmount_filesys_partition()
{
    sudo umount -v "${tmp_dir}" || echo umount failed
    sudo umount -v "${mount_dir}"
    trap EXIT
}

mount_filesys_partition()
{
    sudo mount -v "${filesys_partition}" "${mount_dir}"
    sudo bindfs -u "$(id -u)" -g "$(id -g)" "${mount_dir}" "${tmp_dir}"
    trap unmount_filesys_partition EXIT
}

copy_conf_files()
{
    cp -v conf-files/* "${mount_dir}"/
}

edit_boot_cmd()
{
    if ! grep -q "cgroup_memory" "${mount_dir}"/cmdline.txt ; then
        sed -i 's/$/ cgroup_memory=1/' "${mount_dir}"/cmdline.txt
    fi
    if ! grep -q "cgroup_enable" "${mount_dir}"/cmdline.txt ; then
        sed -i 's/$/ cgroup_enable=memory/' "${mount_dir}"/cmdline.txt
    fi
}

create_wheel_group()
{
    if ! grep -q "wheel:" "${mount_dir}"/etc/group ; then
        groupadd -R "${mount_dir}" wheel
    fi
}

add_user()
{
    if ! grep -q "${user}:" "${tmp_dir}"/etc/passwd ; then
        useradd -m -R "${tmp_dir}" "${user}"
    fi
}

copy_ssh_key()
{
    mkdir -v -p -m 700 "${tmp_dir}"/home/"${user}"/.ssh
    cp -v /home/"${user}"/.ssh/id_rsa.pub "${tmp_dir}"/home/"${user}"/.ssh/authorized_keys
    uid=$(grep -m 1 "${user}" "${tmp_dir}"/etc/passwd | cut -d ':' -f 3)
    gid=$(grep -m 1 "${user}" "${tmp_dir}"/etc/passwd | cut -d ':' -f 4)
    sudo chown -v -R "${uid}":"${gid}" "${tmp_dir}"/home/"${user}"/.ssh
}

disable_pi_password()
{
    sed -i 's/\(pi:\)[^:]*\(:.*\)/\1!\2/' "${tmp_dir}"/etc/shadow
}

add_user_to_wheel()
{
    sed -i 's/\(^wheel.*:\).*/\1'"${user}"'/' "${tmp_dir}"/etc/group
}

nopasswd_sudo_for_wheel()
{
    if ! grep -q '%wheel ALL=(ALL) NOPASSWD: ALL' "${tmp_dir}"/etc/sudoers ; then
        echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> "${tmp_dir}"/etc/sudoers > /dev/null
        visudo -cf "${tmp_dir}"/etc/sudoers
    fi
}

mount_boot_partition
copy_conf_files
edit_boot_cmd
unmount_boot_partition

mount_filesys_partition
add_user
copy_ssh_key
disable_pi_password
create_wheel_group
add_user_to_wheel
nopasswd_sudo_for_wheel
unmount_filesys_partition
