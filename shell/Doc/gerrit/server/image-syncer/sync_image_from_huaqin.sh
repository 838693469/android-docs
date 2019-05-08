#!/bin/bash

export work_dir="/work/image-syncer"
export image_dir="/work/version"
export log=$(echo "${work_dir}/sync_log.txt")


test_rsync=`ps -A | grep rsync`
if [[ -n ${test_rsync} ]]; then
    #如果有rsync进程在执行，程序退出
    echo $(date +"%Y-%m-%d %H:%M:%S") rsync is running, exit. | tee -a $log
    exit
else
    #如果没有rsync进程运行，启动rsync,开始同步版本
    echo $(date +"%Y-%m-%d %H:%M:%S") rsync is not running! | tee -a $log
    echo $(date +"%Y-%m-%d %H:%M:%S") start rsync! | tee -a $log
    time rsync -avzuP --delete --progress --password-file=${work_dir}/rsyncd.secrets root@version.huaqin.com::version ${image_dir}
fi

