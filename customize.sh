#!/bin/bash

add_custom_account() {
  # To avoid an empty function because users may not have made any customizations
  return
}

perform_minimal_reconfiguration() {
  echo "** Revert SSH message **"
  cat > ${MOUNTPOINT}/etc/issue.net << EOL
Ubuntu 16.04.3 LTS
EOL
  rm ${MOUNTPOINT}/etc/issue
  (cd ${MOUNTPOINT}/etc ; ln -s issue.net issue)
}
