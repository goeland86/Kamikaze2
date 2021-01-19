#!/bin/bash
set -x
set -e
>/root/make-refactor.log
exec >  >(tee -ia /root/make-refactor.log)
exec 2> >(tee -ia /root/make-refactor.log >&2)

if [[ $# -ne 1 ]]; then
    echo "You need to specify the platform when you run the script."
    echo "It currently needs to be one of [recore, replicape, pi, pi64]"
    exit 1
fi

ansible-playbook SYSTEM_klipper_octoprint-DEFAULT.yml --extra-vars "{platform: $1}" -i hosts

echo "Now reboot!"
