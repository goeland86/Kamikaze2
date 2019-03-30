#!/bin/bash
set -x
set -e

export VERSIONING=`pwd`/Packages/version.d
for f in `ls ${VERSIONING}/*`
  do
    source $f
  done
if [ -f "customize.sh" ] ; then
  source customize.sh
fi

TARGETIMAGE=kamikaze-rootfs.img
MOUNTPOINT=$(mktemp -d /tmp/umikaze-root.XXXXXX)

BASEIMAGE=`basename ${BASEIMAGE_URL}`

if [ ! -f $BASEIMAGE ]; then
    wget $BASEIMAGE_URL
fi

rm -f $TARGETIMAGE
xz -c -d $BASEIMAGE >> $TARGETIMAGE
truncate -s 4G $TARGETIMAGE
DEVICE=`losetup -P -f --show $TARGETIMAGE`

cat << EOF | fdisk ${DEVICE}
p
d
n
p
1
8192

p
w

EOF

e2fsck -f ${DEVICE}p1
resize2fs ${DEVICE}p1

mount ${DEVICE}p1 ${MOUNTPOINT}
mount -o bind /dev ${MOUNTPOINT}/dev
mount -o bind /sys ${MOUNTPOINT}/sys
mount -o bind /proc ${MOUNTPOINT}/proc

rm ${MOUNTPOINT}/etc/resolv.conf
cp /etc/resolv.conf ${MOUNTPOINT}/etc/resolv.conf

# don't git clone here - if someone did a commit since this script started, Unexpected Things will happen
# instead, do a deep copy so the image has a git repo as well
mkdir -p ${MOUNTPOINT}${UMIKAZE_HOME}

shopt -s dotglob # include hidden files/directories so we get .git
shopt -s extglob # allow excluding so we can hide the img files
cp -r `pwd`/!(*.img*) ${MOUNTPOINT}${UMIKAZE_HOME}
shopt -u extglob
shopt -u dotglob

if [ -f "customize.sh" ]; then
  add_custom_account
  perform_minimal_reconfiguration
fi

set +e # allow this to fail - we'll check the return code
chroot ${MOUNTPOINT} /bin/su -c "cd ${UMIKAZE_HOME} && ./prep_ubuntu.sh && ./make-kamikaze.sh"
status=$?
set -e

rm ${MOUNTPOINT}/etc/resolv.conf
umount ${MOUNTPOINT}/proc
umount ${MOUNTPOINT}/sys
umount ${MOUNTPOINT}/dev
umount ${MOUNTPOINT}
rmdir ${MOUNTPOINT}

if [ $status -eq 0 ]; then
    echo "Looks like the image was prepared successfully - packing it up"
    ./update-u-boot.sh $DEVICE
    ./generate-image-from-sd.sh $DEVICE
else
    echo "image generation seems to have failed - cleaning up"
fi



losetup -d $DEVICE
