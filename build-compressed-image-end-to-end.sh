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
else
  before_running_in_chroot() {
    :
  }
  after_running_in_chroot() {
    :
  }
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
VIRTUAL_DISK=`losetup -P -f --show $TARGETIMAGE`

cat << EOF | fdisk ${VIRTUAL_DISK}
p
d
n
p
1
8192

p
w

EOF

e2fsck -f ${VIRTUAL_DISK}p1
resize2fs ${VIRTUAL_DISK}p1
e2label ${VIRTUAL_DISK}p1 ${UMIKAZE_BRANCH}

mount ${VIRTUAL_DISK}p1 ${MOUNTPOINT}
mount -o bind /dev ${MOUNTPOINT}/dev
mount -o bind /sys ${MOUNTPOINT}/sys
mount -o bind /proc ${MOUNTPOINT}/proc

echo "Mounting /dev/ and /dev/pts in chroot... "
mkdir -p -m 755 ${MOUNTPOINT}/dev/pts
mount -t devpts -o gid=5,mode=620 devpts ${MOUNTPOINT}/dev/pts
echo "OK"

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

before_running_in_chroot

set +e # allow this to fail - we'll check the return code
chroot ${MOUNTPOINT} /bin/su -c "cd ${UMIKAZE_HOME} && ./prep_ubuntu.sh && ./make-kamikaze.sh"
status=$?
set -e

if [ $status -eq 0 ]; then
    after_running_in_chroot
fi

rm ${MOUNTPOINT}/etc/resolv.conf
umount ${MOUNTPOINT}/proc
umount ${MOUNTPOINT}/sys
umount ${MOUNTPOINT}/dev/pts
umount ${MOUNTPOINT}/dev
umount ${MOUNTPOINT}
rmdir ${MOUNTPOINT}

if [ $status -eq 0 ]; then
    echo "Looks like the image was prepared successfully - packing it up"
    ./update-u-boot.sh $VIRTUAL_DISK
    ./generate-compressed-distribution-image.sh $VIRTUAL_DISK
else
    echo "image generation seems to have failed - cleaning up"
fi

losetup -d $VIRTUAL_DISK

exit $status
