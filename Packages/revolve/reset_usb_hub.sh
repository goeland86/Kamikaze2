#!/bin/sh

echo 0 > /sys/bus/usb/devices/1-1/1-1\:1.0/1-1-port1/power/pm_qos_no_power_off
echo 0 > /sys/bus/usb/devices/1-1/1-1\:1.0/1-1-port2/power/pm_qos_no_power_off
echo 0 > /sys/bus/usb/devices/1-1/1-1\:1.0/1-1-port3/power/pm_qos_no_power_off
echo 0 > /sys/bus/usb/devices/1-1/1-1\:1.0/1-1-port4/power/pm_qos_no_power_off

echo 1 > /sys/bus/usb/devices/1-1/1-1\:1.0/1-1-port1/power/pm_qos_no_power_off
echo 1 > /sys/bus/usb/devices/1-1/1-1\:1.0/1-1-port2/power/pm_qos_no_power_off
echo 1 > /sys/bus/usb/devices/1-1/1-1\:1.0/1-1-port3/power/pm_qos_no_power_off
echo 1 > /sys/bus/usb/devices/1-1/1-1\:1.0/1-1-port4/power/pm_qos_no_power_off
