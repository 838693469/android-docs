#!/bin/bash
#########################################################################
# File Name: adb_debug_charger.sh
#########################################################################

adb wait-for-device
adb root
adb wait-for-device

boot_mode=`adb shell getprop ro.bootmode`
echo -e "\n Android boot Mode is : '${boot_mode}' \n"

adb shell dmesg > dmesg.log

#adb shell "echo 8 > /proc/sys/kernel/printk"
adb shell "echo -n 'file phy-msm-usb.c +p' > /sys/kernel/debug/dynamic_debug/control"
adb shell "echo -n 'file ci13xxx_msm.c +p' > /sys/kernel/debug/dynamic_debug/control"
adb shell "echo -n 'file qpnp-smbcharger.c +p' > /sys/kernel/debug/dynamic_debug/control"
#adb shell "echo 'file qpnp-fg.c +p' > /sys/kernel/debug/dynamic_debug/control"

echo -e "\n----------------------------------------------------\n"
adb shell cat /sys/class/power_supply/battery/uevent
echo -e "\n----------------------------------------------------\n"
adb shell cat /sys/class/power_supply/bms/uevent
echo -e "\n----------------------------------------------------\n"
adb shell cat /sys/class/power_supply/usb/uevent
echo -e "\n----------------------------------------------------\n"

if true ; then
echo -e "\n----------------------------------------------------\n"
adb shell cat /proc/aging_power_test/Charging_ChargeState
adb shell cat /proc/aging_power_test/Charging_DemoApp_ChargeState
echo -e "\n----------------------------------------------------\n"
adb shell cat /sys/devices/soc/qpnp-fg-17/Charging_batterylife
echo -e "\n----------------------------------------------------\n"
adb shell cat /sys/class/switch/usb_connector/state
echo -e "\n----------------------------------------------------\n"
adb shell cat /sys/class/switch/battery/name
echo -e "\n----------------------------------------------------\n"
#adb shell cat /proc/android_touch/SMWP
echo -e "\n----------------------------------------------------\n"
fi

#adb shell cat /sys/kernel/debug/gpio > gpio.txt

adb shell logcat -v time -b kernel -d > logcat_kernel.log
sync
