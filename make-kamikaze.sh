#!/bin/bash
set -x
set -e
>/root/make-kamikaze.log
exec >  >(tee -ia /root/make-kamikaze.log)
exec 2> >(tee -ia /root/make-kamikaze.log >&2)

# TODO 2.1:
# PCA9685 in devicetree
# Make redeem dependencies built into redeem
# Remove xcb/X11 dependencies
# Add sources to clutter packages
# Slic3r support
# Edit Cura profiles
# Remove root access
# /dev/ttyGS0

# TODO 2.0:
# After boot,
# initrd img / depmod-a on new kernel.

# STAGING:
# Copy uboot files to /boot/uboot
# Restart commands on install for Redeem and Toggle
# Update to Clutter 1.26.0+dsfg-1

# Get the versioning information from the entries in version.d/
export VERSIONING=`pwd`/Packages/version.d
for f in `ls ${VERSIONING}/*`
  do
    source $f
  done

echo "**Making ${VERSION}**"
export LC_ALL=C
export PATH=`pwd`/Packages:$PATH

install_sgx
setup_port_forwarding
install_dependencies
create_octoprint_user
install_service_virtualization
install_redeem
install_octoprint
install_octoprint_redeem
install_octoprint_toggle
install_toggle
# install_cura
# install_slic3r
# install_u-boot
make_general_adjustments
install_usbreset
install_smbd
install_dummy_logging
install_videostreamer
install_ffmpeg
rebrand_ssh
perform_cleanup
prepare_flasher

echo "Now reboot!"
