#!/bin/bash
#########################################################################
# File Name: license_file.sh
# Author: WangSen
# Email: wangs_hs@163.com
# Created Time: 2017年04月14日 星期五 14时11分57秒
#########################################################################

AMSS_PATH=/opt/wangs

Script_FILE_LIST=(
RPM.BF.2.4/rpm_proc/build/build_8953.sh
RPM.BF.2.2/rpm_proc/build/build_8937_8917.sh
BOOT.BF.3.3/boot_images/build/ms/setenv.sh
BOOT.BF.3.3/boot_images/build/ms/build.sh
)


# main
for i in "${Script_FILE_LIST[@]}"
do
    echo -e "Modify LM_LICENSE_FILE -> ${i} \n"
    sed -i '/LM_LICENSE_FILE/ s/192.168.132.222/10.20.32.143/g' ${AMSS_PATH}/${i}
    sync
done
