# Umikaze
Umikaze image generation, based on Ubuntu

# Changelog:
2.2.1 - *** Work In Progress ***
 - OctoPrint 1.3.11
 - Support for Revolve board

# Notes for Revolve
The revolve boards were shipped out with 
a u-boot that does not boot from USB stick (Mass storage) if one is present. 
Therefore, it is necessary to stop u-boot and write the following: 
```
usb start
setenv bootargs console=ttyS0,115200n8 rootdelay=5 root=/dev/sda1 rw
load usb 0:1 0x82000000 /boot/vmlinuz-4.19.50-ti-r20
load usb 0:1 0x88000000 /boot/dtbs/4.19.50-ti-r20/am335x-revolve.dtb
bootz 0x82000000 - 0x88000000
```

Once booted from UMS, the image can be flashed into eMMC by doing: 
``` 
cd /usr/src/Umikaze/Packages/revolve/
./usb.sh
```


Current issues for running on Revolve:
 - depmod -a needs to be run on the board. 
 
