#!/bin/bash
#########################################################################
# File Name: run_build.sh
# Author: WangSen
# Email: wangs_hs@163.com
# Created Time: 2019年01月21日 星期一 10时01分09秒
#########################################################################

MODULE_NAME=$1
if [ -n "${MODULE_NAME}" ]; then
    read -p "Warning: Please confirm to make '${MODULE_NAME}' [Continue] ?"

    rm -vrf out/target/product/msm8937_64/root
    rm -vrf out/target/product/msm8937_64/vendor
    rm -vrf out/target/product/msm8937_64/system
else
    sudo ntpdate us.pool.ntp.org
    echo -e "\n============================================================\n"

    if [ -d "out" ]; then
	#选项说明：
	#--delete-before 接收者在传输之前进行删除操作
	#--progress 在传输时显示传输过程
	#-a 归档模式，表示以递归方式传输文件，并保持所有文件属性, -rlptgoD (no -H,-A,-X)
	#-H 保持硬连接的文件
	#-v 详细输出模式
	#--stats 给出某些文件的传输状态
	mkdir rsync_empty
	rsync --delete-before -a -H --progress --stats  rsync_empty/ out/
	rm -vrf  rsync_empty/ out/
    fi
fi
sync

# rm -rf out
# repo forall -v -c 'git rebase --abort; git reset --hard; git clean -df' -j64
# repo sync --no-repo-verify -c -j64


NOW_DATE=`date +%Y%m%d`
TARGET="msm8937_64"
VARIANT="userdebug"
JOBS=64
LOG_FILE="${NOW_DATE}_${TARGET}-${VARIANT}_正在编译"
BUILD_OUT_DIR=${NOW_DATE}_${TARGET}-${VARIANT}

create_ccache() {
    echo -e "\nINFO: Setting CCACHE with 10 GB\n"
    export CCACHE_DIR=./.ccache
    export USE_CCACHE=1

    if [ ! -d "out" ]; then
	prebuilts/misc/linux-x86/ccache/ccache -C
	rm -vrf $CCACHE_DIR
	sync
	prebuilts/misc/linux-x86/ccache/ccache -M 10G
    fi
}

#./build.sh ${TARGET} -j ${JOBS} -l ${LOG_FILE} -v ${VARIANT}
build_android() {
    echo -e "\nINFO: Build Android tree for $TARGET\n"
    source build/envsetup.sh
    lunch $TARGET-$VARIANT
    if [ ! "$ANDROID_PRODUCT_OUT" ]; then
	echo -e "\nERORR: Couldn't locate output files.  Try running 'lunch' first.\n"
	exit 1
    fi
    echo -e "\n====== ${FUNCNAME[0]}: <$ANDROID_PRODUCT_OUT> ======\n"

    case $MODULE_NAME in
	aboot | bootimage | systemimage | userdataimage | recoveryimage | vendorimage | persistimage | cacheimage | otapackage)
	    make ${MODULE_NAME} -j${JOBS}
	    ;;
	*)
	    echo -e "\nOnly: aboot | bootimage | systemimage | userdataimage | recoveryimage | vendorimage | persistimage | cacheimage | otapackage\n"
	    make -j${JOBS}
	    if [ $? -ne 0 ]; then
		echo -e "\n[`date +"%Y-%m-%d %H:%M:%S"`] ====== $@ :     Failure ======\n"
		exit 1
	    fi
	    ;;
    esac
    sync

    if [ -d "${BUILD_OUT_DIR}" ]; then
	rm -vrf ${BUILD_OUT_DIR}
    fi
    mkdir -vp ${BUILD_OUT_DIR}

    cp -vLrf $ANDROID_PRODUCT_OUT/*.img ${BUILD_OUT_DIR}
    cp -vLrf $ANDROID_PRODUCT_OUT/*.mbn ${BUILD_OUT_DIR}
}


create_ccache 2>&1 | tee ${LOG_FILE}.log
build_android 2>&1 | tee -a ${LOG_FILE}.log

sync
mv ${LOG_FILE}.log ${BUILD_OUT_DIR}/${NOW_DATE}_${TARGET}-${VARIANT}_"编译完成".log
