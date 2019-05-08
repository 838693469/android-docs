#!/bin/bash
#########################################################################
# File Name: mk.sh
# Author: WangSen
# Email: wangs_hs@163.com
# Created Time: 2018年01月26日 星期五 15时29分14秒
#########################################################################

AP_TOP_DIR=`pwd`
None_HLOS=/WorkSpace/BYD_HS501/AMSS
LA_UM_PATH=${None_HLOS}/LA.UM.5.6
MSM_DEVICE_LA_DIR=${None_HLOS}/MSM8953.LA.2.0

export TARGET=msm8953_64
export VARIANT=userdebug

export TOOLS_PATH=/WorkSpace/Tools/qcom_Tools
Copy_MBN_Script=${TOOLS_PATH}/Scripts/copy-all-img.sh
Copy_ELF_Script=${TOOLS_PATH}/Scripts/copy-all-elf.sh


function check_gcc_version() {
    local required_version='4.8.1'
    local gcc_version_str=`gcc --version 2>&1 | grep '^gcc .*[ "]4\.[0-9][\. "$$]'`
    local gcc_version=$(expr "$gcc_version_str" : '.*\(4\.[0-9]\.[0-9]\).*')
    if [ "$gcc_version" \< "$required_version" ]
    then
	echo "You are attempting to build with the incorrect version of gcc."
	echo -e "Your version is: $gcc_version_str."
	echo "The required version is: $required_version."
	echo "Please update gcc version with ${TOOLS_PATH}/Scripts/install_gcc4-8-1.sh"
	exit 1
    fi
}

############################################################################
check_gcc_version

source ${TOOLS_PATH}/myenviron_amss.sh
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo -e "\n[`date +"%Y-%m-%d %H:%M:%S"`] ====== [myenviron_amss.sh] Execute result is:     Failure ======\n"
    exit 1
fi

if [ $# -ne 0 ]; then
    cd ${AP_TOP_DIR}
    echo -e "\n${QFIL_YELLOW}[`date +"%Y-%m-%d %H:%M:%S"`] ====== Build android: < ${TARGET}-${VARIANT} $@ > ======${QFIL_WHITE}\n"
    ${TOOLS_PATH}/Scripts/make_android.sh ${TARGET}  $@
    exit 0
fi
############################################################################

build_allhols() {
    echo -e "\n${QFIL_YELLOW}====== Build all HLOS: <$None_HLOS> ======${QFIL_WHITE}\n"

    cd $ANDROID_PRODUCT_OUT
    if [ ! -f "system.img" ]; then
	echo -e "\n${QFIL_RED}[`date +"%Y-%m-%d %H:%M:%S"`] ====== [${FUNCNAME}] Execute result is:     Failure ======${QFIL_WHITE}\n"
	exit 1
    fi

    rm -rf ${LA_UM_PATH}/LINUX/android
    ln -vs ${AP_TOP_DIR} ${LA_UM_PATH}/LINUX/android
    sync

    # Build HLOS images
    rm -rf ${MSM_DEVICE_LA_DIR}/common/build/bin
    sync

    #   build.py <mode>
    #   Examples:
    #	    build.py --nonhlos  (generates NON_HLOS.bin alone)
    #	    build.py --hlos     (generates sparse images if rawprogram0.xml exists)
    #	    build.py            (generates NON-HLOS.bin and sparse images)
    cd ${MSM_DEVICE_LA_DIR}/common/build
    python ./build.py
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
	echo -e "\n${QFIL_RED}[`date +"%Y-%m-%d %H:%M:%S"`] ====== [${FUNCNAME}] Execute result is:     Failure ======${QFIL_WHITE}\n"
	exit 1
    fi
}

build_zip_images() {
    echo -e "\n${QFIL_YELLOW}====== Build TO GENERATE DOWNLOAD PACKAGE ======${QFIL_WHITE}\n"
    local now_date=`date +%Y%m%d_%H-%M-%S`
    local package_ZIP_NAME=BYD_${TARGET}_${now_date}.zip

    echo -e "\n${QFIL_YELLOW}====== ANDROID_PRODUCT_OUT: <$ANDROID_PRODUCT_OUT> ======${QFIL_WHITE}\n"
    PACKAGE_ZIP_DIR=${ANDROID_PRODUCT_OUT}/all_sparse_images

    if [ -d "${PACKAGE_ZIP_DIR}" ]; then
	rm -rf ${PACKAGE_ZIP_DIR}
    fi
    mkdir -p ${PACKAGE_ZIP_DIR}
    sync

    #++++++++++++++++++++++++++++++++++#
    cd $ANDROID_PRODUCT_OUT
    if [ -f "system.img" ]; then
	if [ -d "BAK_IMAGS" ]; then
	    rm -rf ./BAK_IMAGS
	fi
	mkdir -p ./BAK_IMAGS
	mv system.img userdata.img cache.img persist.img ./BAK_IMAGS
    fi
    sync
    
    cp -arf ${ANDROID_PRODUCT_OUT}/*.img ${PACKAGE_ZIP_DIR}
    cp -arf ${ANDROID_PRODUCT_OUT}/*.mbn ${PACKAGE_ZIP_DIR}
    sync

    if [ ! -f "system.img" ]; then
	if [ -d "BAK_IMAGS" ]; then
	    mv ./BAK_IMAGS/* ./
	fi
    fi
    sync

    cp -arf ${MSM_DEVICE_LA_DIR}/common/build/bin/asic/sparse_images/* ${PACKAGE_ZIP_DIR}
    cp -arf ${MSM_DEVICE_LA_DIR}/common/build/patch0.xml ${PACKAGE_ZIP_DIR}
    sync
    #++++++++++++++++++++++++++++++++++#

    cd ${None_HLOS}
    ${Copy_MBN_Script}  8953 all ${PACKAGE_ZIP_DIR}
    sync

    ${Copy_ELF_Script}  8953 all ${PACKAGE_ZIP_DIR}/symbols
    cp -arf ${ANDROID_PRODUCT_OUT}/obj/EMMC_BOOTLOADER_OBJ/build-msm*/lk \
	${ANDROID_PRODUCT_OUT}/obj/KERNEL_OBJ/vmlinux \
	${PACKAGE_ZIP_DIR}/symbols
    sync

    #++++++++++++++++++++++++++++++++++#
    cp -arf build/images/* ${PACKAGE_ZIP_DIR}
    sync
    #++++++++++++++++++++++++++++++++++#

    #++++++++++++++++++++++++++++++++++#
    local rawprogram_unsparse=${PACKAGE_ZIP_DIR}/rawprogram_unsparse.xml
    local rawprogram_unsparse_upgrade=${PACKAGE_ZIP_DIR}/rawprogram_unsparse_upgrade.xml
    if [ -e $rawprogram_unsparse ]; then
	#partition_xml=${None_HLOS}/MSM8953.LA.2.0/common/config/partition.xml
	#sed -i '/sec/ s/filename="sec.dat"/filename=""/g' ${partition_xml}
	sed -i 's/sec.dat//g' ${rawprogram_unsparse}

	cp -arf ${rawprogram_unsparse} ${rawprogram_unsparse_upgrade}
	sed -i 's/zero_1kb.bin//g' ${rawprogram_unsparse_upgrade}
	sed -i 's/zero_1536kb.bin//g' ${rawprogram_unsparse_upgrade}
	sed -i 's/zero_32kb.bin//g' ${rawprogram_unsparse_upgrade}
	sed -i 's/fs_image.tar.gz.mbn.img//g' ${rawprogram_unsparse_upgrade}
	sed -i 's/persist_1.img//g' ${rawprogram_unsparse_upgrade}
	sed -i 's/misc.img//g' ${rawprogram_unsparse_upgrade}
    fi

    local rawprogram0_xml=${PACKAGE_ZIP_DIR}/rawprogram0.xml
    local rawprogram0_BLANK=${PACKAGE_ZIP_DIR}/rawprogram0_BLANK.xml
    local validated_emmc_firehose=${PACKAGE_ZIP_DIR}/validated_emmc_firehose*.mbn
    if [ -e ${rawprogram0_xml} ]; then
	rm -rf ${rawprogram0_xml} ${rawprogram0_BLANK} ${validated_emmc_firehose}
    fi
    #++++++++++++++++++++++++++++++++++#

    cd ${PACKAGE_ZIP_DIR}
    sync
    echo -e "\n====== Build package: ${QFIL_YELLOW} ${package_ZIP_NAME} ${QFIL_WHITE} ======\n"
    zip -qry ${AP_TOP_DIR}/${package_ZIP_NAME} ./*
    sync
}

############################################################################
ENTERCORRECTLY=0
while [ $ENTERCORRECTLY -ne 1 ]
do
    read -n1 -p "Would you Compile the complete Version Package ? [Y/N] : " SIZECHECK
    ENTERCORRECTLY=1
    case $SIZECHECK in
	"y" | "Y")
	    echo -e "\n${QFIL_RED}######## [`date +"%Y-%m-%d %H:%M:%S"`] ########${QFIL_WHITE}\n"
	    ;;
	"n" | "N")
	    echo -e "\n${QFIL_RED}######## [`date +"%Y-%m-%d %H:%M:%S"`] ########${QFIL_WHITE}\n"
	    exit 1
	    ;;
	*)
	    echo -e "\nPlease enter [Y|y] or [N|n] \n"
	    ENTERCORRECTLY=0
	    ;;
    esac
done
############################################################################

cd ${AP_TOP_DIR}
source build/envsetup.sh
lunch ${TARGET}-${VARIANT}
if [ ! "$ANDROID_PRODUCT_OUT" ]; then
    echo -e "\nERORR: Couldn't locate output files.  Try running 'lunch' first.\n"
    exit 1
fi

cd ${None_HLOS}
${TOOLS_PATH}/Scripts/make_amss.sh 8953 -i all
if [ $? -ne 0 ]; then
    echo -e "\n[`date +"%Y-%m-%d %H:%M:%S"`] ====== [make_amss.sh] Execute result is:     Failure ======\n"
    exit 1
fi

cd ${AP_TOP_DIR}
${TOOLS_PATH}/Scripts/make_android.sh ${TARGET} -u -i android
if [ $? -ne 0 ]; then
    echo -e "\n[`date +"%Y-%m-%d %H:%M:%S"`] ====== [make_android.sh] Execute result is:     Failure ======\n"
    exit 1
fi


build_allhols 2>&1 | tee ${AP_TOP_DIR}/logs/HLOS_build_all.log

cd ${AP_TOP_DIR}
build_zip_images 2>&1 | tee ${AP_TOP_DIR}/logs/ZIP_package_all.log


sync
echo -e "\n${QFIL_GREEN}######## [${BASH_SOURCE}] make completed successfully  ########${QFIL_WHITE}\n"
sync
