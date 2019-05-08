#!/system/bin/sh
#########################################################################

echo "[`date +%Y%m%d_%H-%M-%S`] ====== $0: PID of this script: $$ ======\n"

SAVE_LOG_ROOT=/data/power
SAVE_LOG_PATH="$SAVE_LOG_ROOT/`date +%Y_%m_%d_%H_%M_%S`"

function set_environment() {
    # check mount file
    umask 0;
    sync

    rm -rf $SAVE_LOG_ROOT
    # create savelog folder (UTC)
    mkdir -p $SAVE_LOG_PATH
    chmod -R 777 $SAVE_LOG_PATH
    chmod -R 777 $SAVE_LOG_ROOT
}

function enable_debug_log() {
    echo 0 > /sys/module/qpnp_rtc/parameters/poweron_alarm
    echo 1 > /sys/module/msm_show_resume_irq/parameters/debug_mask

    echo 1 > /sys/module/kernel/parameters/initcall_debug
    echo 1 > /sys/kernel/debug/clk/debug_suspend
    echo 33 > /sys/module/msm_pm/parameters/debug_mask
    echo 9 > /sys/module/mpm_of/parameters/debug_mask
    echo 0x16 > /sys/module/smd/parameters/debug_mask
}

function get_system_config() {
    # save property
    getprop > $SAVE_LOG_PATH/getprop.txt

    # save cmdline
    cat /proc/cmdline > $SAVE_LOG_PATH/cmdline.txt

    # save mount table
    cat /proc/mounts > $SAVE_LOG_PATH/mounts.txt

    # save space used status
    df > $SAVE_LOG_PATH/df.txt

    # save network info
    cat /proc/net/route > $SAVE_LOG_PATH/route.txt
    ifconfig -a > $SAVE_LOG_PATH/ifconfig.txt

    # save software version
    echo "AP_VER: `getprop ro.build.display.id`" > $SAVE_LOG_PATH/version.txt
    echo "CP_VER: `getprop gsm.version.baseband`" >> $SAVE_LOG_PATH/version.txt
    echo "BT_VER: `getprop bt.version.driver`" >> $SAVE_LOG_PATH/version.txt
    echo "WIFI_VER: `getprop wifi.version.driver`" >> $SAVE_LOG_PATH/version.txt
    echo "GPS_VER: `getprop gps.version.driver`" >> $SAVE_LOG_PATH/version.txt
    echo "BUILD_DATE: `getprop ro.build.date`" >> $SAVE_LOG_PATH/version.txt

    # save load kernel modules
    lsmod > $SAVE_LOG_PATH/lsmod.txt

    # save process now
    ps > $SAVE_LOG_PATH/ps.txt
    ps -t -p > $SAVE_LOG_PATH/ps_thread.txt

}

function get_system_log()
{
    local count=$1

    echo "###### `date +%Y-%m-%d_%H-%M-%S` ######" > $SAVE_LOG_PATH/dmesg_${count}.log
    dmesg >> $SAVE_LOG_PATH/dmesg_${count}.log
    dmesg -C
    logcat -b kernel -d > $SAVE_LOG_PATH/logcat_kernel_${count}.log
    logcat -b kernel -c

    echo "###### `date +%Y-%m-%d_%H-%M-%S` ######" > $SAVE_LOG_PATH/wakeup_sources_${count}.txt
    cat /sys/kernel/debug/wakeup_sources >> $SAVE_LOG_PATH/wakeup_sources_${count}.txt

    if true; then
	cat /sys/kernel/debug/rpm_stats > ${SAVE_LOG_ROOT}/rpm_stats_${count}.txt
	cat /sys/kernel/debug/rpm_master_stats > ${SAVE_LOG_ROOT}/rpm_master_stats_${count}.txt
    else
	cat /sys/power/system_sleep/stats > ${SAVE_LOG_ROOT}/rpm_stats_${count}.log
	cat /sys/power/rpmh_stats/master_stats > ${SAVE_LOG_ROOT}/rpm_master_stats_${count}.log
    fi
}


set_environment
enable_debug_log

get_system_config
echo 1000 > /sys/class/timed_output/vibrator/enable


get_system_log 1


echo "###### `date +%Y-%m-%d_%H-%M-%S` ######" > $SAVE_LOG_PATH/kernel_kmsg.log
cat /proc/kmsg >> $SAVE_LOG_PATH/kernel_kmsg.log &

echo "###### `date +%Y-%m-%d_%H-%M-%S` ######" > $SAVE_LOG_PATH/loagcat_all.log
logcat -v threadtime -b all >> $SAVE_LOG_PATH/loagcat_all.log &

#echo "###### `date +%Y-%m-%d_%H-%M-%S` ######" > $SAVE_LOG_PATH/bugreport.log
#bugreport >> $SAVE_LOG_PATH/bugreport.log &

if [ -e /data/powertop ]; then
    echo "###### `date +%Y-%m-%d_%H-%M-%S` ######" > $SAVE_LOG_PATH/powertop.log
    chmod 777 /data/powertop
    /data/powertop -r -d -t 10 >> $SAVE_LOG_PATH/powertop.log &
fi

#echo "###### `date +%Y-%m-%d_%H-%M-%S` ######" > $SAVE_LOG_PATH/top.log
#top -m 10 -d 1 -n 1 -t >> top.log &


sleep 60


get_system_log 2


echo "[`date +%Y%m%d_%H-%M-%S`] ====== $0: Successful execution ! ======\n"
echo 1000 > /sys/class/timed_output/vibrator/enable
sync
