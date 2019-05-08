#!/system/bin/sh
#########################################################################
# File Name: adb_run.sh
# Author: WangSen
# Email: wangs_hs@163.com
# Created Time: 2017年03月20日 星期一 17时30分43秒
#########################################################################

Script_PATH=/data
Script_NAME=${Script_PATH}/audio_power.sh

LOG_PATH=/data/wangs
if [ ! -d ${LOG_PATH} ]; then
    mkdir -p ${LOG_PATH}
fi

NOW_DATE=`date +%Y%m%d_%H-%M-%S`
LOG_NAME_temp=`basename ${Script_NAME}`
LOG_NAME=${LOG_NAME_temp%.*}_${NOW_DATE}.log

echo "====== $0: PID of this script: $$ ======\n"

#${Script_NAME} 2>&1 | tee ${LOG_PATH}/${LOG_NAME} &
${Script_NAME} >> ${LOG_PATH}/${LOG_NAME} 2>&1 &
sync
