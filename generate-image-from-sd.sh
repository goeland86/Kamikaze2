#!/bin/bash

# This script currently does not have error checking in it and has not been heavily tested.
#   use this script at your own risk.
#
#   If you are debugging or just concerned uncomment the "set -e" line below to force the script to
#   terminate on any error. This includes erroring on already existing directories and similar minor issues.

set -e
set -x

#echo
#echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
#echo "! This script currently does not have error checking in it and has not been heavily tested. !"
#echo "!         As such use this script at your own risk till it can be refined further.          !"
#echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
#echo
#echo "This script will resize the file system and partition on the SD card to as small as possible."
#echo "After this it will clone the results to an image file on USB drive"
#echo
#echo "Please make sure the SD card and FAT formatted USB drive are inserted."
#read -rsp $'Press any key to continue...\n' -n1 key

# This is commended out because it currently cannot work, the script shuts the BB down after running
#echo "Running script to clone eMMC to SD"
#echo "/opt/scripts/tools/eMMC/beaglebone-black-make-microSD-flasher-from-eMMC.sh"
echo

DEVICE=$1
PARTITION=${DEVICE}p1
TARGET_PLATFORM=$2

echo "Device: $DEVICE"
echo "Partition: $PARTITION"

# This makes it so the image will boot on other BB not just the one it was built on
    MOUNTPOINT=$(mktemp -d /tmp/Refactor-sd.XXXXXX)
    mount $PARTITION ${MOUNTPOINT}
if [ ${TARGET_PLATFORM} == 'replicape' ]; then
    echo "Removing UUID references and uncommenting flasher option from /boot/uEnv.txt"
    sed -ie '/^uuid=/d' ${MOUNTPOINT}/boot/uEnv.txt
    #sed -ie 's/#cmdline=init=\/opt\/scripts\/tools\/eMMC\/init-eMMC-flasher-v3.sh$/cmdline=init=\/opt\/scripts\/tools\/eMMC\/init-eMMC-flasher-v3.sh/' ${MOUNTPOINT}/boot/uEnv.txt
fi

echo "Removing WPA wifi access file just in case"
rm -rf ${MOUNTPOINT}/root/wpa.conf
echo "Clearing bash history"
rm -rf ${MOUNTPOINT}/root/.bash_history
rm -rf ${MOUNTPOINT}/home/ubuntu/.bash_history
echo

# Likely not needed but for the sake of making the image smaller we defrag first
echo "Defragmenting partition mounted at ${MOUNTPOINT}."
e4defrag -c ${MOUNTPOINT} > /dev/null
umount ${MOUNTPOINT}
echo

# Run file system checks and then shrink the file system as much as possible
echo "Resizing filesystem."
e2fsck -f $PARTITION -y
resize2fs -pM $PARTITION
resize2fs -pM $PARTITION
e2fsck -f $PARTITION -y
echo

# Zero out the free space remaining on the file system
echo "Defrag and zero partition free space."
mount $PARTITION ${MOUNTPOINT}
e4defrag -c ${MOUNTPOINT} > /dev/null
dd if=/dev/zero of=${MOUNTPOINT}/zero_fill || true
rm -rf ${MOUNTPOINT}/zero_fill
umount ${MOUNTPOINT}
echo

# Run the file system checks and another series of file system shrinks just in case
#   we can shrink the file system any further after zeroing the free space.
echo "Resizing filesystem again."
e2fsck -f $PARTITION -y
resize2fs -pM $PARTITION
e2fsck -f $PARTITION -y
echo

# This is where the real danger starts with modifying the partitions
echo "Shrinking partition now."
# Gather useful partition data
fsblockcount=$(tune2fs -l $PARTITION | grep "Block count:" | awk '{printf $3}')
fsblocksize=$(tune2fs -l $PARTITION | grep "Block size:" | awk '{printf $3}')
partblocksize=$(fdisk -l $PARTITION | grep Units: | awk '{printf $8}')
partblockstart=$(fdisk -l -o Device,Start $DEVICE | grep $PARTITION | awk '{printf $2}')
partsize=$((fsblockcount*fsblocksize/partblocksize))

# Write out the partition layout that will replace the currently existing one.
cat <<EOF > /shrink.layout
# partition table of $DEVICE
unit: sectors

$PARTITION : start=${partblockstart}, size=${partsize}, Id=83, bootable
EOF

# Perform actual modifications to the partition layout
sfdisk $DEVICE < /shrink.layout
#rm -rf /shrink.layout

# Make sure the system sees the new partition layout, check the file system for issues
#   and then resize the file system to the full size of the new partition if it is needed
echo "Re-read partition table"
#hdparm -z $DEVICE
sync
echo "Wait for the kernel to re-read the table"
sleep 5

e2fsck -f $PARTITION -y
resize2fs $PARTITION
e2fsck -f $PARTITION -y
echo

# Run one last defrag and zero of the free space before backing it up
echo "Final defrag and zeroing partition free space."
mount $PARTITION ${MOUNTPOINT}
ImageVersion=$(cat ${MOUNTPOINT}/etc/refactor.version | sed 's/ /-/g' | awk -F' ' '{printf $1}')
e4defrag -c ${MOUNTPOINT} > /dev/null
# ignore the failure on this line - it runs until it's out of space
dd if=/dev/zero of=${MOUNTPOINT}/zero_fill || true
rm -rf ${MOUNTPOINT}/zero_fill
umount ${MOUNTPOINT}
rmdir ${MOUNTPOINT}
echo

# Final file system check
echo "File system and partition shrink are complete, running last file system check."
e2fsck -f $PARTITION -y
echo

# Mounting the USB thumb drive and generating the compressed image file on it from the sd card
echo "Generating image file now."
blocksize=$(fdisk -l $DEVICE | grep Units: | awk '{printf $8}')
count=$(fdisk -l -o Device,End $DEVICE | grep $PARTITION | awk '{printf $2}')
ddcount=$((count*blocksize/1000000+1))
dd if=$DEVICE bs=1MB count=${ddcount} | xz -vc -0 -T 0 > Refactor-${TARGET_PLATFORM}-"${ImageVersion}".img.xz
ln -s Refactor-${TARGET_PLATFORM}-"${ImageVersion}".img.xz Refactor-${TARGET_PLATFORM}-current.img.xz

# Talkie talkie
echo "***************************************************************************************"
echo "Image file generated on USB drive as Refactor-${TARGET_PLATFORM}-${ImageVersion}.img.xz"
echo "USB drive and MicroSD card can be removed safely now."
echo "***************************************************************************************"
