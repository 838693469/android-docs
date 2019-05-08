#!/system/bin/sh
#########################################################################
#########################################################################

echo "[`date +%Y%m%d_%H-%M-%S`] ====== $0: PID of this script: $$ ======\n"

SAVE_LOG_ROOT=/data/power
SAVE_LOG_PATH="$SAVE_LOG_ROOT/`date +%Y_%m_%d_%H_%M_%S`"

function set_environment() {
    rm -rf $SAVE_LOG_ROOT
    mkdir -p $SAVE_LOG_PATH
    chmod -R 777 $SAVE_LOG_PATH
}

function enable_debug_log() {
    echo "8 8 8 8" > /proc/sys/kernel/printk
    echo 0 > /sys/module/qpnp_rtc/parameters/poweron_alarm
    echo 1 > /sys/module/msm_show_resume_irq/parameters/debug_mask

    #echo 1 > /sys/module/kernel/parameters/initcall_debug
    echo 1 > /sys/kernel/debug/clk/debug_suspend
    #echo 32 > /sys/module/msm_pm/parameters/debug_mask
    echo 11 > /sys/module/mpm_of/parameters/debug_mask
    #echo 0x16 > /sys/module/smd/parameters/debug_mask

    dmesg -C
    logcat -c

    cat /proc/kmsg > $SAVE_LOG_PATH/kernel_kmsg.log &
    logcat -b kernel > $SAVE_LOG_PATH/logcat_kernel.log &
    logcat -v threadtime -b all > $SAVE_LOG_PATH/loagcat_all.log &
}


function read_dir() {
    for file in `ls $1` #注意此处这是两个反引号，表示运行系统命令
    do
	if [ -d $1"/"$file ]; then
	    read_dir $1"/"$file
	else
	    echo -ne "\n${1}/${file} : " >> $SAVE_LOG_PATH/lpm_levels.txt
	    cat $1"/"$file >> $SAVE_LOG_PATH/lpm_levels.txt
	fi
    done
}


set_environment
enable_debug_log
echo 1000 > /sys/class/timed_output/vibrator/enable

echo test > /sys/power/wake_lock
#echo test > /sys/power/wake_unlock
cat /sys/power/wake_lock


echo "\n[`date +%Y%m%d_%H-%M-%S`] remove USB and start your test case within 10s\n"
#sleep 10
echo -e "\n[`date +%H:%M:%S.%N`]\n" >> $SAVE_LOG_PATH/time.txt


count=0
while true
do
    #count=$[${count} + 1]
    count=$(( $count + 1 ))

    sleep 2
    echo "$(date)\n $(cat /d/clk/enabled_clocks)\n=================================================" >> $SAVE_LOG_PATH/clock.txt

    if [ $count -ge 90 ]; then
	break
    fi
done


dmesg > $SAVE_LOG_PATH/dmesg.log
bugreport > $SAVE_LOG_PATH/bugreport.txt
logcat -d > $SAVE_LOG_PATH/logcat.log

echo -e "\n[`date +%H:%M:%S.%N`]\n" >> $SAVE_LOG_PATH/time.txt
sync
echo "[`date +%Y%m%d_%H-%M-%S`] ====== $0: Successful execution ! ======\n"
echo 1000 > /sys/class/timed_output/vibrator/enable
input keyevent POWER
sync
