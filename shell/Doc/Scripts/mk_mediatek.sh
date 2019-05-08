#!/bin/bash
#########################################################################
# File Name: mk.sh
# Author: WangSen
# Email: wangs_hs@163.com
# Created Time: 2017年12月14日 星期四 17时47分31秒
#########################################################################

if [ -z $1 ]; then
    echo -e "\nPlease enter the compiler parameters such as: [bootimage] \n"
    exit
fi

RUN_lunch="lunch full_hq8163_tb_a8_n-userdebug"
RUN_Compile="./mk -o=TARGET_BUILD_VARIANT=userdebug hq8163_tb_a8_n a2060[row] $1"
RUN_sign="./vendor/mediatek/proprietary/scripts/sign-image/sign_image.sh"

source ./build/envsetup.sh

echo -e "\n###### $RUN_lunch ######\n"
$RUN_lunch
sync

echo -e "\n###### $RUN_Compile ######\n"
$RUN_Compile
sync

echo -e "\n###### $RUN_sign ######\n"
$RUN_sign
sync
