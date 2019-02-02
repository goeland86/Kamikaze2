#!/bin/bash

echo "** Updating Kamikaze **"

install_uboot() {
        echo "** install U-boot **"
        cd /usr/src/Kamikaze2
        export DISK=/dev/mmcblk0
        dd if=./u-boot/MLO of=${DISK} count=1 seek=1 bs=128k
        dd if=./u-boot/u-boot.img of=${DISK} count=2 seek=1 bs=384k
}

install_uboot
