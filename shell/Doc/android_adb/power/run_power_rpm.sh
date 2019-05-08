#!/system/bin/sh
#########################################################################
# File Name: power.sh
# Author: WangSen
# Email: wangs_hs@163.com
# Created Time: 2017年07月14日 星期五 15时09分38秒
#########################################################################

echo "[`date +%Y%m%d_%H-%M-%S`] ====== $0: PID of this script: $$ ======\n"

SAVE_LOG_ROOT=/data/wangs
SAVE_LOG_PATH="$SAVE_LOG_ROOT/`date +%Y_%m_%d_%H_%M_%S`"

set_environment() {
    rm -rf $SAVE_LOG_ROOT
    mkdir -p $SAVE_LOG_PATH
    chmod -R 777 $SAVE_LOG_PATH
    chmod -R 777 $SAVE_LOG_ROOT

    cat /proc/kmsg > $SAVE_LOG_PATH/kernel_kmsg.log &
    logcat -v threadtime -b all > $SAVE_LOG_PATH/loagcat_all.log &
}

function get_system_log()
{
    local count=$1

    cat /sys/kernel/debug/wakeup_sources > ${SAVE_LOG_ROOT}/wakeup_sources_${count}.txt

    if true; then
	cat /sys/kernel/debug/rpm_stats > ${SAVE_LOG_ROOT}/rpm_stats_${count}.txt
	cat /sys/kernel/debug/rpm_master_stats > ${SAVE_LOG_ROOT}/rpm_master_stats_${count}.txt
    else
	cat /sys/power/system_sleep/stats > ${SAVE_LOG_ROOT}/rpm_stats_${count}.log
	cat /sys/power/rpmh_stats/master_stats > ${SAVE_LOG_ROOT}/rpm_master_stats_${count}.log
    fi
}

set_environment
echo 1000 > /sys/class/timed_output/vibrator/enable


get_system_log 1

echo "\n[`date +%Y%m%d_%H-%M-%S`] remove USB and start your test case within 10s\n"
# Give the below commands before disconnecting the USB and once you completed the 120 secs test then connect the USB. 
# Once the below commands are executed , make sure you start your test case within 10 secs. 
sleep 10

get_system_log 2

#adb shell "echo test > sys/power/wake_lock"
cat /d/clk/enabled_clocks > ${SAVE_LOG_ROOT}/enabled_clocks.txt



sync
echo "[`date +%Y%m%d_%H-%M-%S`] ====== $0: Successful execution ! ======\n"
echo 1000 > /sys/class/timed_output/vibrator/enable
input keyevent POWER
