#!/system/bin/sh
#########################################################################
# File Name: power_logcat.sh
# Author: WangSen
# Email: wangs_hs@163.com
# Created Time: 2016年09月27日 星期二 14时13分04秒
#########################################################################

echo "[`date +%Y%m%d_%H-%M-%S`] ====== $0: PID of this script: $$ ======\n"

SAVE_LOG_ROOT=/data/wangs
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
echo 1000 > /sys/class/timed_output/vibrator/enable


echo "\n[`date +%Y%m%d_%H-%M-%S`] remove USB and start your test case within 10s\n"
sleep 10
echo -e "\n[`date +%H:%M:%S.%N`]\n" >> $SAVE_LOG_PATH/time.txt

echo reset > /sys/kernel/debug/lpm_stats/stats
echo reset > /sys/kernel/debug/lpm_stats/suspend

sleep 30

cat /sys/kernel/debug/lpm_stats/stats > $SAVE_LOG_PATH/lpm_stats.txt

echo "###### `date +%Y-%m-%d_%H:%M:%S.%N` ######" > $SAVE_LOG_PATH/lpm_levels.txt
read_dir "/sys/module/lpm_levels/perf"

bugreport > $SAVE_LOG_PATH/bugreport.txt


echo -e "\n[`date +%H:%M:%S.%N`]\n" >> $SAVE_LOG_PATH/time.txt
sync
echo "[`date +%Y%m%d_%H-%M-%S`] ====== $0: Successful execution ! ======\n"
echo 1000 > /sys/class/timed_output/vibrator/enable
input keyevent POWER
sync
