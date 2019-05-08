#!/bin/bash
#########################################################################
# File Name: adb_reboot.sh
# Author: WangSen
# Email: wangs_hs@163.com
# Created Time: 2017年04月14日 星期五 16时44分25秒
#########################################################################

adb wait-for-device
adb root
adb wait-for-device

adb shell "echo 0x100 > /sys/kernel/debug/spmi/spmi-0/count"
adb shell "echo 0x800 > /sys/kernel/debug/spmi/spmi-0/address"

adb shell cat /sys/kernel/debug/spmi/spmi-0/data > spmi_data.txt

echo -e "\nSo to get power on/off reason, it is get value of 0x8C0 and 0x8C5;" >> spmi_data.txt
sync
