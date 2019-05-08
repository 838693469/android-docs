#!/system/bin/sh
#########################################################################
# File Name: run.sh
# Author: WangSen
# Email: wangs_hs@163.com
# Created Time: 2017年07月14日 星期五 15时24分23秒
#########################################################################

SAVE_LOG_ROOT=/data/wangs
if [ -d "${SAVE_LOG_ROOT}" ]; then
    rm -rf ${SAVE_LOG_ROOT}
fi
mkdir -p ${SAVE_LOG_ROOT}

NOW_DATE=`date +%Y%m%d_%H-%M-%S`
LOG_NAME=${NOW_DATE}.log

Script_NAME=/data/power.sh

echo "====== $0: PID of this script: $$ ======\n"

#${Script_NAME} 2>&1 | tee ${LOG_PATH}/${LOG_NAME} &
${Script_NAME} >> ${SAVE_LOG_ROOT}/${LOG_NAME} 2>&1

cat /sys/kernel/debug/gpio > ${SAVE_LOG_ROOT}/gpio_status.txt

sleep 0
sync
