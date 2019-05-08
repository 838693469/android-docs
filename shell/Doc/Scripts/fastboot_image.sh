#!/bin/bash
#########################################################################
# File Name: fastboot_image.sh
# Author: WangSen
# Email: wangs_hs@163.com
# Created Time: 2018年12月25日 星期二 11时12分15秒
#########################################################################

# -号表示开启这个选项，+表示关闭这个选项
#set -o errexit
set -o errtrace
#set -o xtrace

#******************************#
QFIL_WHITE="\\033[0m"
QFIL_GREEN="\\033[40;32m"
QFIL_YELLOW="\\033[40;33m"
QFIL_RED="\\033[40;31m"
#******************************#


function check_and_flash_image() {
    echo -e "\n------------------------------------------------------------"
    partition_name=$1
    image_name=$2

    fastboot getvar partition-size:${partition_name} 2>&1 | grep ${partition_name}
    if [ -e  "${PRODUCT_OUT}/${image_name}" ]; then
	echo -e "\n${QFIL_GREEN}[${image_name}]                             --->    Flash ${QFIL_WHITE}\n"
	fastboot flash ${partition_name} ${PRODUCT_OUT}/${image_name}
    else
	echo -e "\n${QFIL_RED}[${image_name}]                               --->    Skip ${QFIL_WHITE}\n"
	return 1
    fi
}


CHIP_ID="8937"
# Mandatory argument
if [ $# -eq 0 ]; then
    echo
    read -p "Warning: Use Default CHIP_ID='${CHIP_ID}' [Y/N]: " SIZECHECK
    case $SIZECHECK in
	"y" | "Y")
	    ;;
	"n" | "N" | *)
	    exit 1
	    ;;
    esac
else
    CHIP_ID="$1"; shift
fi

TOP_DIR=`pwd`
PRODUCT_OUT=${TOP_DIR}

echo -e "\n============================================================"
echo "CHIP_ID=$CHIP_ID"
echo "PRODUCT_OUT=$PRODUCT_OUT"
echo -e "==============================================================\n"


fastboot getvar platform
down_platform=`fastboot getvar platform 2>&1 | grep platform | awk '{print $NF}'`
if [ $down_platform != $CHIP_ID ]; then
    echo -ne "\n${QFIL_RED}ERROR: ${QFIL_WHITE}"
    read -p "The platform information is Incorrect [Ctrl + C] ?"
fi


echo -e "\n------------------------------------------------------------"
fastboot devices
echo -e "\n${QFIL_YELLOW}Warning: fastboot oem enable-unlock-once ${QFIL_WHITE}"
fastboot oem enable-unlock-once
#fastboot erase config
echo -e "\n------------------------------------------------------------\n"


###### BP ######
check_and_flash_image dsp ${CHIP_ID}_adspso.bin
check_and_flash_image cmnlib ${CHIP_ID}_cmnlib_30.mbn
check_and_flash_image cmnlib64 ${CHIP_ID}_cmnlib64_30.mbn
check_and_flash_image devcfg ${CHIP_ID}_devcfg.mbn
check_and_flash_image keymaster ${CHIP_ID}_keymaster64.mbn
check_and_flash_image sec ${CHIP_ID}_sec.dat
check_and_flash_image sbl1 ${CHIP_ID}_sbl1.mbn
check_and_flash_image rpm ${CHIP_ID}_rpm.mbn
check_and_flash_image tz ${CHIP_ID}_tz.mbn
check_and_flash_image modem ${CHIP_ID}_NON-HLOS.bin


check_and_flash_image aboot ${CHIP_ID}_emmc_appsboot.mbn
check_and_flash_image boot boot.img

check_and_flash_image system system.img
check_and_flash_image vendor vendor.img
check_and_flash_image recovery recovery.img

check_and_flash_image cache cache.img
check_and_flash_image userdata userdata.img

#check_and_flash_image persist persist.img
check_and_flash_image splash splash.img
check_and_flash_image mdtp mdtp.img


###### ASUS ######
check_and_flash_image APD APD.img
check_and_flash_image asusfw asusfw.img
check_and_flash_image logo logo.bin
check_and_flash_image xrom xrom.img


echo -e "\n==============================================================\n"
sync
read -p "Warning: Please confirm flash complete, ready to restart [Continue] ?"
#fastboot oem reboot-recovery-wipe
fastboot reboot
