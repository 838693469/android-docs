#!/bin/bash
#########################################################################
# File Name: check_ps.sh
# Author: WangSen
# Email: wangs_hs@163.com
# Created Time: 2017年03月14日 星期二 14时34分29秒
#########################################################################

# sshfs ubuntu@10.20.32.141:/WorkSpace/Tools/server /opt/wangs

export Script_PATH=/opt/wangs

Crontab_LOG_PATH=${Script_PATH}/crontab_log
if [ ! -d ${Crontab_LOG_PATH} ]; then
    mkdir -p ${Crontab_LOG_PATH}
fi

function check_df()
{
    local check_name=${1%/*}
    local count=`df |grep $check_name |grep -v "grep" |wc -l`
    if [ $count -eq 0 ]; then
	echo -e "sshfs ubuntu@10.20.32.141:/WorkSpace/Tools/server /opt/wangs \n" >> ${Crontab_LOG_PATH}/check.log
	echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ====== No check to -> $check_name $count ======\n" >> ${Crontab_LOG_PATH}/check.log
	exit 1
    fi

}

function check_ps()
{
    local self_processes=`basename $1`
    local log_name=${self_processes%.*}.log
    local count=`ps -ef |grep $self_processes |grep -v "grep" |wc -l`
    if [ 0 -ne $count ]; then
	echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ====== Run Failed -> $self_processes $count ======\n" >> ${Crontab_LOG_PATH}/$log_name
	exit 1
    fi
}

# Main
check_df ${Script_PATH}

check_ps ${Script_PATH}/self_crontab.sh
${Script_PATH}/self_crontab.sh
sync
