#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
echo "Installing ansible"

chmod o+r /etc/resolv.conf
echo "nameserver 1.1.1.1" > /etc/resolv.conf

apt-get update
apt-get -y install ansible git python3-pip python3-venv python-pip python-virtualenv python-apt python3-apt python-setuptools python-dev python3-dev
pip install --upgrade pip
pip install --upgrade virtualenv

sed -i 's/gather_timeout=10/gather_timeout=20/g' /etc/ansible/ansible.cfg

echo "Now the system is ready to use the ansible playbooks to build images."
