#!/bin/bash
#########################################################################
# File Name: dir_repo_sync.sh
# Author: WangSen
# Email: wangs_hs@163.com
# Created Time: 2017年03月14日 星期二 11时10分00秒
#########################################################################

#Source_PATH=`pwd`
Source_PATH=/data/HQProjectMirror


#****************************************#
CPU_Processor=`cat /proc/cpuinfo |grep processor | wc -l`
thread_jobs=$[${CPU_Processor} + 4]
echo -e "\n====== thread_jobs=${thread_jobs} ======\n"
#****************************************#

function repo_sync()
{
    if [ ! -z "$1" ] && [ "$1" = "all" ]; then
	echo -e "\n====== fetch <All> branch from server ======\n"
	sync_cmds="--no-repo-verify -j${thread_jobs}"
    else
	echo -e "\n====== fetch <Only Current> branch from server ======\n"
	sync_cmds="--no-repo-verify -c -j${thread_jobs}"
    fi

    local count=10
    repo sync ${sync_cmds}
    while [ $? -ne 0 ] 
    do
	if [ ${count} -lt 1 ]; then
	    break;
	fi
	count=$[${count} - 1]

	echo -e "\n[`date +"%Y-%m-%d %H:%M:%S"`] ====== repo sync Failed -> ${sync_cmds} ======\n"
	sleep 1
	repo sync ${sync_cmds}
    done
    if [ $? -ne 0 ]; then
	echo -e "\n[`date +"%Y-%m-%d %H:%M:%S"`] ====== sync result is:     Failure ======\n"
	exit -1
    fi
    sync
}


for dir_repo in `ls $Source_PATH`
do
    if [ -d "${Source_PATH}/$dir_repo" ]; then
	echo -e "\n[`date +"%Y-%m-%d %H:%M:%S"`] ====== Run into -> ${Source_PATH}/$dir_repo ======\n"
	cd ${Source_PATH}/$dir_repo

	#repo sync
	echo -e "====== repo sync source -> $dir_repo ======\n"
	if [ "$dir_repo" = "Projects" ]; then
	    repo_sync all
	else
	    repo_sync
	fi
	echo -e "\n[`date +"%Y-%m-%d %H:%M:%S"`] ====== sync result is:     Successfully ======\n"
    else
	echo -e "\n[`date +"%Y-%m-%d %H:%M:%S"`] ====== Not Dir -> ${Source_PATH}/$dir_repo  ======\n"
    fi
done
sync
