#!/bin/bash

# My personal changes
# REDEEM_BRANCH="2_2_x"
# REDEEM_REPOSITORY="Private:Redeem"
# REDEEM_REPOSITORY="https://github.com/Wackerbarth/redeem"
# TOGGLE_BRANCH="1_3_x"
# TOGGLE_REPOSITORY="Private:Toggle"
# TOGGLE_REPOSITORY="https://github.com/Wackerbarth/toggle"
UMIKAZE_BRANCH="RC3"
# UMIKAZE_REPOSITORY="Private:Umikaze"
# UMIKAZE_REPOSITORY="https://github.com/Wackerbarth/Umikaze"

source ${VERSIONING}/_Version
# REDEEM_ENVIRONMENT="/usr/local/Redeem-${REDEEM_BRANCH}"
# TOGGLE_ENVIRONMENT="/usr/local/Toggle-${TOGGLE_BRANCH}"

### This function is run in the chrooted environment
add_custom_accounts() {
  :
}
### These functions are not run in the chrooted environment
before_running_in_chroot() {
  :
}
after_running_in_chroot() {
  :
}
