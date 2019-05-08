#!/system/bin/sh
#########################################################################
# File Name: power_logcat.sh
#########################################################################

echo "[`date +%Y%m%d_%H-%M-%S`] ====== $0: PID of this script: $$ ======\n"

SAVE_LOG_ROOT=/data/power
SAVE_LOG_PATH="$SAVE_LOG_ROOT/`date +%Y_%m_%d_%H_%M_%S`"

function set_environment() {
    rm -rf $SAVE_LOG_ROOT
    mkdir -p $SAVE_LOG_PATH
    chmod -R 777 $SAVE_LOG_PATH

    echo test > /sys/power/wake_lock
    #echo test > /sys/power/wake_unlock
    cat /sys/power/wake_lock

    cat /proc/kmsg > $SAVE_LOG_PATH/kernel_kmsg.log &
    logcat -b kernel > $SAVE_LOG_PATH/logcat_kernel.log &
    logcat -v threadtime -b all > $SAVE_LOG_PATH/loagcat_all.log &
}

function enable_debug_log() {
    echo "8 8 8 8" > /proc/sys/kernel/printk
    echo 0 > /sys/module/qpnp_rtc/parameters/poweron_alarm
    echo 1 > /sys/module/msm_show_resume_irq/parameters/debug_mask

    echo 1 > /sys/module/kernel/parameters/initcall_debug
    echo 1 > /sys/kernel/debug/clk/debug_suspend
    echo 32 > /sys/module/msm_pm/parameters/debug_mask
    echo 8 > /sys/module/mpm_of/parameters/debug_mask
    echo 0x16 > /sys/module/smd/parameters/debug_mask
}


set_environment
enable_debug_log
echo 1000 > /sys/class/timed_output/vibrator/enable


echo "\n[`date +%Y%m%d_%H-%M-%S`] remove USB and start your test case within 10s\n"
sleep 10
echo -e "\n[`date +%H:%M:%S.%N`]\n" >> $SAVE_LOG_PATH/time.txt

cat /sys/kernel/debug/wakeup_sources > $SAVE_LOG_PATH/wakeup_sources_1.txt
dmesg -C

sleep 30

top -m 25 -d 1 -n 1 > $SAVE_LOG_PATH/top.txt
cat /sys/kernel/debug/gpio > $SAVE_LOG_PATH/gpio.txt

dmesg > $SAVE_LOG_PATH/dmesg.log
cat /sys/kernel/debug/wakeup_sources > $SAVE_LOG_PATH/wakeup_sources_2.txt

dumpsys power > $SAVE_LOG_PATH/dumpsys_power.txt

bugreport > $SAVE_LOG_PATH/bugreport.txt


echo -e "\n[`date +%H:%M:%S.%N`]\n" >> $SAVE_LOG_PATH/time.txt
sync
echo "[`date +%Y%m%d_%H-%M-%S`] ====== $0: Successful execution ! ======\n"
echo 1000 > /sys/class/timed_output/vibrator/enable
input keyevent POWER
sync
