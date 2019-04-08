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

DEVICE='/dev/sda'
FILE_NAME=` echo $VERSION | tr " " "-"`
COMPRESSED_IMAGE="${FILE_NAME}.img.xz"
xz -c -d ${COMPRESSED_IMAGE} >${DEVICE}
partprobe

cat << EOF | fdisk ${DEVICE}
o
n
p
1
8192

N
a
p
w

EOF

e2fsck -f ${DEVICE}1
resize2fs ${DEVICE}1
e2fsck -f ${DEVICE}1

status=$?
set -e

if [ $status -eq 0 ]; then
    echo "Flash Complete"
else
    echo "Flash Failed"
fi
