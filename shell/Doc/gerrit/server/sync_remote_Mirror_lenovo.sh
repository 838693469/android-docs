#!/bin/bash
#########################################################################
# File Name: repo_init.sh
# Author: WangSen
# Email: wangs_hs@163.com
# Created Time: 2017年03月16日 星期四 17时02分09秒
#########################################################################

# sshfs archermind@10.20.32.143:/data/HQProjectMirror /HQProjectMirror

#Source_PATH=/media/ubuntu/WorkSpace/Mediatek/Huaqin
Source_PATH=/WorkSpace/Huaqin
Mirror_PATH=/HQProjectMirror/Projects


Branch_Manifest_NAME=(
A6097_LENOVO_master
)
#A6000_LENOVO_master
#A6090_LENOVO
#A600x_LENOVO_SMT
#A609x_LENOVO_SMT
#A6096N_LENOVO_ATT
#A600x_driveronly
#A609x_driveronly
#A6090_LENOVO_NEC
#A60XX_LENOVO_WIFI_MP
#A6096_LENOVO_SMT
#A6097_LENOVO_SOFTBANK_SMT
#A6097_LENOVO_master
#A600X_LENOVO_OTA
#A609X_LENOVO_OTA
#A600X_YZ_SMT
#A6095_LENOVO_MP

#ZA2060_lenovo_master
#A1960_lenovo_MP

#msm8909-la-3-0-1_dev
#ZQ6005_LENOVO_SMT


Repo_init_cmds="repo init --no-repo-verify -u ssh://WB20174643@61.152.125.66:29418/manifest "

#****************************************#
CPU_Processor=`cat /proc/cpuinfo |grep processor | wc -l`
thread_jobs=$[${CPU_Processor} + 8]
echo -e "\n====== thread_jobs=${thread_jobs} ======\n"
#****************************************#

function check_df()
{
    local check_name=${1%/*}
    local count=`df |grep $check_name |grep -v "grep" |wc -l`
    if [ $count -eq 0 ]; then
	echo -e "sshfs archermind@10.20.32.143:/data/HQProjectMirror /HQProjectMirror \n"
	echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ====== No check to -> $check_name $count ======\n"
	exit 1
    fi

}

function repo_clean()
{
    echo -e "\n[`date +"%Y-%m-%d %H:%M:%S"`] ====== <Clear> all changes and exceptions ======\n"

    repo forall -v -c '
	if [ -e ".git/index.lock" ]; then
	    rm -f .git/index.lock
	fi
	if [ ! -s ".git/ORIG_HEAD" ]; then
	    rm -f .git/ORIG_HEAD
	fi
    ' -j${thread_jobs}

    repo forall -v -c 'git rebase --abort' -j${thread_jobs}
    repo forall -v -c 'git reset --hard' -j${thread_jobs}
    repo forall -v -c 'git clean -df' -j${thread_jobs}
    if [ $? -ne 0 ]; then
	echo -e "\n[`date +"%Y-%m-%d %H:%M:%S"`] ====== forall result is:     Failure ======\n"
	exit -1
    fi
    sync
}

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

function repo_mirror_run()
{
    local Branch_NAME=$1

    # sync branch mirror
    if true ; then
	echo -e "\n[`date +"%Y-%m-%d %H:%M:%S"`] ====== repo init '${Branch_NAME}.xml' -> mirror ======\n"
	cd $Mirror_PATH
	if [ ! -d "$Mirror_PATH/.repo" ]; then
	    $Repo_init_cmds -m ${Branch_NAME}.xml --mirror
	    if [ $? -ne 0 ]; then
		echo -e "\n[`date +"%Y-%m-%d %H:%M:%S"`] ====== init result is:     Failure ======\n"
		exit -1
	    fi
	#else
	#    $Repo_init_cmds -m ${Branch_NAME}.xml
	#    sync
	fi
	repo_sync
	echo -e "\n[`date +"%Y-%m-%d %H:%M:%S"`] ====== sync mirror is:     Successfully ======\n"
    fi

    # sync branch code
    if true ; then
	echo -e "\n[`date +"%Y-%m-%d %H:%M:%S"`] ====== repo init '${Branch_NAME}.xml' -> code ======\n"
	if [ ! -d "$Source_PATH/$Branch_NAME" ]; then
	    mkdir -p $Source_PATH/$Branch_NAME
	    cd $Source_PATH/$Branch_NAME

	    $Repo_init_cmds -m ${Branch_NAME}.xml --reference=${Mirror_PATH}
	    if [ $? -ne 0 ]; then
		echo -e "\n[`date +"%Y-%m-%d %H:%M:%S"`] ====== init result is:     Failure ======\n"
		exit -1
	    fi
	    sync
	else
	    cd $Source_PATH/$Branch_NAME
	    repo_clean
	fi
	repo_sync
	echo -e "\n[`date +"%Y-%m-%d %H:%M:%S"`] ====== sync local is:     Successfully ======\n"
	sync
    fi
}

# main
for i in "${Branch_Manifest_NAME[@]}"
do
    #check_df ${Mirror_PATH}

    repo_mirror_run ${i}
    sync
done
sync
