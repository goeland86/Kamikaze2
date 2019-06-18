#!/bin/bash
set -x
set -e
>/root/make-kamikaze.log
exec >  >(tee -ia /root/make-kamikaze.log)
exec 2> >(tee -ia /root/make-kamikaze.log >&2)

# Get the versioning information from the entries in version.d/
export VERSIONING=`pwd`/Packages/version.d
for f in `ls ${VERSIONING}/*`
  do
    source $f
  done
if [ -f "customize.sh" ] ; then
  source customize.sh
else
  add_custom_accounts() {
    :
  }
fi

echo "**Making ${VERSION}**"
export LC_ALL=C
export PATH=`pwd`/Packages:$PATH

install_sgx
setup_port_forwarding
install_dependencies
create_octoprint_user
add_custom_accounts
install_service_virtualization
install_redeem-py2
# install_redeem-py3
install_octoprint
install_octoprint_redeem
install_octoprint_toggle
install_toggle-py2
# install_toggle-py3
# install_cura
# install_slic3r
install_u-boot
make_general_adjustments
install_usbreset
install_smbd
install_dummy_logging
install_videostreamer
install_ffmpeg
rebrand_ssh
prepare_revolve
perform_cleanup
install_flasher

echo "Now reboot!"
