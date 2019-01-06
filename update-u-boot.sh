#!/bin/bash

set -e
set -x

DEVICE=$1

if [ ! "${DEVICE}" ] ; then
  echo "No device specified - exiting"
  exit 1
fi

source Packages/version.d/U-Boot

echo "Flashing U-Boot onto $DEVICE"

if [ ! -f ${UBOOT_SPL} ] ; then
    wget ${UBOOT_SPL_URL}
fi

if [ ! -f ${UBOOT_BIN} ] ; then
    wget ${UBOOT_BIN_URL}
fi

dd if=${UBOOT_SPL} of=${DEVICE} seek=1 bs=128k
dd if=${UBOOT_BIN} of=${DEVICE} seek=1 bs=384k

echo "U-Boot Update Complete!"

exit 0
