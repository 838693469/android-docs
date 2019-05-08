#!/bin/bash
#########################################################################
#########################################################################

SAVE_LOG_ROOT=logs
if [ -d "${SAVE_LOG_ROOT}" ]; then
    rm -rf ${SAVE_LOG_ROOT}
fi
mkdir -p ${SAVE_LOG_ROOT}

#adb reboot
echo -e "\n[`date +"%Y-%m-%d %H:%M:%S"`] ====== begin ======\n"

adb wait-for-device
adb root
adb wait-for-device

#adb shell "mount -t debugfs none /sys/kernel/debug"
adb shell "echo 1 > /sys/kernel/debug/clk/debug_suspend"
adb shell "echo 1 > /sys/module/msm_show_resume_irq/parameters/debug_mask"
adb shell "echo 33 > /sys/module/msm_pm/parameters/debug_mask"
adb shell "echo 9 > /sys/module/mpm_of/parameters/debug_mask"

adb shell dmesg > ${SAVE_LOG_ROOT}/dmesg_1.log
adb shell cat /sys/kernel/debug/wakeup_sources > ${SAVE_LOG_ROOT}/wakeup_sources_1.txt
adb shell dmesg -C

boot_mode=`adb shell getprop ro.bootmode`
echo -e "\n Android boot Mode is : '${boot_mode}' \n"

if [ "$boot_mode" == "ffbm-01" ]; then
    adb shell "echo 0 > /sys/class/leds/lcd-backlight/brightness"
    adb shell "echo PowerManagerService.Display > /sys/power/wake_unlock"
    adb shell "echo PowerManagerService.WakeLocks > /sys/power/wake_unlock"
    adb shell "echo bluetooth_timer > /sys/power/wake_unlock"
    adb shell "echo mem > /sys/power/autosleep"
    adb shell "echo mem > /sys/power/state"
else
    echo -e "\n[`date +"%Y-%m-%d %H:%M:%S"`] ====== dev.bootcomplete ======\n"
    result=`adb shell getprop dev.bootcomplete`
    while [ "z${result}" != "z1" ]
    do
	result=`adb shell getprop dev.bootcomplete`
    done
    echo -e "\n[`date +"%Y-%m-%d %H:%M:%S"`] ====== dev.bootcomplete ======\n"

if false; then
    # /system/priv-app/CQATest
    echo -e "\n[`date +"%Y-%m-%d %H:%M:%S"`] ====== com.motorola.motocit ======\n"
    count=0
    while [ $count -lt 10 ]
    do
	motocit=`adb shell "ps -A | grep motocit | wc -l"`
	if [ $motocit -ne 0 ]; then
	    adb shell am force-stop com.motorola.motocit
	    adb shell sync
	    motocit=`adb shell "ps -A | grep motocit | wc -l"`
	    if [ $motocit -eq 0 ]; then
		break
	    fi
	else
	    count=$[${count} + 1]
	    sleep 1
	fi
    done
    echo -e "\n[`date +"%Y-%m-%d %H:%M:%S"`] ====== com.motorola.motocit ======\n"
fi

    adb shell setprop sys.screentimeout 1
fi
adb shell sync

set -x
adb shell cat /sys/class/leds/lcd-backlight/brightness
adb shell cat /sys/power/wake_unlock
adb shell cat /sys/power/autosleep
adb shell cat /sys/power/state
adb shell getprop sys.screentimeout
adb shell "ps -A | grep motocit | wc -l"
set +x

echo -e "\n[`date +"%Y-%m-%d %H:%M:%S"`] ====== end ======\n"

sleep 30
adb wait-for-device
adb root
adb wait-for-device

adb shell dmesg > ${SAVE_LOG_ROOT}/dmesg_2.log
adb shell cat /sys/kernel/debug/wakeup_sources > ${SAVE_LOG_ROOT}/wakeup_sources_2.txt

sync
