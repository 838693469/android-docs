#!/bin/bash
:<<EOF
========================================================
# Author: Xiaowen Sun
# Date: 2017-11-07
# Copyright (c) 2017, Xiaowen Sun. All rights reserved.
========================================================
EOF



set -o errexit
#===================================${初始化}===========================================#
#初始化变量#
ROOTDIR=$(readlink -f .)
SCRIPT=$(basename $0)
SCRIPT=${SCRIPT%.*}
SCRIPT_VERSION="v1.0.0"
CPUCORES=`cat /proc/cpuinfo | grep processor | wc -l`
DATE=$(date +%y%m%d_%H%M)
LOGFILE=${DATE}
LOGDIR=$ROOTDIR/out/build_log/$LOGFILE

#=========================================${自定义函数}===================================================

#格式化输出
RED="\033[0;31m"
YELLOW="\033[1;33m"
GREEN="\033[0;32m"
NO_COLOR="\033[0m"
BOLD="\033[1m"
UNDERLINE="\033[4m"
warn_debug=true
print_debug=true
print_color=36
die() {
    echo -e "==> ${RED}${@}${NO_COLOR}"
    exit 1
}

warn() {
    if [[ "$warn_debug" = true ]]; then
        echo -e "==> ${YELLOW}${@}${NO_COLOR}"
    fi
}

good() {
    echo -e "==> ${GREEN}${*}${NO_COLOR}"
}

show_version(){
    echo "版本号:${SCRIPT_VERSION}"
    exit 0

}

#=========================================${自定义函数}===================================================

# Set echo module root path
AOP_ROOT=./AMSS/AOP.HO.1.1
MODEM_ROOT=./AMSS/MPSS.AT.4.0.2
WLAN_ROOT=./AMSS/WLAN.HL.2.0.1
TZ_ROOT=./AMSS/TZ.XF.5.0
ADSP_ROOT=./AMSS/ADSP.VT.5.0
CDSP_ROOT=./AMSS/CDSP.VT.2.0
BOOT_ROOT=./AMSS/BOOT.XF.2.1
#SLPI_ROOT=./AMSS
ANDROID_ROOT=./android
COMMON_ROOT=./AMSS/SDM670.LA.1.0

## build aop
BUILD_AOP_CMD="./build_670.sh"

## build xbl
BUILD_XBL_CMD="python ./buildex.py --variant LA -t SDM670Pkg,QcomToolsPkg"

##build modem
#BUILD_MODEM_CMD="./build_variant.py sdm670.gen.prod"
BUILD_MODEM_CMD="./build_variant.py sdm710.gen.prod"

##build tz
BUILD_TZ_CMD="python build_all.py -b TZ.XF.5.0 CHIPSET=sdm670 --config=build_config_deploy.xml"

#build cdsp_proc
BUILD_CDSP_CMD="python build.py -c sdm670 -f CDSP"

#build adsp_proc
BUILD_ADSP_CMD="python build.py -c sdm670 -f ADSP"


#build slpi_proc
#BUILD_SLPI_CMD="python build.py -c sdm670"

BUILD_LOG=true
DEF_LOG_FILE=/dev/null
log_file=$DEF_LOG_FILE
# Add begin by  ODM.qianzy for: optimize the script
ERROR_AOP_KEYWORD="Error"
ERROR_MODEM_KEYWORD="errors"
SUCCESS_XBL_KEYWORD="Successfully"
SUCCESS_CDSP_KEYWORD="SUCCESS"
SUCCESS_ADSP_KEYWORD="SUCCESS"
#SUCCESS_SLPI_KEYWORD="SUCCESS"
SUCCESS_TZ_KEYWORD="successfully"
# Add end

usage() {
cat <<USAGE

Usage:
    bash $0 [OPTIONS] [OPTIONS]

Description:
    Builds meta.

OPTIONS:
    -o, --build_aop
        Build aop

    -b, --build_xbl
        Build xbl

    -m, --build_modem
        Build modem

    -cs, --build_cdsp
        Build cdsp

    -d, --build_adsp
        Build adsp

    -t, --build_tz
        Build trust zone

    -bp, --build_bp
        Build all subsystem for amss

    -ap, --build_ap
        Build android

    -a, --build_all
        Build all sub-system and android

    -u, --update_common
        Update Common

    -cp, --copy_images
        Copy qfil&fastboot&elf images to out/

    -l, --log_to_file
        Put build log to file

    -j, --jobs
    Specifies the number of jobs to run simultaneously  (Default: ${JOBS})

    -v, --build_variant
        Build variant(user,userdebug,eng) for android (Default: userdebug)

    -p --build_product
        Build product(Tina) for android (Default: Tina)

    -c --build clean
        Build with Clean

    -C --build_carrier
        Build carrier ([cn_open|factory|cmcc|ct_c...] - Default: ${CARRIER})

    -V, --build_version
        Specify build version

    -sm, --show modem env
        Show build modem env

    -h, --help
        Display this help message

Example:
    build xbl:
        $0 -b

    clean xbl:
        $0 -b -c

    build xbl and show build log:
        $0 -b -l

    clean xbl and show the log:
        $0 -b -c -l
USAGE
exit 0
}

build_successed() {
    if [ -z "`grep $1 $2`" ] ; then
    #    echo "There is not a keyword($1) in file($2)."
        res=1
    else
        res=0
    fi
}

set_env_modem()
{
    PYTHON_PATH=/pkg/qct/software/python/2.7.5/bin
    #MAKE_PATH=/pkg/gnu/make/3.81/bin
    export ARMTOOLS=RVCT221
    export ARMROOT=/pkg/qct/software/arm/RVDS/2.2BLD593
    export ARMLIB=$ARMROOT/RVCT/Data/2.2/349/lib
    export ARMINCLUDE=$ARMROOT/RVCT/Data/2.2/349/include/unix
    export ARMINC=$ARMINCLUDE
    export ARMCONF=$ARMROOT/RVCT/Programs/2.2/593/linux-pentium
    export ARMDLL=$ARMROOT/RVCT/Programs/2.2/593/linux-pentium
    export ARMBIN=$ARMROOT/RVCT/Programs/2.2/593/linux-pentium
    export PATH=$MAKE_PATH:$PYTHON_PATH:$ARM_COMPILER_PATH:$PATH
    export ARMHOME=$ARMROOT
    export HEXAGON_ROOT=/pkg/qct/software/hexagon/releases/tools
}

build_aop() {
    cd ${AOP_ROOT}/aop_proc/build
    if [ "$BUILD_CLEAN" = "true" ]; then
        echo -e "\n Clean AOP...\n"
        BUILD_AOP_CMD+=" -c"
    else
        echo -e "\n Build AOP...\n"
    fi

    echo "$BUILD_AOP_CMD"
    echo
    echo
    if [ "$BUILD_LOG" = "true" ] ;then
        if [ ! -d $LOGDIR ] ;then
          mkdir -p $LOGDIR
        fi
        log_file=$LOGDIR/aop.log
    else
        log_file=$DEF_LOG_FILE
    fi

    $BUILD_AOP_CMD   2>&1 | tee $log_file
    build_successed $ERROR_AOP_KEYWORD $log_file
    if [ $res -eq 0 ] ; then
        echo -e "\nBuild aop failed.\n"
        exit 1;
    fi
    cd $ROOTDIR
}

build_xbl() {
    cd ${BOOT_ROOT}/boot_images/QcomPkg/
    if [ "$VARIANT" == "user" ]; then
        BUILD_XBL_CMD+=" -r RELEASE"
        RELEASE=RELEASE
    else
        BUILD_XBL_CMD+=" -r DEBUG"
        RELEASE=DEBUG
    fi

    if [ "$BUILD_CLEAN" = "true" ]; then
        echo -e "\n Clean XBL...\n"
        BUILD_XBL_CMD+=" --build_flags=cleanall"
    else
        echo -e "\n Build XBL...\n"
    fi

    echo "$BUILD_XBL_CMD"
    echo
    echo

    if [ "$BUILD_LOG" = "true" ] ;then
        if [ ! -d $LOGDIR ] ;then
          mkdir -p $LOGDIR
        fi
        log_file=$LOGDIR/xbl.log
    else
        log_file=$DEF_LOG_FILE
    fi

    $BUILD_XBL_CMD   2>&1 | tee $log_file

    build_successed $SUCCESS_XBL_KEYWORD $log_file
    if [ $res -ne 0 ] ; then
        echo -e "\nBuild xbl failed.\n"
        exit 1;
    fi

    cd $ROOTDIR
}

build_modem() {

    cd $ROOTDIR
    #Add end
    cd ${MODEM_ROOT}/modem_proc/build/ms

    if [ "$BUILD_CLEAN" = "true" ]; then
        echo -e "\n Clean MODEM...\n"
        BUILD_MODEM_CMD+=" --clean"
    else
        BUILD_MODEM_CMD+=" bparams=-k"
    echo -e "\n Build MODEM...\n"
    fi

    set_env_modem
#--------------------------------------------------------------------
    echo "$BUILD_MODEM_CMD"
    echo
    echo

    if [ "$BUILD_LOG" = "true" ] ;then
        if [ ! -d $LOGDIR ] ;then
          mkdir -p $LOGDIR
        fi
        log_file=$LOGDIR/modem.log
    else
        log_file=$DEF_LOG_FILE
    fi

    $BUILD_MODEM_CMD  2>&1 | tee $log_file

    build_successed $ERROR_MODEM_KEYWORD $log_file
    if [ $res -eq 0 ] ; then
        echo -e "\nBuild modem failed.\n"
        exit 1;
    fi
    cd $ROOTDIR
}
build_cdsp() {
    cd ${CDSP_ROOT}/cdsp_proc/build/
    if [ "$BUILD_CLEAN" = "true" ]; then
        echo -e "\n Clean cdsp...\n"
        BUILD_CDSP_CMD+=" -o clean"
    else
        echo -e "\n Build CDSP...\n"
        BUILD_CDSP_CMD+=" -o all"
    fi

    echo "$BUILD_CDSP_CMD"
    echo
    echo

    if [ "$BUILD_LOG" = "true" ] ;then
        if [ ! -d $LOGDIR ] ;then
          mkdir -p $LOGDIR
        fi
        log_file=$LOGDIR/cdsp.log
    else
        log_file=$DEF_LOG_FILE
    fi

    $BUILD_CDSP_CMD    2>&1 | tee $log_file

    build_successed $SUCCESS_CDSP_KEYWORD $log_file
    if [ $res -ne 0 ] ; then
        echo -e "\nBuild cdsp failed.\n"
        exit 1;
    fi
    cd $ROOTDIR

}

build_adsp() {
    cd ${ADSP_ROOT}/adsp_proc/build

    if [ "$BUILD_CLEAN" = "true" ]; then
        echo -e "\n Clean adsp...\n"
        BUILD_ADSP_CMD+=" -o clean"
    else
        echo -e "\n Build adsp...\n"
        BUILD_ADSP_CMD+=" -o all"
    fi

    echo "$BUILD_ADSP_CMD"
    echo
    echo

    if [ "$BUILD_LOG" = "true" ] ;then
        if [ ! -d $LOGDIR ] ;then
          mkdir -p $LOGDIR
        fi
        log_file=$LOGDIR/adsp.log
    else
        log_file=$DEF_LOG_FILE
    fi

    $BUILD_ADSP_CMD    2>&1 | tee $log_file

    build_successed $SUCCESS_ADSP_KEYWORD $log_file
    if [ $res -ne 0 ] ; then
        echo -e "\nBuild adsp failed.\n"
        exit 1;
    fi
    cd $ROOTDIR

}

build_tz() {
    cd ${TZ_ROOT}/trustzone_images/build/ms

    if [ "$BUILD_CLEAN" = "true" ]; then
        echo -e "\n Clean TrustZone...\n"
        BUILD_TZ_CMD+=" --clean"
    else
        BUILD_TZ_CMD+=" --recompile"
        echo -e "\n Build TrustZone...\n"
    fi

    echo "$BUILD_TZ_CMD"
    echo
    echo

    if [ "$BUILD_LOG" = "true" ] ;then
        if [ ! -d $LOGDIR ] ;then
          mkdir -p $LOGDIR
        fi
        log_file=$LOGDIR/tz.log
    else
        log_file=$DEF_LOG_FILE
    fi

    $BUILD_TZ_CMD    2>&1 | tee $log_file

    build_successed $SUCCESS_TZ_KEYWORD $log_file
    if [ $res -ne 0 ] ; then
        echo -e "\nBuild TrustZone failed.\n"
        exit 1;
    fi
    cd $ROOTDIR
}

build_slpi() {
    cd slpi_proc/build

    if [ "$BUILD_CLEAN" = "true" ]; then
        echo -e "\n Clean SLPI...\n"
        BUILD_SLPI_CMD+=" -o clean"
    else
        echo -e "\n Build SLPI...\n"
        BUILD_SLPI_CMD+=" -o all"
    fi

    echo "$BUILD_SLPI_CMD"
    echo
    echo

    if [ "$BUILD_LOG" = "true" ] ;then
        if [ ! -d $LOGDIR ] ;then
          mkdir -p $LOGDIR
        fi
        log_file=$LOGDIR/slpi.log
    else
        log_file=$DEF_LOG_FILE
    fi

    $BUILD_SLPI_CMD    2>&1 | tee $log_file
    build_successed $SUCCESS_SLPI_KEYWORD $log_file
    if [ $res -ne 0 ] ; then
        echo -e "\nBuild SLPI failed.\n"
        exit 1;
    fi
    cd $ROOTDIR
}

update_common() {
    cd $ROOTDIR/${COMMON_ROOT}
    cp contents.xml contents.xml.bak
    cp ${PRODUCT}_contents.xml contents.xml
    cp common/config/ufs/partition.xml common/config/ufs/partition.xml.bak
    if [ "$CARRIER" = "factory" ] ;then
        cp common/config/ufs/${PRODUCT}_factory_partition.xml common/config/ufs/partition.xml
    else
        cp common/config/ufs/${PRODUCT}_partition.xml common/config/ufs/partition.xml
    fi
    cd $ROOTDIR/${COMMON_ROOT}/common/build

    if [ "$BUILD_LOG" = "true" ] ;then
        if [ ! -d $LOGDIR ] ;then
          mkdir -p $LOGDIR
        fi
        log_file=$LOGDIR/uc.log
    else
        log_file=$DEF_LOG_FILE
    fi

    python build.py 2>&1 | tee $log_file

    cd $ROOTDIR/${COMMON_ROOT}
    mv contents.xml.bak contents.xml
    mv common/config/ufs/partition.xml.bak common/config/ufs/partition.xml
    cd $ROOTDIR
}

build_ap() {

    cd $ROOTDIR/${ANDROID_ROOT}
    if [ "$BUILD_LOG" = "true" ] ;then
        if [ ! -d $LOGDIR ] ;then
          mkdir -p $LOGDIR
        fi
        log_file=$LOGDIR/build_ap.log
    else
        log_file=$DEF_LOG_FILE
    fi

    #./build.sh $PRODUCT  -C $CARRIER -v $VARIANT -j $JOBS 2>&1 | tee $log_file
    ./build.sh $PRODUCT  -v $VARIANT -j $JOBS 2>&1 | tee $log_file
    if [ ! -f out/target/product/${PRODUCT}/system.img ] ;then
        die "Build Android failed."
    fi

    cd $ROOTDIR

}

build_bp() {
    echo -e "\n Build BP... \n"

    build_aop
    build_xbl
    build_modem
    build_tz
    build_cdsp
    build_adsp

    update_common
}

build_all() {
    echo -e "\n Build All... \n"
    build_ap
    build_bp
}



set_env_pack(){
    PACK_OUT="out"
    if [ ! -d ${PACK_OUT} ];then
        mkdir ${PACK_OUT}
    fi
    FASTBOOT_DIR=${PRODUCT}_${VARIANT}_fastboot
    QFIL_DIR=${PRODUCT}_${VARIANT}_qfil
    ELF_DIR=${PRODUCT}_${VARIANT}_elf



}

get_revision_num(){
    local revision=$(repo forall -c "git tag -l"  2>$DEF_LOG_FILE | sort | tail -1 | sed -e 's#revision_#r#g' | grep -w "r[0-9]*")
    test -z "${revision}" && revision=null
    echo ${revision}
}

copy_images() {
    set_env_pack

	test -z "$(grep -w user ./${ANDROID_ROOT}/out/target/product/${PRODUCT}/previous_build_config.mk)" || RELEASE=RELEASE

    good "copy [$PRODUCT][${VARIANT}] image to [$PACK_OUT] dir ......."

    # copy qfil image to out
    test -d ${PACK_OUT}/$FASTBOOT_DIR && rm -rf ${PACK_OUT}/$FASTBOOT_DIR 
    test -d ${PACK_OUT}/$QFIL_DIR && rm -rf ${PACK_OUT}/$QFIL_DIR 
    test -d ${PACK_OUT}/$ELF_DIR && rm -rf ${PACK_OUT}/$ELF_DIR 

    mkdir -p ${PACK_OUT}/$FASTBOOT_DIR
    mkdir -p ${PACK_OUT}/$QFIL_DIR
    mkdir -p ${PACK_OUT}/$ELF_DIR

    cp -rf ./${COMMON_ROOT}/common/build/ufs/bin/BTFM.bin ${PACK_OUT}/$QFIL_DIR
    cp -rf ./${COMMON_ROOT}/common/build/ufs/bin/asic/NON-HLOS.bin ${PACK_OUT}/$QFIL_DIR
    cp -rf ./${COMMON_ROOT}/common/build/bin/asic/dspso.bin ${PACK_OUT}/$QFIL_DIR
    cp -rf ./${COMMON_ROOT}/common/build/ufs/gpt_backup*.bin ${PACK_OUT}/$QFIL_DIR
    cp -rf ./${COMMON_ROOT}/common/build/ufs/gpt_main*.bin ${PACK_OUT}/$QFIL_DIR
    cp -rf ./${COMMON_ROOT}/common/build/ufs/patch*.xml ${PACK_OUT}/$QFIL_DIR
    cp -rf ./${COMMON_ROOT}/common/build/ufs/rawprogram1.xml ${PACK_OUT}/$QFIL_DIR
    cp -rf ./${COMMON_ROOT}/common/build/ufs/rawprogram2.xml ${PACK_OUT}/$QFIL_DIR
    cp -rf ./${COMMON_ROOT}/common/build/ufs/rawprogram3.xml ${PACK_OUT}/$QFIL_DIR
    cp -rf ./${COMMON_ROOT}/common/build/ufs/rawprogram5.xml ${PACK_OUT}/$QFIL_DIR
    cp -rf ./${COMMON_ROOT}/common/config/ufs/provision/${PRODUCT}_provision_samsung.xml ${PACK_OUT}/$QFIL_DIR
    cp -rf ./${COMMON_ROOT}/common/build/ufs/bin/asic/sparse_images/* ${PACK_OUT}/$QFIL_DIR
    rm -rf ${PACK_OUT}/$QFIL_DIR/*.bak
    cp -rf ./${COMMON_ROOT}/common/core_qupv3fw/sdm670/rel/1.0/qupv3fw.elf ${PACK_OUT}/$QFIL_DIR
    cp -rf ./${COMMON_ROOT}/common/sectools/resources/build/fileversion2/sec.dat ${PACK_OUT}/$QFIL_DIR
    cp -rf ./${BOOT_ROOT}/boot_images/QcomPkg/SDM670Pkg/Bin/670/LA/${RELEASE}/prog_firehose_ddr.elf ${PACK_OUT}/$QFIL_DIR
    cp -rf ./${BOOT_ROOT}/boot_images/QcomPkg/SDM670Pkg/Bin/670/LA/${RELEASE}/xbl.elf ${PACK_OUT}/$QFIL_DIR
    cp -rf ./${BOOT_ROOT}/boot_images/QcomPkg/SDM670Pkg/Bin/670/LA/${RELEASE}/xbl_config.elf ${PACK_OUT}/$QFIL_DIR
    cp -rf ./${BOOT_ROOT}/boot_images/QcomPkg/SDM670Pkg/Bin/670/LA/${RELEASE}/imagefv.elf ${PACK_OUT}/$QFIL_DIR
    cp -rf ./${BOOT_ROOT}/boot_images/QcomPkg/SDM670Pkg/Bin/670/LA/${RELEASE}/pmic.elf ${PACK_OUT}/$QFIL_DIR
    cp -rf ./${BOOT_ROOT}/boot_images/QcomPkg/Tools/binaries/logfs_ufs_8mb.bin ${PACK_OUT}/$QFIL_DIR
    cp -rf ./${AOP_ROOT}/aop_proc/build/ms/bin/AAAAANAZO/670/pm670/aop.mbn ${PACK_OUT}/$QFIL_DIR
    cp -rf ./${TZ_ROOT}/trustzone_images/build/ms/bin/XAWAANAA/devcfg.mbn ${PACK_OUT}/$QFIL_DIR
    cp -rf ./${TZ_ROOT}/trustzone_images/build/ms/bin/XAWAANAA/tz.mbn ${PACK_OUT}/$QFIL_DIR
    cp -rf ./${TZ_ROOT}/trustzone_images/build/ms/bin/XAWAANAA/cmnlib64.mbn ${PACK_OUT}/$QFIL_DIR
    cp -rf ./${TZ_ROOT}/trustzone_images/build/ms/bin/XAWAANAA/cmnlib.mbn ${PACK_OUT}/$QFIL_DIR
    cp -rf ./${TZ_ROOT}/trustzone_images/build/ms/bin/XAWAANAA/hyp.mbn ${PACK_OUT}/$QFIL_DIR
    cp -rf ./${TZ_ROOT}/trustzone_images/build/ms/bin/XAWAANAA/keymaster64.mbn ${PACK_OUT}/$QFIL_DIR
    cp -rf ./${TZ_ROOT}/trustzone_images/build/ms/bin/XAWAANAA/storsec.mbn ${PACK_OUT}/$QFIL_DIR
    cp -rf ./${ANDROID_ROOT}/out/target/product/${PRODUCT}/boot.img ${PACK_OUT}/$QFIL_DIR
    cp -rf ./${ANDROID_ROOT}/out/target/product/${PRODUCT}/dtbo.img ${PACK_OUT}/$QFIL_DIR
    cp -rf ./${ANDROID_ROOT}/out/target/product/${PRODUCT}/vbmeta.img ${PACK_OUT}/$QFIL_DIR
    cp -rf ./${ANDROID_ROOT}/out/target/product/${PRODUCT}/abl.elf ${PACK_OUT}/$QFIL_DIR

    # Add begin by ODM.guoliang for copy recovery.img to qfil directory
    cp -rf ./${ANDROID_ROOT}/out/target/product/${PRODUCT}/recovery.img ${PACK_OUT}/$QFIL_DIR
    # Add end

    good "copy QFILE image to [${PACK_OUT}/$QFIL_DIR] completed !"

    cp -rf ./${COMMON_ROOT}/common/build/ufs/bin/BTFM.bin ${PACK_OUT}/$FASTBOOT_DIR
    cp -rf ./${COMMON_ROOT}/common/build/ufs/bin/asic/NON-HLOS.bin ${PACK_OUT}/$FASTBOOT_DIR
    cp -rf ./${COMMON_ROOT}/common/build/bin/asic/dspso.bin ${PACK_OUT}/$FASTBOOT_DIR
    cp -rf ./${COMMON_ROOT}/common/build/ufs/rawprogram*.xml ${PACK_OUT}/$FASTBOOT_DIR
    cp -rf ./${COMMON_ROOT}/common/config/ufs/provision/${PRODUCT}_provision_samsung.xml ${PACK_OUT}/$FASTBOOT_DIR
    cp -rf ./${COMMON_ROOT}/common/core_qupv3fw/sdm670/rel/1.0/qupv3fw.elf ${PACK_OUT}/$FASTBOOT_DIR
    cp -rf ./${COMMON_ROOT}/common/sectools/resources/build/fileversion2/sec.dat ${PACK_OUT}/$FASTBOOT_DIR
    cp -rf ./${BOOT_ROOT}/boot_images/QcomPkg/SDM670Pkg/Bin/670/LA/${RELEASE}/prog_firehose_ddr.elf ${PACK_OUT}/$FASTBOOT_DIR
    cp -rf ./${BOOT_ROOT}/boot_images/QcomPkg/SDM670Pkg/Bin/670/LA/${RELEASE}/xbl.elf ${PACK_OUT}/$FASTBOOT_DIR
    cp -rf ./${BOOT_ROOT}/boot_images/QcomPkg/SDM670Pkg/Bin/670/LA/${RELEASE}/xbl_config.elf ${PACK_OUT}/$FASTBOOT_DIR
    cp -rf ./${BOOT_ROOT}/boot_images/QcomPkg/SDM670Pkg/Bin/670/LA/${RELEASE}/imagefv.elf ${PACK_OUT}/$FASTBOOT_DIR
    cp -rf ./${BOOT_ROOT}/boot_images/QcomPkg/SDM670Pkg/Bin/670/LA/${RELEASE}/pmic.elf ${PACK_OUT}/$FASTBOOT_DIR
    cp -rf ./${BOOT_ROOT}/boot_images/QcomPkg/Tools/binaries/logfs_ufs_8mb.bin ${PACK_OUT}/$FASTBOOT_DIR
    cp -rf ./${AOP_ROOT}/aop_proc/build/ms/bin/AAAAANAZO/670/pm670/aop.mbn ${PACK_OUT}/$FASTBOOT_DIR
    cp -rf ./${TZ_ROOT}/trustzone_images/build/ms/bin/XAWAANAA/devcfg.mbn ${PACK_OUT}/$FASTBOOT_DIR
    cp -rf ./${TZ_ROOT}/trustzone_images/build/ms/bin/XAWAANAA/tz.mbn ${PACK_OUT}/$FASTBOOT_DIR
    cp -rf ./${TZ_ROOT}/trustzone_images/build/ms/bin/XAWAANAA/cmnlib64.mbn ${PACK_OUT}/$FASTBOOT_DIR
    cp -rf ./${TZ_ROOT}/trustzone_images/build/ms/bin/XAWAANAA/cmnlib.mbn ${PACK_OUT}/$FASTBOOT_DIR
    cp -rf ./${TZ_ROOT}/trustzone_images/build/ms/bin/XAWAANAA/hyp.mbn ${PACK_OUT}/$FASTBOOT_DIR
    cp -rf ./${TZ_ROOT}/trustzone_images/build/ms/bin/XAWAANAA/keymaster64.mbn ${PACK_OUT}/$FASTBOOT_DIR
    cp -rf ./${TZ_ROOT}/trustzone_images/build/ms/bin/XAWAANAA/storsec.mbn ${PACK_OUT}/$FASTBOOT_DIR
    cp -rf ./${ANDROID_ROOT}/out/target/product/${PRODUCT}/boot.img ${PACK_OUT}/$FASTBOOT_DIR
    cp -rf ./${ANDROID_ROOT}/out/target/product/${PRODUCT}/persist.img ${PACK_OUT}/$FASTBOOT_DIR
    cp -rf ./${ANDROID_ROOT}/out/target/product/${PRODUCT}/vendor.img ${PACK_OUT}/$FASTBOOT_DIR
    cp -rf ./${ANDROID_ROOT}/out/target/product/${PRODUCT}/system.img ${PACK_OUT}/$FASTBOOT_DIR
    cp -rf ./${ANDROID_ROOT}/out/target/product/${PRODUCT}/userdata.img ${PACK_OUT}/$FASTBOOT_DIR
#    cp -rf ./${ANDROID_ROOT}/out/target/product/${PRODUCT}/recovery.img ${PACK_OUT}/$FASTBOOT_DIR
#    cp -rf ./${ANDROID_ROOT}/out/target/product/${PRODUCT}/cache.img ${PACK_OUT}/$FASTBOOT_DIR
    cp -rf ./${ANDROID_ROOT}/out/target/product/${PRODUCT}/dtbo.img ${PACK_OUT}/$FASTBOOT_DIR
    cp -rf ./${ANDROID_ROOT}/out/target/product/${PRODUCT}/vbmeta.img ${PACK_OUT}/$FASTBOOT_DIR
    cp -rf ./${ANDROID_ROOT}/out/target/product/${PRODUCT}/abl.elf ${PACK_OUT}/$FASTBOOT_DIR
#    cp -rf ./${ANDROID_ROOT}/device/Meitu/${PRODUCT}/fastboot_all.* ${PACK_OUT}/$FASTBOOT_DIR

    # Add begin by ODM.guoliang for copy recovery.img & cache.img to fastboot directory
    cp -rf ./${ANDROID_ROOT}/out/target/product/${PRODUCT}/recovery.img ${PACK_OUT}/$FASTBOOT_DIR
    cp -rf ./${ANDROID_ROOT}/out/target/product/${PRODUCT}/cache.img ${PACK_OUT}/$FASTBOOT_DIR
    # Add end

    good "copy FASTBOOT image to [${PACK_OUT}/$FASTBOOT_DIR] completed !"

    cp -rf ./AMSS/about.html ${PACK_OUT}/$ELF_DIR
    cp -rf ./${COMMON_ROOT}/contents.xml ${PACK_OUT}/$ELF_DIR
    cp -rf ./${ANDROID_ROOT}/out/target/product/${PRODUCT}/obj/kernel/msm-4.9/vmlinux ${PACK_OUT}/$ELF_DIR
    cp -rf ./${ANDROID_ROOT}/out/target/product/${PRODUCT}/obj/kernel/msm-4.9/System.map ${PACK_OUT}/$ELF_DIR
    cp -rf ./${TZ_ROOT}/trustzone_images/ssg/bsp/devcfg/build/XAWAANAA/devcfg.elf ${PACK_OUT}/$ELF_DIR
    cp -rf ./${BOOT_ROOT}/boot_images/Build/SDM670LA_Loader/${RELEASE}_CLANG39LINUX/AARCH64/QcomPkg/XBLLoader/XBLLoader/DEBUG/XBLLoader.dll ${PACK_OUT}/$ELF_DIR
    cp -rf ./${AOP_ROOT}/aop_proc/core/bsp/aop/build/AOP_AAAAANAZO.elf ${PACK_OUT}/$ELF_DIR
    cp -rf ./${MODEM_ROOT}/modem_proc/build/ms/*.elf ${PACK_OUT}/$ELF_DIR
    rm -rf ${PACK_OUT}/$ELF_DIR/*_reloc.elf
    cp -rf ./${MODEM_ROOT}/modem_proc/build/myps/qshrink/*.qsr4 ${PACK_OUT}/$ELF_DIR
    cp -rf ./${ADSP_ROOT}/adsp_proc/dsp_670.adsp.prodQ.elf ${PACK_OUT}/$ELF_DIR
    cp -rf ./${ADSP_ROOT}/adsp_proc/build/ms/AUDIO_670.adsp.prodQ.elf ${PACK_OUT}/$ELF_DIR
    cp -rf ./${ADSP_ROOT}/adsp_proc/build/ms/ROOT_670.adsp.prodQ.elf ${PACK_OUT}/$ELF_DIR
    cp -rf ./${CDSP_ROOT}/cdsp_proc/build/ms/ROOT_670.cdsp.prodQ.elf ${PACK_OUT}/$ELF_DIR
    cp -rf ./${CDSP_ROOT}/cdsp_proc/dsp_670.cdsp.prodQ.elf ${PACK_OUT}/$ELF_DIR

    good "copy ELF debug to [${PACK_OUT}/$ELF_DIR] completed !"

}
# ===========================================================

send_images(){
    set_env_pack
    local rootDir=$(pwd)
    local dest="$1"
    local user="meitu"
    local server="172.16.1.230"
    local chip="SDM710O"
    local version="DrvOnly"
    local planning="DVT1"
    local sig="unsign"
    local revision=$(get_revision_num)
    local pack_dir="${chip}_${version}_${planning}_${PRODUCT}_${DATE}_${revision}_${VARIANT}_${sig}"

    cd ${PACK_OUT}
    mkdir -p ${pack_dir}/image
    mkdir -p ${pack_dir}/else
    good "send [$PRODUCT][$VARIANT] image  to [${server}] ing ...... "
    zip -r ${pack_dir}/${pack_dir}_qfil.zip $QFIL_DIR
    zip -r ${pack_dir}/${pack_dir}_fastboot.zip $FASTBOOT_DIR
    cp -rf $QFIL_DIR/* ${pack_dir}/image/

    if [[ $(which 7z) == "" ]];then
        zip -r ${pack_dir}/else/${pack_dir}_elf.zip $ELF_DIR
		zip -r ${pack_dir}/else/${pack_dir}_symbols.zip ${rootDir}/${ANDROID_ROOT}/out/target/product/${PRODUCT}/symbols
    else
        7z a -t7z -r ${pack_dir}/else/${pack_dir}_elf.7z $ELF_DIR
		7z a -t7z -r ${pack_dir}/else/${pack_dir}_symbols.7z ${rootDir}/${ANDROID_ROOT}/out/target/product/${PRODUCT}/symbols
    fi

    good "zip [$PRODUCT][$VARIANT] image  to [${pack_dir}/image/] completed !"

#   if [ "$PRODUCT" == "Tiffany" ];then
#       local projectDir="/home/meitu/disk_d/Tiffany/3.dailybuild_release/"
#   fi

#   if [ "$PRODUCT" == "Melody" ];then
#       local projectDir="/home/meitu/disk_f/Melody/3.dailybuild_release/"
#   fi

    if [ "$PRODUCT" == "Tina" ];then
        local projectDir="/home/meitu/disk_g/Tina/3.dailybuild_release"
    fi

    chmod 775 ${pack_dir} -R
    scp -r ${pack_dir} $user@${server}:${projectDir}/${dest}/
    nohup ssh meitu@172.31.2.8 python /home/meitu/workspace/scratch.pyx ${projectDir}/${dest}/${pack_dir}/${pack_dir}_fastboot.zip&
    good "send [${pack_dir}] image  to [$user@${server}:${projectDir}/${dest}/] completed !"
    cd - > $DEF_LOG_FILE


}
#=================================${参数选择}============================================
# Setup getopt.
VARIANT=userdebug
PRODUCT=Tina
CARRIER=cn_open
VERSION=${DATE}
BUILD_CLEAN="false"
OPTS="false"
RELEASE=DEBUG
JOBS=$(($(cat /proc/cpuinfo | grep processor | wc -l)*3))

[ $# -eq 0 ] && usage

ARGS=$(getopt -o v:p:V:C:j:hrbmsdtwuacl -al ap,bp,cp,si,cs,sm,version,test,help,build_aop,build_slpi,build_xbl,build_modem,build_cdsp,build_adsp,build_tz,build_wcnss,update_common,build_ap,build_bp,copy_images,send_images,build_variant,build_product,build_version,build_carrier,build_all,clean_build,build_log,jobs -- "$@")


eval set -- "${ARGS}" 
#echo "caicai_debug: $@"
while true  ;do
        case "$1" in
        -o|--build_aop)             BUILD_AOP="true";;
        -b|--build_xbl)             BUILD_XBL="true";;
        -m|--build_modem)           BUILD_MODEM="true";;
        -cs|--build_cdsp)           BUILD_CDSP="true";;
        -d|--build_adsp)            BUILD_ADSP="true";;
        -s|--build_slpi)            BUILD_SLPI="true";;
        -t|--build_tz)              BUILD_TZ="true";;
        -w|--build_wcnss)           BUILD_WCNSS="true";;
        -u|--update_common)         UPDATE_COMMON="true";;
        --ap|--build_ap)            BUILD_AP="true";;
        --bp|--build_bp)            BUILD_BP="true";;

        --cp|--copy_images)         COPY_IMAGES="true";;
        --si|--send_images)         SEND_IMAGES="true";;

        -v|--build_variant)         VARIANT="$2";shift;;
        -p|--build_product)         PRODUCT="$2";shift;;
        -V|--build_version)         VERSION="$2";shift;;
        -C|--build_carrier)         CARRIER="$2";shift;;
        -j|--jobs)                  JOBS="$2";shift;;
        -a|--build_all)             BUILD_ALL="true";;
        -c|--clean_build)           BUILD_CLEAN="true";;
        -l|--build_log)             BUILD_LOG="true";;

        --sm|--show_env_modem)      SHOW_ENV_MODEM="true";;

        -h|--help)                  usage;;
        --test)                     TEST="true";;
        --version)                  show_version;;
        --)                         arg1="$2"; arg2="$3"; arg3="$4"; break;;
        esac
shift
done
#####################################


#===============================================================
# Mandatory argument

if [ "$BUILD_AOP" = "true" ]; then
    build_aop
fi

if [ "$BUILD_XBL" = "true" ]; then
    build_xbl
fi

if [ "$BUILD_MODEM" = "true" ]; then
    build_modem
fi

if [ "$BUILD_CDSP" = "true" ]; then
    build_cdsp
fi

if [ "$BUILD_ADSP" = "true" ]; then
    build_adsp
fi

if [ "$BUILD_TZ" = "true" ]; then
    build_tz
fi

if [ "$UPDATE_COMMON" = "true" ]; then
    update_common
fi

if [ "$BUILD_BP" = "true" ]; then
    build_bp
fi

if [ "$BUILD_AP" = "true" ]; then
    build_ap
fi

if [ "$BUILD_ALL" = "true" ]; then
    build_all
fi

if [ "$COPY_IMAGES" = "true" ]; then
    if [ "$BUILD_LOG" = "true" ] ;then
        if [ ! -d $LOGDIR ] ;then
          mkdir -p $LOGDIR
        fi
        log_file=$LOGDIR/copy_image.log
    else
        log_file=$DEF_LOG_FILE
    fi
    copy_images 2>&1 | tee $log_file
fi

#SPM db专用，传输镜像到服务器，必须是最后一组参数
if [ "$SEND_IMAGES" = "true" ]; then
    if [ "$BUILD_LOG" = "true" ] ;then
        if [ ! -d $LOGDIR ] ;then
          mkdir -p $LOGDIR
        fi
        log_file=$LOGDIR/send_image.log
    else
        log_file=$DEF_LOG_FILE
    fi
    send_images $arg1 2>&1 | tee ${log_file}
fi
#=======================================
if [ "$SHOW_ENV_MODEM" = "true" ]; then
    set_env_modem
fi
#=======================================

#内调函数
if [ "$TEST" == "true" ];then
    echo $@
    $arg1 $arg2 $arg3
    exit 0
fi
#########################################


#usage



