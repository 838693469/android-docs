#!/bin/bash
#########################################################################
# File Name: test.sh
# Author: WangSen
# Email: wangs_hs@163.com
# Created Time: 2017年03月14日 星期二 14时25分34秒
#########################################################################

function git_clone()
{
    if [ $# -ne 2 ]; then
	echo "error"
	exit 1
    fi

    local path_name=$1
    local remote_name=$2

    echo "${path_name%/*}"
    echo "${path_name##*/}"
}

remote_name=(
"bootable/bootloader/lk msm8953_64_N/kernel/lk"
"1 2"
)

for i in "${remote_name[@]}"
do
    echo ${i}
    git_clone ${i}
done

for i in `seq 1 100`
do
    sleep 1
    sync
done
