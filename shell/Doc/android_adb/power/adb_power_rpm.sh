#!/bin/bash
#########################################################################

SAVE_LOG_ROOT=logs
if [ -d "${SAVE_LOG_ROOT}" ]; then
    rm -rf ${SAVE_LOG_ROOT}
fi
mkdir -p ${SAVE_LOG_ROOT}

echo -e "\n[`date +"%Y-%m-%d %H:%M:%S"`] ====== begin ======\n"

adb wait-for-device
adb root
adb wait-for-device


function get_system_log()
{
    local count=$1

    if true; then
	adb shell cat /sys/kernel/debug/rpm_stats > ${SAVE_LOG_ROOT}/rpm_stats_${count}.txt
	adb shell cat /sys/kernel/debug/rpm_master_stats > ${SAVE_LOG_ROOT}/rpm_master_stats_${count}.txt
    else
	adb shell cat /sys/power/system_sleep/stats > ${SAVE_LOG_ROOT}/rpm_stats_${count}.log
	adb shell cat /sys/power/rpmh_stats/master_stats > ${SAVE_LOG_ROOT}/rpm_master_stats_${count}.log
    fi
    adb shell "echo 1000 > /sys/class/timed_output/vibrator/enable"
}



adb shell "echo test > /sys/power/wake_lock"
adb shell cat /sys/power/wake_lock


get_system_log 1

echo -en "\n准备倒数10秒： "
for i in $(seq 10 -1 0)
do
    if [ $i -eq 9 ]; then
	echo -en "\b\b09"
    else
	echo -en "\b$i"
    fi
    sleep 1
done

adb wait-for-device
get_system_log 2

adb shell dumpsys power > ${SAVE_LOG_ROOT}/dumpsys_power.log

sync
echo -e "\n[`date +%Y%m%d_%H-%M-%S`] ====== $0: Successful execution ! ======\n"
sync
