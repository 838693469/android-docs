#!/bin/bash
#########################################################################
# File Name: repo_sync.sh
# Author: WangSen
# Email: wangs_hs@163.com
# Created Time: 2018年12月19日 星期三 11时20分46秒
#########################################################################

project_list_device=(
"vendor/nxp/opensource/interfaces/nfc"
"vendor/nxp/opensource/commonsys/external/libnfc-nci"
"vendor/nxp/opensource/commonsys/frameworks"
"vendor/nxp/opensource/halimpl"
"vendor/nxp/opensource/hidlimpl"
"vendor/nxp/opensource/commonsys/packages/apps/Nfc"
)

for i in "${project_list_device[@]}"
do
    echo -e "######    ${i}    ######\n"
    repo sync --no-repo-verify -j16 -c $i
    sync
done
