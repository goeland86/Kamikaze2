#!/bin/bash
set -x
set -e
>/root/prep_ubuntu.log
exec >  >(tee -ia /root/prep_ubuntu.log)
exec 2> >(tee -ia /root/prep_ubuntu.log >&2)

upgrade_base_operating_system() {
  echo "Upgrading packages"
  apt-get update
  echo "Removing unwanted kernel packages"
# apt-get -y remove linux-image-*
  apt-get -y remove linux-headers-*
  apt-get -y autoremove
# systemctl disable bb-wl18xx-wlan0
  echo "Updating uboot..."
  sed -i 's\uboot_overlay_pru=/lib/firmware/AM335X-PRU-RPROC\#uboot_overlay_pru=/lib/firmware/AM335X-PRU-RPROC\' /boot/uEnv.txt
  sed -i 's\#uboot_overlay_pru=/lib/firmware/AM335X-PRU-UIO\uboot_overlay_pru=/lib/firmware/AM335X-PRU-UIO\' /boot/uEnv.txt
  sed -i 's\##uboot\#uboot\' /boot/uEnv.txt
  echo "** Preparing Ubuntu for Umikaze **"

  echo "Updating kernel..."
  cd /opt/scripts/tools/
  git pull
  # Update to the latest ti kernel with initrd!
  FORCEMACHINE=TI_AM335x_BeagleBoneBlack sh update_kernel.sh --lts-4_14 --ti-kernel
  KERNEL_VERSION=`awk -F '=' '/uname_r/ {print $2}' /boot/uEnv.txt`
  apt-get install linux-headers-$KERNEL_VERSION
# apt-get -y install ti-sgx-es8-modules-$KERNEL_VERSION
  depmod $KERNEL_VERSION
  update-initramfs -k $KERNEL_VERSION -u

  echo "Updating wireless..."
  if [ ! -d "/usr/src/wl18xx_fw" ]; then
    git clone --no-single-branch --depth 1 git://git.ti.com/wilink8-wlan/wl18xx_fw.git /usr/src/wl18xx_fw
  fi
  cp /usr/src/wl18xx_fw/wl18xx-fw-4.bin /lib/firmware/ti-connectivity/wl18xx-fw-4.bin

  echo "Upgrade everything..."
  apt-get -y upgrade

  echo "Handle iptables..."
  # first do some magic so iptables-persistent doesn't prompt
  apt-get -y install debconf-utils
  echo "iptables-persistent     iptables-persistent/autosave_v4 boolean true" | debconf-set-selections
  echo "iptables-persistent     iptables-persistent/autosave_v6 boolean true" | debconf-set-selections

  # now install it
  apt-get -y -q --no-install-recommends --force-yes install unzip iptables iptables-persistent
  systemctl enable netfilter-persistent
  sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
}

add_thing_printer_support_repository() {
  echo "installing Kamikaze repository to the list"
  cat >/etc/apt/sources.list.d/testing.list <<EOL
#### Kamikaze ####
deb [arch=armhf] http://kamikaze.thing-printer.com/ubuntu/ xenial main
#deb [arch=armhf] http://kamikaze.thing-printer.com/debian/ stretch main
EOL
  wget -q http://kamikaze.thing-printer.com/ubuntu/public.gpg -O- | apt-key add -
# wget -q http://kamikaze.thing-printer.com/debian/public.gpg -O- | apt-key add -
  apt-get update
}

install_network_manager() {
  echo "** Disable wireless power management **"
  mkdir -p /etc/pm/sleep.d
  touch /etc/pm/sleep.d/wireless

  echo "** Install Network Manager **"
  apt-get -y install --no-install-recommends network-manager
# ln -s /run/resolvconf/resolv.conf /etc/resolv.conf
  sed -i 's/^\[main\]/\[main\]\ndhcp=internal/' /etc/NetworkManager/NetworkManager.conf

  cat >/etc/network/interfaces <<EOF
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
iface eth0 inet dhcp
# Example to keep MAC address between reboots
#hwaddress ether DE:AD:BE:EF:CA:FE

# To setup wifi use nmtui to add or edit connections instead

# Ethernet/RNDIS gadget (g_ether)
# Used by: /opt/scripts/boot/autoconfigure_usb0.sh

auto usb0
iface usb0 inet static
  address 192.168.7.2
  netmask 255.255.255.252
  network 192.168.7.0
  gateway 192.168.7.1
EOF
}

remove_unneeded_packages() {
  echo "** Remove unneeded packages **"*
  rm -rf /etc/apache2/sites-enabled
  rm -rf /root/.c9
  rm -rf /usr/local/lib/node_modules
  rm -rf /var/lib/cloud9
  rm -rf /usr/lib/node_modules/
  apt-get purge -y apache2 apache2-bin apache2-data apache2-utils hostapd
}

cleanup() {
  apt-get remove -y libgtk-3-common
  apt-get autoremove -y
}

prep() {
  upgrade_base_operating_system
  add_thing_printer_support_repository
  install_network_manager
  remove_unneeded_packages
  cleanup
}

prep

echo "Now reboot into the new kernel and run make-kamikaze.sh"
