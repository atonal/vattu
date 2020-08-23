#!/usr/bin/env bash

root_dir=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

ansible-playbook "${root_dir}"/ansible/playbook.yml -i "${root_dir}"/ansible/inventory "$@"
