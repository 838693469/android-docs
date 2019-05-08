#!/bin/bash
#########################################################################
# File Name: crontab.sh
# Author: WangSen
# Email: wangs_hs@163.com
# Created Time: 2017年03月14日 星期二 11时40分20秒
#########################################################################

if [ -n "$Script_PATH" ]; then
    Script_PATH=/opt/wangs
fi

Script_NAME_LIST=(
${Script_PATH}/dir_repo_sync.sh
${Script_PATH}/repo_init_Mirror.sh
)


Crontab_LOG_PATH=${Script_PATH}/crontab_log
if [ ! -d ${Crontab_LOG_PATH} ]; then
    mkdir -p ${Crontab_LOG_PATH}
fi

function crontab_run()
{
    local RUN_SHELL_PATH=$1
    local NOW_DATE=`date +%Y%m%d_%H-%M-%S`
    local LOG_NAME_temp=`basename ${RUN_SHELL_PATH}`
    local LOG_NAME=${LOG_NAME_temp%.*}_${NOW_DATE}.log

    #${RUN_SHELL_PATH} 2>&1 | tee ${Crontab_LOG_PATH}/${LOG_NAME}
    ${RUN_SHELL_PATH} >> ${Crontab_LOG_PATH}/${LOG_NAME} 2>&1
    if [ $? -ne 0 ]; then
	#sed -i '1s/^/\n====== Run Failed -> ${RUN_SHELL_PATH} ======\n\n/' ${Crontab_LOG_PATH}/${LOG_NAME}
	echo -e "\n[`date +"%Y-%m-%d %H:%M:%S"`] ====== Run Failed -> ${RUN_SHELL_PATH} ======\n" >> ${Crontab_LOG_PATH}/${LOG_NAME}
	ln -sf ${Crontab_LOG_PATH}/${LOG_NAME} ${Crontab_LOG_PATH}/FAIL-${NOW_DATE}
	return
    fi  
}

# main
for i in "${Script_NAME_LIST[@]}"
do
    crontab_run ${i}
    sync
done
