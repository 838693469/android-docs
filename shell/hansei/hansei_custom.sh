#!/bin/bash
# hansei.py parse for rpm resource from ramdump(msm8937 chipset done)
# owner:hongwei.di
# arg1: qualcomm amss_codes root dir
# output: ${pwd}/output/

TOP_DIR=`pwd`
HANSEI_DIR="$1"
HANSEI_CUSTOM=${HANSEI_DIR}/RPM.BF.2.2/rpm_proc/core/bsp/rpm/scripts/hansei
RPM_ELF=/work/asus/versions/sku1_p/0311-ramdump/RPM_AAAAANAAR.elf
RAMDUMP_DIR=/work/asus/versions/sku1_p/0311-ramdump/Port_COM41

echo -e "clear output before hansei parse\n"

rm -rf ${TOP_DIR}/output/

python ${HANSEI_CUSTOM}/hansei.py --elf ${RPM_ELF} ${RAMDUMP_DIR}/CODERAM.BIN ${RAMDUMP_DIR}/DATARAM.BIN ${RAMDUMP_DIR}/MSGRAM.BIN -o ${TOP_DIR}/output/
