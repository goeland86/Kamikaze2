#!/bin/bash
set -x
set -e

BASEIMAGE_URL=https://rcn-ee.com/rootfs/2018-02-09/microsd/bone-ubuntu-16.04.3-console-armhf-2018-02-09-2gb.img.xz
TARGETIMAGE=kamikaze-rootfs.img

BASEIMAGE=`basename $BASEIMAGE_URL`

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

mount ${DEVICE}p1 /mnt/root
mount -o bind /dev /mnt/root/dev
mount -o bind /sys /mnt/root/sys
mount -o bind /proc /mnt/root/proc

mkdir -p /mnt/root/run/resolvconf
cp /etc/resolv.conf /mnt/root/run/resolvconf/resolv.conf

cp make-kamikaze-2.1.sh /mnt/root/root
cp prep_ubuntu.sh /mnt/root/root
git clone https://github.com/goeland86/Umikaze2.git /mnt/root/usr/src/Umikaze2
chroot /mnt/root /bin/su -c "cd /root && ./prep_ubuntu.sh && ./make-kamikaze-2.1.sh"

umount /mnt/root/proc
umount /mnt/root/sys
umount /mnt/root/dev
umount /mnt/root

./generate-image-from-sd.sh $DEVICE

losetup -d $DEVICE
