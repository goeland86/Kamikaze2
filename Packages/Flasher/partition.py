#! /usr/bin/python

import parted

target = "/dev/mmcblk0"

device = parted.getDevice(target)
disk = parted.Disk(device)

if len(disk.partitions) == 2:
        print "disk has 2 partitions - leaving it alone"
        print "storage partition ready at {}".format(disk.partitions[1].path)

elif len(disk.partitions) == 1:
        print "disk has 1 partition - creating storage partition"
        basePart = disk.partitions[0]
        storageStart = basePart.geometry.end + 1
        storageLength = device.getLength() - storageStart
        print "current partition runs from {} to {}, new one will be {} to {}".format(basePart.geometry.start, basePart.geometry.end, storageStart, storageStart + storageLength)

        storageGeometry = parted.Geometry(device=device, start=storageStart, length=device.getLength() - storageStart)
        storageFS = parted.FileSystem(type="ext4", geometry=storageGeometry)
        storagePartition = parted.Partition(disk=disk, type=parted.PARTITION_NORMAL, fs=storageFS, geometry=storageGeometry)

        disk.addPartition(partition=storagePartition, constraint=device.optimalAlignedConstraint)

        print "storage partition ready at {}".format(storagePartition.path)

else:
        print "unrecognized disk configuration"

disk.commit()
