#!/bin/bash
############################################################################################################
###  编译命令: AP端默认编译eng版本，如需编译其它版本，请添加对应参数（user,debug）                      ####
###  兼容8917与8937版本: ./quick_build.sh msm8937_64 overall n                                          ####
###   efuse签名版本 all: ./quick_build.sh msm8937_64 all n                                              ####
###   efuse非签名版本 all: ./quick_build.sh msm8937_64 all n unsign                                     ####
###      all clean: ./quick_build.sh msm8937_64 all c                                                   ####
###           amss: ./quick_build.sh msm8937_64 amss                                                    ####
###      amss boot: ./quick_build.sh msm8937_64 pl                                                      ####
###      amss mpss: ./quick_build.sh msm8937_64 mpss                                                    ####
###       amss rpm: ./quick_build.sh msm8937_64 rpm_proc                                                ####
###        amss tz: ./quick_build.sh msm8937_64 tz                                                      ####
###      amss adsp: ./quick_build.sh msm8937_64 adsp                                                    ####
###        common: ./quick_build.sh msm8937_64 common                                                   ####
###          AP端: ./quick_build.sh msm8937_64 n （若命令中参数ACTION不为null，均会编译AP端代码）       ####
###     bootimage: ./quick_build.sh msm8937_64 boot or boot-nodeps                                      ####
###         aboot: ./quick_build.sh msm8937_64 aboot                                                    ####
###   systemimage: ./quick_build.sh msm8937_64 system or snod                                           ####
###   vendorimage: ./quick_build.sh msm8937_64 vendor or vnod                                           ####
###      apdimage: ./quick_build.sh msm8937_64 apd                                                      ####
### recoveryimage: ./quick_build.sh msm8937_64 recovery                                                 ####
###  ramdiskimage: ./quick_build.sh msm8937_64 ramdisk or ramdisk-nodeps                                ####
###       AP端模块: ./quick_build.sh msm8937_64 mmm 模块路径                                            ####
############################################################################################################

WsRootDir=`pwd`
MY_NAME=`whoami`
amssPath=$WsRootDir/amss
CONFIGPATH=$WsRootDir/device/wind
ARM=arm64
#KERNELCONFIGPATH=$WsRootDir/kernel-3.18/arch/$ARM/configs
CUSTOMPATH=$WsRootDir/device/wind
RELEASE_PARAM=all
CHIP=8917
LOG_PATH=$WsRootDir/build-log
    CPUCORE=24
WIND_DEXPREOPT_OPTION=
WIND_EFUSE_UNSIGN=
WIND_CHIP=
WIND_BUILD_MODE=
WIND_FACTORY_BUILD=no
WIND_NO_GMS=no

export LM_LICENSE_FILE=8224@10.20.26.73
export ARMLMD_LICENSE_FILE=8224@10.20.26.73


function get_make_command()
{
     echo command ./makeMtk
}

function makemk()
{
    local start_time=$(date +"%s")
    $(get_make_command) "$@"
    local ret=$?
    local end_time=$(date +"%s")
    local tdiff=$(($end_time-$start_time))
    local hours=$(($tdiff / 3600 ))
    local mins=$((($tdiff % 3600) / 60))
    local secs=$(($tdiff % 60))
    echo
        if [ $ret -eq 0 ] ; then
            echo -n -e "\033[34m #### make completed successfully \033[0m"
        else
            echo -n -e "\033[31m #### make failed to build some targets \033[0m"
        fi
        if [ $hours -gt 0 ] ; then
            printf "(%02g:%02g:%02g (hh:mm:ss))" $hours $mins $secs
        elif [ $mins -gt 0 ] ; then
            printf "(%02g:%02g (mm:ss))" $mins $secs
        elif [ $secs -gt 0 ] ; then
            printf "(%s seconds)" $secs
        fi
    echo -e "\033[31m #### \033[0m"
    echo
    return $ret
}

function build_version()
{
    #add produce verison
    #############################
    #version number
    #############################
    echo "********remove old version********"
       echo
    if [ -f "./version" ] ;then
       rm version
    fi

    VERSION=$WsRootDir/device/wind/${PRODUCT}/version
    if [ -f "$VERSION" ] ;then
       echo "***************copy new version***************"
       cp $VERSION .
       echo
    else
       echo "File version not exist!!!!!!!!!"
    fi
    INVER=`awk -F = 'NR==1 {printf $2}' version`
    OUTVER=`awk -F = 'NR==2 {printf $2}' version`
    PROVINCE=`awk -F = 'NR==3 {printf $2}' version`
    OPERATOR=`awk -F = 'NR==4 {printf $2}' version`
    INCREMENTALVER=`awk -F = 'NR==5 {printf $2}' version`    
    SVNUMBER=`awk -F = 'NR==6 {printf $2}' version`
    TIME=`date +%F`
    BUILDDATE=`echo $INCREMENTALVER | sed -r 's/^[^-]*-//'`
    ASUSVERSION=`echo $INCREMENTALVER | sed -r '{s/^[^-]*-//;s/-[^-]*$//}'`
    WDBUILDDATE=`echo $INCREMENTALVER | sed -r '{s/^[^-]*-//;s/^[^-]*-//}'`
    echo INNER VERSION IS $INVER
    echo OUTER VERSION IS $OUTVER
    echo PROVINCE NAME IS $PROVINCE
    echo OPERATOR NAME IS $OPERATOR
    echo RELEASE TIME IS $TIME
    echo INCREMENTAL VERSION IS $INCREMENTALVER    
    echo SV NUMBER IS $SVNUMBER
    echo BUILD DATE IS $BUILDDATE
    echo ASUS VERSION IS $ASUSVERSION
    export VER_INNER=$INVER
    export VER_OUTER=$OUTVER
    export PROVINCE_NAME=$PROVINCE
    export OPERATOR_NAME=$OPERATOR
    export RELEASE_TIME=$TIME
    export WIND_CPUCORES=$CPUCORE
    export VER_INCREMENTAL=$INCREMENTALVER
    export SV_NUMBER=$SVNUMBER    
    export WIND_PROJECT_NAME_CUSTOM=$CONFIG_NAME
    export WIND_DEXPREOPT_OPTION=$WIND_DEXPREOPT_OPTION    
    export WIND_EFUSE_UNSIGN=$EFUSE_UNSIGN
    export WIND_CHIP=$CHIP
    export WIND_BUILD_MODE=$BUILD_MODE
    export WIND_FACTORY_BUILD=$WIND_FACTORY_BUILD
    export WIND_NO_GMS=$WIND_NO_GMS
    export BUILDDATE
    export ASUSVERSION
    export WDBUILDDATE
}

PRODUCT=
VARIANT=
ACTION=
MODULE=
ORIGINAL=
COPYFILES=
CONFIG_NAME=
BUILD_MODE=
CLEAN=
DEPEND=
CHIPID_DIR=
efuse_sign_files=
ALL_EFUSE_SIGN_FILES=
BASE_FILES=
SIGN_FILES=
PROP=
OTA_BUILD=


function copy_custom_files()
{
    echo "Start copy files..."
    result=0
    cd $WsRootDir/vendor/qcom/proprietary/
    git checkout . && git clean -df
    cd -
    case $PRODUCT in
        E300L_CN|E300L_WW|A306)
        cp -a $CUSTOM_FILES_PATH/* ./
        cd $WsRootDir/vendor/qcom/proprietary/
        cp -a $PROP/* .
        rm -rf E300L A306
        cd -
        result=$?
        ;;
        *)
        echo "!!!!!!   Nothing to copy   !!!!"
        ;;
    esac

    if [ $result -eq 1 ]; then
        echo -e "\033[31m Copy files error!!! \033[0m"
        exit 1
    else
        echo "Copy special files finish!"
    fi
}

function copy_tz_files()
{
    echo "Start copy tz files..."
    TZ_FILES=tz_files
    if [ -d "$amssPath/$TZ_FILES/$CHIP" ];then
        rm -rf $amssPath/$TZ_FILES/$CHIP
    fi
    mkdir -p $amssPath/$TZ_FILES/$CHIP
	
    cp $SIGN_FILES/$CHIP/cppf/cppf* $amssPath/$TZ_FILES/$CHIP/
    cp $SIGN_FILES/$CHIP/widevine/widevine* $amssPath/$TZ_FILES/$CHIP/
    if [ x"$BUILD_MODE" == x"overall" ];then
        mkdir -p $amssPath/$TZ_FILES/8937
        cp $SIGN_FILES/tz/8937/cppf/cppf* $amssPath/$TZ_FILES/8937/
        cp $SIGN_FILES/tz/8937/widevine/widevine* $amssPath/$TZ_FILES/8937/
        rm $amssPath/$TZ_FILES/8937/*.mbn
    fi
    rm $amssPath/$TZ_FILES/$CHIP/*.mbn
    echo "Copy TZ files finish!"
}

clean_kernel()
{
    if [ x$ORIGINAL == x"yes" ]; then
        rm $LOG_PATH/k.log; make clean-kernel
        return $?
    else
        OUT_PATH=$WsRootDir/out/target/product/$PRODUCT
        KERNEL_OUT_PATH=$OUT_PATH/obj/KERNEL_OBJ
        rm -f $LOG_PATH/k.log
        rm -f $OUT_PATH/boot.img
        rm -rf $KERNEL_OUT_PATH
        result=$?
        return $result
    fi
}
build_kernel()
{
    if [ x$ORIGINAL == x"yes" ]; then
        make -j$CPUCORE kernel 2>&1 | tee $LOG_PATH/k.log
        return $?
    else
        cd kernel/msm-3.18
        kernelproduct=$PRODUCT
        if [ x"64" == x"$(echo $PRODUCT | sed -r 's/^.+_//')" ];then
            kernelproduct=$(echo $PRODUCT | sed -r 's/_[^_]+$//')
        fi
        echo "kernelproduct=$kernelproduct"
        if [ x$VARIANT == x"user" ] || [ x$VARIANT == x"userroot" ];then
            defconfig_files=${kernelproduct}-perf_defconfig
        else
            defconfig_files=${kernelproduct}_defconfig
        fi
        KERNEL_OUT_PATH=../../out/target/product/$PRODUCT/obj/KERNEL_OBJ
        mkdir -p $KERNEL_OUT_PATH
        while [ 1 ]; do
            make O=$KERNEL_OUT_PATH ARCH=$ARM ${defconfig_files}
            result=$?; if [ x$result != x"0" ];then break; fi
            #make -j$CPUCORE -k O=$KERNEL_OUT_PATH Image modules
        if [ x$VARIANT == x"userroot" ] ; then
            make QCOM_BUILD_ROOT=yes -j$CPUCORE O=$KERNEL_OUT_PATH ARCH=$ARM CROSS_COMPILE=$WsRootDir/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android- 2>&1 | tee $LOG_PATH/k.log
        else
            make -j$CPUCORE O=$KERNEL_OUT_PATH ARCH=$ARM CROSS_COMPILE=$WsRootDir/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android- 2>&1 | tee $LOG_PATH/k.log
        fi
        result=$?; if [ x$result != x"0" ];then break; fi
            if [ x$ARM == x"arm" ];then
            cp $KERNEL_OUT_PATH/arch/arm/boot/zImage ../../out/target/product/$PRODUCT/kernel
            else
            cp $KERNEL_OUT_PATH/arch/arm64/boot/Image.gz ../../out/target/product/$PRODUCT/kernel
            fi
            break
        done
        cd -
        cp $OUT_PATH/kernel /data/mine/test/MT6572/$MY_NAME/
        return $result
    fi
}

clean_lk()
{
    if [ x$ORIGINAL == x"yes" ]; then
        rm $LOG_PATH/lk.log; make clean-lk
        return $?
    else
        OUT_PATH=$WsRootDir/out/target/product/$PRODUCT
        LK_OUT_PATH=$OUT_PATH/obj/EMMC_BOOTLOADER_OBJ
        rm -f $LOG_PATH/lk.log
        rm -f $OUT_PATH/lk.bin $OUT_PATH/logo.bin
        rm -rf $LK_OUT_PATH
        result=$?
        return $result
    fi
}
build_lk()
{
    if [ x$ORIGINAL == x"yes" ]; then
        make -j$CPUCORE lk 2>&1 | tee $LOG_PATH/lk.log
        return $?
    else
        bootloaderproduct=$PRODUCT
        if [ x"msm8937" == x"$(echo $DEPEND | sed -r 's/_[^_]+$//')" ];then
            bootloaderproduct=msm8952
        fi
        echo "bootloaderproduct=$bootloaderproduct"
        OUT_PATH=$WsRootDir/out/target/product/$PRODUCT
        LK_OUT_PATH=$OUT_PATH/obj/EMMC_BOOTLOADER_OBJ
        mkdir -p $LK_OUT_PATH
        cd bootable/bootloader/lk
        #export BOOTLOADER_OUT=$LK_OUT_PATH
        #export MTK_PUMP_EXPRESS_SUPPORT=yes
        if [ x$VARIANT == x"userroot" ] ; then
            make QCOM_BUILD_ROOT=yes -j$CPUCORE TOOLCHAIN_PREFIX=$WsRootDir/prebuilts/gcc/linux-x86/arm/arm-eabi-4.8/bin/arm-eabi- BOOTLOADER_OUT=$LK_OUT_PATH $bootloaderproduct 2>&1 | tee $LOG_PATH/lk.log
        else
            make -j$CPUCORE TOOLCHAIN_PREFIX=$WsRootDir/prebuilts/gcc/linux-x86/arm/arm-eabi-4.8/bin/arm-eabi- BOOTLOADER_OUT=$LK_OUT_PATH $bootloaderproduct 2>&1 | tee $LOG_PATH/lk.log
        fi
        result=$?
        cd -
        cp $LK_OUT_PATH/build-$bootloaderproduct/lk.bin $OUT_PATH
        #cp $LK_OUT_PATH/build-$bootloaderproduct/logo.bin $OUT_PATH
        cp $OUT_PATH/lk.bin /data/mine/test/MT6572/$MY_NAME/
        return $result
    fi
}


function build_android()
{
    cd $WsRootDir
    if [ x$VARIANT == x"" ];then VARIANT=eng; fi
    if [ x$ORIGINAL == x"" ];then ORIGINAL=no; fi
    if [ x$ACTION == x"clean" ];then RELEASE_PARAM=none; fi

    echo "********This build project CONFIG_NAME is $CONFIG_NAME********"
    echo "PRODUCT=$PRODUCT VARIANT=$VARIANT ACTION=$ACTION MODULE=$MODULE COPYFILES=$COPYFILES ORIGINAL=$ORIGINAL DEXPREOPT_OPTION=$WIND_DEXPREOPT_OPTION CLEAN=$CLEAN"
    echo "Log Path $LOG_PATH"

    if [ x$PRODUCT == x"" ];then
        echo  -e "\033[31m !!!!!!   No Such Product   !!!! \033[0m"
        exit 1
    fi
    if [ x$ACTION == x"" ];then
        echo  -e "\033[31m !!!!!!   No Such Action   !!!! \033[0m"
        exit 1
    fi

    ##################################################################
    #Prepare
    ##################################################################
    Check_Space

    #if [ x$PRODUCT == x"E300L_CN" ] || [ x$PRODUCT == x"E300L_WW" ];then
    #    cd device/wind/$PRODUCT
    #    for f in `ls ../../qcom/$DEPEND/`; do ln -s ../../qcom/$DEPEND/$f $f; done
    #    cd $WsRootDir
    #fi
    check_product=$(echo $CONFIG_NAME | sed -r 's/^[^_]*_//')
    echo "check_product $check_product"
    NEW_PRODUCT=$CONFIG_NAME
    echo "NEW_PRODUCT $NEW_PRODUCT"

    build_version

    echo "WIND_EFUSE_UNSIGN=$WIND_EFUSE_UNSIGN"
    echo "WIND_CHIP=$WIND_CHIP"
    echo "WIND_BUILD_MODE=$WIND_BUILD_MODE"

    ###################################################################
    #Start build
    ###################################################################
    echo "Build started `date +%Y%m%d_%H%M%S` ..."
    echo;echo;echo;echo
    export PATH="/usr/lib/jvm/java-8-openjdk-amd64/bin":$PATH

    source build/envsetup.sh
    if [ x$VARIANT == x"userroot" ] ; then
        lunch $PRODUCT-user
    else    
        lunch $PRODUCT-$VARIANT
    fi    
    OUT_PATH=$WsRootDir/out/target/product/$PRODUCT
    case $ACTION in
        new | remake | clean)

        M=false; C=false;
        if [ x$ACTION == x"new" ];then M=true; C=true;
        elif [ x$ACTION == x"remake" ];then
          M=true;
          find $OUT_PATH/ -name 'build.prop' -exec rm -rf {} \;
          find $OUT_PATH/ -name 'default.prop' -exec rm -rf {} \;
        else C=true;
        fi

        case $MODULE in
            pl)
            if [ x$C == x"true" ];then clean_pl; result=$?; fi
            if [ x$M == x"true" ];then build_pl; result=$?; fi
            ;;

            k)
            if [ x$C == x"true" ];then clean_kernel; result=$?; fi
            if [ x$M == x"true" ];then
                build_kernel; result=$?
                echo $result
                if [ $result -eq 0 ];then
                    make -j$CPUCORE bootimage-nodeps; result=$?;
                    cp $OUT_PATH/boot.img /data/mine/test/MT6572/$MY_NAME/
                fi
            fi
            ;;

            lk)
            if [ x$C == x"true" ];then clean_lk; result=$?; fi
            if [ x$M == x"true" ];then build_lk; result=$?; fi
            ;;

            *)
            if [ x"$MODULE" == x"" ];then
                if [ x$C == x"true" ];then
                    echo "make clean"
                    make clean; result=$?;
                    #rm -rf $LOG_PATH/*;
                fi
                #echo "`date +"%F %T"`	./quick_build.sh $1 $2 $3 $4 $5" >> $LOG_PATH/record.log
                if [ x$M == x"true" ];then 
                    if [ x$VARIANT == x"userroot" ] ; then
                        echo "make userroot version"
                        make QCOM_BUILD_ROOT=yes -j$CPUCORE 2>&1 | tee $LOG_PATH/android.log; result=$?; 
                    else
                        echo "make build project"
                        make -j$CPUCORE 2>&1 | tee $LOG_PATH/android.log; result=$?;
                    fi
                fi
            else
                echo  -e "\033[31m !!!!!!   No Such module   !!!! \033[0m"
                exit 1
            fi
            ;;
        esac
        ;;
                
        mmma | mmm)
        $ACTION $MODULE 2>&1 | tee $LOG_PATH/$ACTION.log; result=$?
        ;;

        asusfw_otapackage)
        full_package_zip=$(find $OUT_PATH/ -name ${PRODUCT}-target_files-*.zip)
        full_package=`echo $full_package_zip | sed -e 's/.zip//'`
        echo "$full_package_zip $full_package"
        if [ -f "$full_package_zip" ] ;then
            echo "build this ota_from_target_files ...."
            ./build/tools/releasetools/ota_from_target_files -v --block --extracted_input_target_files $full_package -p out/host/linux-x86 -k build/target/product/security/wind/releasekey --asusfw $full_package_zip out/target/product/$PRODUCT/$PRODUCT-ota-asusfw-$VARIANT.zip; result=$?
        else
            echo "build make ...."
            make -j$CPUCORE $ACTION 2>&1 | tee $LOG_PATH/$ACTION.log; result=$?

            cd $amssPath/$CHIPID_DIR/common/build/bin/asic/sparse_images
            python $WsRootDir/amss/BOOT.BF.3.3/boot_images/core/storage/tools/ptool/checksparse.py -i ./../../../rawprogram0.xml -s $WsRootDir/out/target/product/$PRODUCT/ -o rawprogram_unsparse.xml
            cd $WsRootDir
        fi
        ;;

        update-api | aboot | bootimage | systemimage | recoveryimage | vendorimage | userdataimage | cacheimage-nodeps | snod | vnod | bootimage-nodeps | userdataimage-nodeps | ramdisk-nodeps | otapackage | cts  | apdimage | apdimage-nodeps |xromimage)
        make -j$CPUCORE $ACTION 2>&1 | tee $LOG_PATH/$ACTION.log; result=$?
        if [ x"$ACTION" == x"otapackage" ];then
            cd $amssPath/$CHIPID_DIR/common/build/bin/asic/sparse_images
            python $WsRootDir/amss/BOOT.BF.3.3/boot_images/core/storage/tools/ptool/checksparse.py -i ./../../../rawprogram0.xml -s $WsRootDir/out/target/product/$PRODUCT/ -o rawprogram_unsparse.xml
            cd $WsRootDir
        fi
        ;;
    esac

    log_path=$LOG_PATH/android.log
    compile_flag=$(grep -rsn "make completed successfully" $log_path | cut -d ":" -f 1)

    if [ x"$compile_flag" == x ];then
        echo -e "\033[40;31m Build android error \033[0m"
        exit 1
    fi

    if [ $result -eq 0 ] && [ x$ACTION == x"mmma" -o x$ACTION == x"mmm" ];then
        echo "Start to release module ...."
        DIR=`echo $MODULE | sed -e 's/:.*//' -e 's:/$::'`
        NAME=${DIR##*/}
        TARGET=out/target/product/${PRODUCT}/obj/APPS/${NAME}_intermediates/package.apk
        if [ -f $TARGET ];then
            cp -f $TARGET /data/mine/test/MT6572/${MY_NAME}/${NAME}.apk
        fi
    elif [ $result -eq 0 ] && [ $RELEASE_PARAM != "none" ] && [ x"$auto_flag" != x"yes" ]; then
        echo "Build completed `date +%Y%m%d_%H%M%S` ..."
        echo "Start to release version ...."
        if [ -f boot_su.img ];then
            cp boot_su.img $OUT_PATH/
        fi
    fi
}

function Check_Space()
{
    UserHome=`pwd`
    Space=0
    Temp=`echo ${UserHome#*/}`
    Temp=`echo ${Temp%%/*}`
    ServerSpace=`df -lh $UserHome | grep "$Temp" | awk '{print $4}'`

    if echo $ServerSpace | grep -q 'G'; then
        Space=`echo ${ServerSpace%%G*}`
    elif echo $ServerSpace | grep -q 'T';then
        TSpace=1
    fi

    echo -e "\033[34m Log for Space $UserHome $ServerSpace $Space !!!\033[0m"
    if [ x"$TSpace" != x"1" ] ;then
        if [ "$Space" -le "30" ];then
            echo -e "\033[31m No Space!! Please Check!! \033[0m"
            exit 1
        fi  
    fi
}

function build_pl(){
	echo "========== build BOOT.BF.3.3 =========="
#	echo "archermind" | sudo -S ntpdate 10.20.26.73
	cd $amssPath/BOOT.BF.3.3/boot_images/build/ms/
	echo "start build boot_image"
	source ./setenv.sh
	if [ x$CLEAN == x"c" ];then
		if [ x$CHIP == x"8917" ];then
			./build.sh TARGET_FAMILY=8917 --prod -c
		else
			./build.sh TARGET_FAMILY=8937 --prod -c
		fi
	else
		if [ x"$BUILD_MODE" == x"overall" ];then
		git clean -df && git checkout .
		cp -a $WsRootDir/vendor/wind/custom_files/amss/* $amssPath/
		fi
		if [ x$CHIP == x"8917" ];then
			./build.sh TARGET_FAMILY=8917 --prod 2>&1|tee $LOG_PATH/boot_8917.log
		else
			./build.sh TARGET_FAMILY=8937 --prod 2>&1|tee $LOG_PATH/boot_8937.log
		fi
		if [ "`grep "Successfully compile $CHIP" $LOG_PATH/boot_$CHIP.log`" ];then
			echo -e "\033[40;32m Build BOOT.BF.3.3 Successfully \033[0m"
			sleep 2
		else
			echo "archermind" | sudo -S ntpdate us.pool.ntp.org
			echo -e "\033[40;31m Build BOOT.BF.3.3 failed (>.<) \033[0m"
			exit 1
		fi
	fi
	echo "archermind" | sudo -S ntpdate us.pool.ntp.org
}

function build_mpss(){
	echo "========== build MPSS.JO.3.0 =========="
	if [ x$PRODUCT == x"A306" ];then
		modem_path=MPSS.JO.3.0_A306
	else
		modem_path=MPSS.JO.3.0
	fi
	cd $amssPath/$modem_path/modem_proc/build/ms
	echo "set environment"
	source setenv.sh
	if [ x$CHIP == x"8917" ];then
		cp $amssPath/$modem_path/modem_proc/core/storage/fs_tar/src/fs_signed_img_param_8917.c $amssPath/$modem_path/modem_proc/core/storage/fs_tar/src/fs_signed_img_param.c
		cd $amssPath/$modem_path/modem_proc/mcfg/configs/mcfg_sw
		git checkout . && git clean -df
		cp -a $WsRootDir/vendor/wind/custom_files/amss/$modem_path/modem_proc/mcfg/configs/mcfg_sw/generic_17/* ./generic
		rm -rf generic_17 
		rm -rf generic_37
		cd -
	elif [ x$CHIP == x"8937" ];then
		cp $amssPath/$modem_path/modem_proc/core/storage/fs_tar/src/fs_signed_img_param_8937.c $amssPath/$modem_path/modem_proc/core/storage/fs_tar/src/fs_signed_img_param.c
		cd $amssPath/$modem_path/modem_proc/mcfg/configs/mcfg_sw
		git checkout . && git clean -df
		cp -a $WsRootDir/vendor/wind/custom_files/amss/$modem_path/modem_proc/mcfg/configs/mcfg_sw/generic_37/* ./generic
		rm -rf generic_37
		rm -rf generic_17
		cd -
	fi
	echo "start build mpss"
	if [ x$CLEAN == x"c" ];then
		./build.sh 8937.genns.prod -c
	else
		./build.sh 8937.genns.prod -k 2>&1|tee $LOG_PATH/mpss.log
		if [ "`grep "Build 8937.genns.prod returned code 0" $LOG_PATH/mpss.log`"  ];then
			echo -e "\033[40;32m Build MPSS.JO.3.0 Successfully \033[0m"
			sleep 2
		else
			echo -e "\033[40;31m Build MPSS.JO.3.0 failed (>.<) \033[0m"
			exit 1
		fi
	fi
}

function build_rpm(){
	echo "========== build RPM.BF.2.2 =========="
	cd $amssPath/RPM.BF.2.2/rpm_proc/build
	source ./setenv.sh
	if [ x$CLEAN == x"c" ];then
		if [ x$CHIP == x"8917" ];then
			./build_8917.sh -c
		else
			./build_8937.sh -c
		fi
	else
		if [ x"$BUILD_MODE" == x"overall" ];then
		git clean -df  && git checkout .
		cp -a $WsRootDir/vendor/wind/custom_files/amss/* $amssPath/
		fi
#echo "archermind" | sudo -S ntpdate 10.20.26.73
		if [ x$CHIP == x"8917" ];then
			./build_8917.sh 2>&1|tee $LOG_PATH/rpm_proc_8917.log
		else
			./build_8937.sh 2>&1|tee $LOG_PATH/rpm_proc_8937.log
		fi
	echo "archermind" | sudo -S ntpdate us.pool.ntp.org
		if [ "`grep "done building targets" $LOG_PATH/rpm_proc_$CHIP.log`" ];then
			echo -e "\033[40;32m Build RPM.BF.2.2 Successfully \033[0m"
			sleep 2
		else
			echo -e "\033[40;31m Build RPM.BF.2.2 failed (>.<) \033[0m"
			exit 1
		fi
	fi
}

function build_tz(){
	echo "========== build TZ.BF.4.0.5 =========="
	if [ x$PRODUCT == x"E300L_WW" ];then
		cd $amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms
	elif [ x$PRODUCT == x"A306" ];then
		cd $amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms
	else
		cd $amssPath/TZ.BF.4.0.5/trustzone_images/build/ms
	fi
	if [ x$CLEAN == x"c" ];then
		./build.sh CHIPSET=msm8937 devcfg sampleapp -c
	else
		./build.sh CHIPSET=msm8937 devcfg sampleapp -c
		if [ x$PRODUCT == x"E300L_WW" ] || [ x$PRODUCT == x"A306" ];then
			./build.sh CHIPSET=msm8937 devcfg sampleapp 2>&1|tee $LOG_PATH/tz_8917.log
		else
			./build.sh CHIPSET=msm8937 devcfg sampleapp 2>&1|tee $LOG_PATH/tz_8937.log
		fi

		if [ x$PRODUCT == x"E300L_WW" ] || [ x$PRODUCT == x"A306" ];then
		if [ "`grep "done building targets" $LOG_PATH/tz_8917.log`" ];then
			echo -e "\033[40;32m Build TZ.BF.4.0.5 Successfully \033[0m"
			sleep 2
		else
			echo -e "\033[40;31m Build TZ.BF.4.0.5 failed (>.<) \033[0m"
			exit 1
		fi
		else
		if [ "`grep "done building targets" $LOG_PATH/tz_$CHIP.log`" ];then
			echo -e "\033[40;32m Build TZ.BF.4.0.5 Successfully \033[0m"
			sleep 2
		else
			echo -e "\033[40;31m Build TZ.BF.4.0.5 failed (>.<) \033[0m"
			exit 1
		fi
		fi
	fi

}

function build_adsp(){
	echo "========== ADSP.8953.2.8.4 ==========" 
	if [ x$PRODUCT == x"E300L_WW" ];then
		cd $amssPath/ADSP.8953.2.8.4_WW/adsp_proc
	elif [ x$PRODUCT == x"A306" ];then
		cd $amssPath/ADSP.8953.2.8.4_A306/adsp_proc
	else
		cd $amssPath/ADSP.8953.2.8.4/adsp_proc
	fi
	source ./build/setenv.sh
	if [ x$CLEAN == x"c" ];then
		python ./build/build.py -c msm8937 -o clean
	else
		if [ x$PRODUCT == x"E300L_WW" ] || [ x$PRODUCT == x"A306" ];then
			python ./build/build.py -c msm8937 -o all 2>&1|tee $LOG_PATH/adsp_8917.log
		else
			python ./build/build.py -c msm8937 -o all 2>&1|tee $LOG_PATH/adsp_8937.log
		fi
		#./build/build.sh 2>&1|tee $LOG_PATH/adsp.log
		if [ x$PRODUCT == x"E300L_WW" ] || [ x$PRODUCT == x"A306" ];then
		if [ "`grep "Compilation SUCCESS" $LOG_PATH/adsp_8917.log`" ];then
			echo -e "\033[40;32m Build ADSP.8953.2.8.4 Successfully \033[0m"
			sleep 2
		else
			echo -e "\033[40;31m Build ADSP.8953.2.8.4 failed (>.<) \033[0m"
			exit 1
		fi
		else
		if [ "`grep "Compilation SUCCESS" $LOG_PATH/adsp_$CHIP.log`" ];then
			echo -e "\033[40;32m Build ADSP.8953.2.8.4 Successfully \033[0m"
			sleep 2
		else
			echo -e "\033[40;31m Build ADSP.8953.2.8.4 failed (>.<) \033[0m"
			exit 1
		fi
		fi
	fi
}

efuse_sign_8917=(
$amssPath/ADSP.8953.2.8.4_WW/adsp_proc/obj/8937/signed/adsp.mbn
$amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/cmnlib_30.mbn
$amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/cmnlib64_30.mbn
$amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/cppf.mbn
$amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/devcfg.mbn
$amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/dhsecapp.mbn
$amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/fingerprint.mbn
$amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/fingerprint64.mbn
$amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/isdbtmm.mbn
$amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/keymaster64.mbn
$amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/widevine.mbn
$amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/mdtp.mbn
$amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/smplap32.mbn
$amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/smplap64.mbn
$amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/qmpsecap.mbn
$amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/tz.mbn
$amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/securemm.mbn
$amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/gptest.mbn
$amssPath/RPM.BF.2.2/rpm_proc/build/ms/bin/8917/rpm.mbn
$amssPath/BOOT.BF.3.3/boot_images/build/ms/bin/LAADANAZ/prog_emmc_firehose_8917_ddr.mbn
$amssPath/BOOT.BF.3.3/boot_images/build/ms/bin/LAASANAZ/sbl1.mbn
$amssPath/VIDEO.VE_ULT.3.1/venus_proc/build/bsp/asic/build/PROD/mbn/reloc/signed/venus.mbn
$amssPath/CNSS.PR.4.0/wcnss_proc/build/ms/bin/8937/reloc/wcnss.mbn
$amssPath/MPSS.JO.3.0/modem_proc/build/ms/bin/8937.genns.prod/mba.mbn
$amssPath/MPSS.JO.3.0/modem_proc/build/ms/bin/8937.genns.prod/mcfg_sw.mbn
$amssPath/MPSS.JO.3.0/modem_proc/build/ms/bin/8937.genns.prod/mcfg_hw.mbn
$amssPath/MPSS.JO.3.0/modem_proc/build/ms/bin/8937.genns.prod/qdsp6sw.mbn
)

efuse_sign_8917_a306=(
$amssPath/ADSP.8953.2.8.4_A306/adsp_proc/obj/8937/signed/adsp.mbn
$amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/cmnlib_30.mbn
$amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/cmnlib64_30.mbn
$amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/cppf.mbn
$amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/devcfg.mbn
$amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/dhsecapp.mbn
$amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/fingerprint.mbn
$amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/fingerprint64.mbn
$amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/isdbtmm.mbn
$amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/keymaster64.mbn
$amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/widevine.mbn
$amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/mdtp.mbn
$amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/smplap32.mbn
$amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/smplap64.mbn
$amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/qmpsecap.mbn
$amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/tz.mbn
$amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/securemm.mbn
$amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/gptest.mbn
$amssPath/RPM.BF.2.2/rpm_proc/build/ms/bin/8917/rpm.mbn
$amssPath/BOOT.BF.3.3/boot_images/build/ms/bin/LAADANAZ/prog_emmc_firehose_8917_ddr.mbn
$amssPath/BOOT.BF.3.3/boot_images/build/ms/bin/LAASANAZ/sbl1.mbn
$amssPath/VIDEO.VE_ULT.3.1/venus_proc/build/bsp/asic/build/PROD/mbn/reloc/signed/venus.mbn
$amssPath/CNSS.PR.4.0/wcnss_proc/build/ms/bin/8937/reloc/wcnss.mbn
$amssPath/MPSS.JO.3.0_A306/modem_proc/build/ms/bin/8937.genns.prod/mba.mbn
$amssPath/MPSS.JO.3.0_A306/modem_proc/build/ms/bin/8937.genns.prod/mcfg_sw.mbn
$amssPath/MPSS.JO.3.0_A306/modem_proc/build/ms/bin/8937.genns.prod/mcfg_hw.mbn
$amssPath/MPSS.JO.3.0_A306/modem_proc/build/ms/bin/8937.genns.prod/qdsp6sw.mbn
)

efuse_sign_8937_in=(
$amssPath/ADSP.8953.2.8.4_WW/adsp_proc/obj/8937/signed/adsp.mbn
$amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/tz.mbn
$amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/smplap32.mbn
$amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/smplap64.mbn
$amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/widevine.mbn
$amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/isdbtmm.mbn
$amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/cppf.mbn
$amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/fingerprint.mbn
$amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/devcfg.mbn
$amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/keymaster64.mbn
$amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/cmnlib_30.mbn
$amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/cmnlib64_30.mbn
$amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/securemm.mbn
$amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/gptest.mbn
$amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/dhsecapp.mbn
$amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/qmpsecap.mbn
$amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/fingerprint64.mbn
$amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/mdtp.mbn
$amssPath/RPM.BF.2.2/rpm_proc/build/ms/bin/8937/rpm.mbn
$amssPath/CNSS.PR.4.0/wcnss_proc/build/ms/bin/8937/reloc/wcnss.mbn
$amssPath/VIDEO.VE_ULT.3.1/venus_proc/build/bsp/asic/build/PROD/mbn/reloc/signed/venus.mbn
$amssPath/BOOT.BF.3.3/boot_images/build/ms/bin/FAASANAZ/sbl1.mbn
$amssPath/BOOT.BF.3.3/boot_images/build/ms/bin/FAADANAZ/prog_emmc_firehose_8937_ddr.mbn
$amssPath/MPSS.JO.3.0/modem_proc/build/ms/bin/8937.genns.prod/qdsp6sw.mbn
$amssPath/MPSS.JO.3.0/modem_proc/build/ms/bin/8937.genns.prod/mba.mbn
$amssPath/MPSS.JO.3.0/modem_proc/build/ms/bin/8937.genns.prod/mcfg_hw.mbn
$amssPath/MPSS.JO.3.0/modem_proc/build/ms/bin/8937.genns.prod/mcfg_sw.mbn
)

efuse_sign_8937=(
$amssPath/ADSP.8953.2.8.4/adsp_proc/obj/8937/signed/adsp.mbn
$amssPath/TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/tz.mbn
$amssPath/TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/smplap32.mbn
$amssPath/TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/smplap64.mbn
$amssPath/TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/widevine.mbn
$amssPath/TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/isdbtmm.mbn
$amssPath/TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/cppf.mbn
$amssPath/TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/fingerprint.mbn
$amssPath/TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/devcfg.mbn
$amssPath/TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/keymaster64.mbn
$amssPath/TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/cmnlib_30.mbn
$amssPath/TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/cmnlib64_30.mbn
$amssPath/TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/securemm.mbn
$amssPath/TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/gptest.mbn
$amssPath/TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/dhsecapp.mbn
$amssPath/TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/qmpsecap.mbn
$amssPath/TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/fingerprint64.mbn
$amssPath/TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/mdtp.mbn
$amssPath/RPM.BF.2.2/rpm_proc/build/ms/bin/8937/rpm.mbn
$amssPath/CNSS.PR.4.0/wcnss_proc/build/ms/bin/8937/reloc/wcnss.mbn
$amssPath/VIDEO.VE_ULT.3.1/venus_proc/build/bsp/asic/build/PROD/mbn/reloc/signed/venus.mbn
$amssPath/BOOT.BF.3.3/boot_images/build/ms/bin/FAASANAZ/sbl1.mbn
$amssPath/BOOT.BF.3.3/boot_images/build/ms/bin/FAADANAZ/prog_emmc_firehose_8937_ddr.mbn
$amssPath/MPSS.JO.3.0/modem_proc/build/ms/bin/8937.genns.prod/qdsp6sw.mbn
$amssPath/MPSS.JO.3.0/modem_proc/build/ms/bin/8937.genns.prod/mba.mbn
$amssPath/MPSS.JO.3.0/modem_proc/build/ms/bin/8937.genns.prod/mcfg_hw.mbn
$amssPath/MPSS.JO.3.0/modem_proc/build/ms/bin/8937.genns.prod/mcfg_sw.mbn
)

efuse_sign_8937_a307=(
$amssPath/ADSP.8953.2.8.4_A306/adsp_proc/obj/8937/signed/adsp.mbn
$amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/tz.mbn
$amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/smplap32.mbn
$amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/smplap64.mbn
$amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/widevine.mbn
$amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/isdbtmm.mbn
$amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/cppf.mbn
$amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/fingerprint.mbn
$amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/devcfg.mbn
$amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/keymaster64.mbn
$amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/cmnlib_30.mbn
$amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/cmnlib64_30.mbn
$amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/securemm.mbn
$amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/gptest.mbn
$amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/dhsecapp.mbn
$amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/qmpsecap.mbn
$amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/fingerprint64.mbn
$amssPath/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/mdtp.mbn
$amssPath/RPM.BF.2.2/rpm_proc/build/ms/bin/8937/rpm.mbn
$amssPath/CNSS.PR.4.0/wcnss_proc/build/ms/bin/8937/reloc/wcnss.mbn
$amssPath/VIDEO.VE_ULT.3.1/venus_proc/build/bsp/asic/build/PROD/mbn/reloc/signed/venus.mbn
$amssPath/BOOT.BF.3.3/boot_images/build/ms/bin/FAASANAZ/sbl1.mbn
$amssPath/BOOT.BF.3.3/boot_images/build/ms/bin/FAADANAZ/prog_emmc_firehose_8937_ddr.mbn
$amssPath/MPSS.JO.3.0_A306/modem_proc/build/ms/bin/8937.genns.prod/qdsp6sw.mbn
$amssPath/MPSS.JO.3.0_A306/modem_proc/build/ms/bin/8937.genns.prod/mba.mbn
$amssPath/MPSS.JO.3.0_A306/modem_proc/build/ms/bin/8937.genns.prod/mcfg_hw.mbn
$amssPath/MPSS.JO.3.0_A306/modem_proc/build/ms/bin/8937.genns.prod/mcfg_sw.mbn
)

ALL_EFUSE_SIGN_FILES="adsp.mbn cmnlib_30.mbn cmnlib64_30.mbn cppf.mbn devcfg.mbn dhsecapp.mbn fingerprint.mbn fingerprint64.mbn isdbtmm.mbn keymaster64.mbn widevine.mbn mdtp.mbn smplap32.mbn smplap64.mbn qmpsecap.mbn tz.mbn securemm.mbn gptest.mbn rpm.mbn sbl1.mbn venus.mbn wcnss.mbn mba.mbn mcfg_sw.mbn mcfg_hw.mbn qdsp6sw.mbn emmc_appsboot.mbn"

#配置参数属性
function confi_prop(){
cd $WsRootDir
if [ x$PRODUCT == x"E300L_WW" ] && [ x$CHIP == x"8917" ];then
CHIPID_DIR=MSM8917.LA.3.0.1
efuse_sign_files=(${efuse_sign_8917[@]})
ALL_EFUSE_SIGN_FILES=${ALL_EFUSE_SIGN_FILES}" prog_emmc_firehose_8917_ddr.mbn"
elif [ x$PRODUCT == x"A306" ] && [ x$CHIP == x"8917" ];then
CHIPID_DIR=MSM8917.LA.3.0.1
efuse_sign_files=(${efuse_sign_8917_a306[@]})
ALL_EFUSE_SIGN_FILES=${ALL_EFUSE_SIGN_FILES}" prog_emmc_firehose_8917_ddr.mbn"
elif [ x$PRODUCT == x"E300L_WW" ] && [ x$CHIP == x"8937" ];then
CHIPID_DIR=MSM8937.LA.3.0.1
efuse_sign_files=(${efuse_sign_8937_in[@]})
ALL_EFUSE_SIGN_FILES=${ALL_EFUSE_SIGN_FILES}" prog_emmc_firehose_8937_ddr.mbn"
elif [ x$PRODUCT == x"A306" ] && [ x$CHIP == x"8937" ];then
CHIPID_DIR=MSM8937.LA.3.0.1
efuse_sign_files=(${efuse_sign_8937_a307[@]})
ALL_EFUSE_SIGN_FILES=${ALL_EFUSE_SIGN_FILES}" prog_emmc_firehose_8937_ddr.mbn"
else
CHIPID_DIR=MSM8937.LA.3.0.1
efuse_sign_files=(${efuse_sign_8937[@]})
ALL_EFUSE_SIGN_FILES=${ALL_EFUSE_SIGN_FILES}" prog_emmc_firehose_8937_ddr.mbn"
fi
BASE_FILES=$amssPath/base_files_$CHIP
SIGN_FILES=$amssPath/sign_files
}

#efuse sign签名
function build_sign(){
cd $WsRootDir
OUT_PATH=$WsRootDir/out/target/product/$PRODUCT

if [ -d $BASE_FILES ];then
	rm -rf $BASE_FILES
fi
mkdir -p $BASE_FILES
for file in ${efuse_sign_files[*]}
do
	if [ -f "$file" ];then
		cp $file $BASE_FILES
	else
		echo -e "Backup error: can't found $file"
		#exit 1
	fi
done
cp $amssPath/$CHIPID_DIR/common/sectools/resources/build/fileversion2/sec.dat $BASE_FILES

if [ -d $SIGN_FILES ];then
	rm -rf $SIGN_FILES/$CHIP
else
	mkdir -p $SIGN_FILES
fi

python $amssPath/$CHIPID_DIR/common/sectools/sectools.py secimage  -m $amssPath/$CHIPID_DIR  -p $CHIP -o $SIGN_FILES -sa
#python $amssPath/$CHIPID_DIR/common/sectools/sectools.py secimage -i $OUT_PATH/emmc_appsboot.mbn -c $amssPath/$CHIPID_DIR/common/sectools/config/$CHIP/${CHIP}_secimage.xml -o $SIGN_FILES -sa
if [ x$PRODUCT == x"A306" ];then
python $amssPath/$CHIPID_DIR/common/sectools/sectools.py secimage -i $amssPath/MPSS.JO.3.0_A306/modem_proc/build/ms/bin/8937.genns.prod/mcfg_sw.mbn -c $amssPath/$CHIPID_DIR/common/sectools/config/$CHIP/${CHIP}_secimage.xml -o $SIGN_FILES -sa
python $amssPath/$CHIPID_DIR/common/sectools/sectools.py secimage -i $amssPath/MPSS.JO.3.0_A306/modem_proc/build/ms/bin/8937.genns.prod/mcfg_hw.mbn -c $amssPath/$CHIPID_DIR/common/sectools/config/$CHIP/${CHIP}_secimage.xml -o $SIGN_FILES -sa
else
python $amssPath/$CHIPID_DIR/common/sectools/sectools.py secimage -i $amssPath/MPSS.JO.3.0/modem_proc/build/ms/bin/8937.genns.prod/mcfg_sw.mbn -c $amssPath/$CHIPID_DIR/common/sectools/config/$CHIP/${CHIP}_secimage.xml -o $SIGN_FILES -sa
python $amssPath/$CHIPID_DIR/common/sectools/sectools.py secimage -i $amssPath/MPSS.JO.3.0/modem_proc/build/ms/bin/8937.genns.prod/mcfg_hw.mbn -c $amssPath/$CHIPID_DIR/common/sectools/config/$CHIP/${CHIP}_secimage.xml -o $SIGN_FILES -sa
fi

cp $WsRootDir/vendor/wind/efuse_sec/$CHIP/sec.dat $amssPath/$CHIPID_DIR/common/sectools/resources/build/fileversion2/

if [ x"$BUILD_MODE" == x"overall" ];then
if [ x$CHIP == x"8917" ];then
python $amssPath/MSM8937.LA.3.0.1/common/sectools/sectools.py secimage -i $amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/widevine.mbn -c $amssPath/MSM8937.LA.3.0.1/common/sectools/config/8937/8937_secimage.xml -o $amssPath/sign_files/tz -sa
python $amssPath/MSM8937.LA.3.0.1/common/sectools/sectools.py secimage -i $amssPath/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/cppf.mbn -c $amssPath/MSM8937.LA.3.0.1/common/sectools/config/8937/8937_secimage.xml -o $amssPath/sign_files/tz -sa
elif [ x$CHIP == x"8937" ];then
cp -a $amssPath/sign_files/tz/8937/* $SIGN_FILES/8937/
fi
fi

cd $SIGN_FILES
if [ -d "${CHIP}_sign" ];then
	rm -rf ${CHIP}_sign
fi
mkdir ${CHIP}_sign
find $SIGN_FILES/$CHIP/ -type f -name "*.mbn" -exec cp -b {} $SIGN_FILES/${CHIP}_sign/ ";"
cd $SIGN_FILES/${CHIP}_sign
for sign_file in $ALL_EFUSE_SIGN_FILES; do
for file in ${efuse_sign_files[*]}
do
	result=$(echo $file | grep "$sign_file")
	if [ x"$result" != x"" ];then
		if [ x$sign_file == x"qdsp6sw.mbn" ];then
			cp modem.mbn $file
		else
			if [ -f "$sign_file" ];then
				cp $sign_file $file
			else
				echo -e "Copy sign file error: can't found $file"
				#exit 1
			fi
		fi
	fi
done
done
copy_tz_files
cd $WsRootDir
}

#还原非签名文件
function restore_base(){
cd $BASE_FILES
for base_file in $ALL_EFUSE_SIGN_FILES; do
for file in ${efuse_sign_files[*]}
do
	result=$(echo $file | grep "$base_file")
	if [ x"$result" != x"" ];then
		if [ -f "$base_file" ];then
			cp $base_file $file
		else
			echo -e "Copy base file error: can't found $file"
			#exit 1
		fi
	fi
done
done
cp $BASE_FILES/sec.dat $amssPath/$CHIPID_DIR/common/sectools/resources/build/fileversion2/
cd $WsRootDir
}

#build common
function build_common(){
	if [ x$CHIP == x"8917" ];then
		echo "========== MSM8917.LA.3.0.1 =========="
	else
		echo "========== MSM8937.LA.3.0.1 =========="
	fi
	echo "make download files"
	if [ x$CLEAN != x"c" ];then
		if [ x$CHIP == x"8917" ];then
			cd $amssPath/MSM8917.LA.3.0.1/common/build
			python build.py $PRODUCT 2>&1|tee $LOG_PATH/common_8917.log

			if [ "`grep "UPDATE COMMON INFO COMPLETE" $LOG_PATH/common_$CHIP.log`" ];then
				echo -e "\033[40;32m Build MSM8917.LA.3.0.1 Successfully \033[0m"
				sleep 2
			else
				echo -e "\033[40;31m Build MSM8917.LA.3.0.1 failed (>.<) \033[0m"
				exit 1
			fi
		else
			cd $amssPath/MSM8937.LA.3.0.1/common/build
			python build.py $PRODUCT 2>&1|tee $LOG_PATH/common_8937.log

			if [ "`grep "UPDATE COMMON INFO COMPLETE" $LOG_PATH/common_$CHIP.log`" ];then
				echo -e "\033[40;32m Build MSM8937.LA.3.0.1 Successfully \033[0m"
				sleep 2
			else
				echo -e "\033[40;31m Build MSM8937.LA.3.0.1 failed (>.<) \033[0m"
				exit 1
			fi
		fi
	fi
}

#release download files
function release(){
	cd $WsRootDir
	echo "start copy files CONFIG_NAME=$CONFIG_NAME RELEASE_PARAM=$RELEASE_PARAM VARIANT=$VARIANT"

	if [ x$RELEASE_PARAM == x"overall" ];then
            ./release_version.sh E300L_IN $RELEASE_PARAM $VARIANT
	else
            ./release_version.sh $CONFIG_NAME $RELEASE_PARAM $VARIANT
	fi
}

function main(){
    ##################################################################
    #Check parameters
    ##################################################################
    command_array=($1 $2 $3 $4 $5)
    if [ ! -d $LOG_PATH ];then
        mkdir $LOG_PATH
    fi
    #add by lishunbo@wind-mobi.com 2017.04.26 start
    echo "`date +"%F %T"`	./quick_build.sh $1 $2 $3 $4 $5" >> $LOG_PATH/record.log
    #add by lishunbo@wind-mobi.com 2017.04.26 end
    for command in ${command_array[*]}; do

        ### set PRODUCT
        case $command in
        msm8937_64)
            if [ x$PRODUCT != x"" ];then continue; fi
            PRODUCT=msm8937_64
            ARM=arm64
            CONFIG_NAME=$command
            DEPEND=msm8937_64
            CHIP=8937
            continue
            ;;
        E300L_CN)
            if [ x$PRODUCT != x"" ];then continue; fi
            PRODUCT=$command
            ARM=arm64
            CONFIG_NAME=$command
            DEPEND=msm8937_64
            CHIP=8937
            PROP=E300L
            continue
            ;;
        E300L_WW)
            if [ x$PRODUCT != x"" ];then continue; fi
            PRODUCT=$command
            ARM=arm64
            CONFIG_NAME=$command
            DEPEND=msm8937_64
            CHIP=8917
            PROP=E300L
            continue
            ;;
        E300L_IN | E300L_PH)
            if [ x$PRODUCT != x"" ];then continue; fi
            PRODUCT=E300L_WW
            ARM=arm64
            CONFIG_NAME=$command
            DEPEND=msm8937_64
            CHIP=8937
            PROP=E300L
            continue
            ;;
        A306)
            if [ x$PRODUCT != x"" ];then continue; fi
            PRODUCT=$command
            ARM=arm64
            CONFIG_NAME=$command
            DEPEND=msm8937_64
            CHIP=8917
            PROP=A306
            continue
            ;;
        A307)
            if [ x$PRODUCT != x"" ];then continue; fi
            PRODUCT=A306
            ARM=arm64
            CONFIG_NAME=$command
            DEPEND=msm8937_64
            CHIP=8937
            PROP=A306
            continue
            ;;
        esac

     
        case $command in
            opt_none)
            WIND_DEXPREOPT_OPTION="DEXPREOPT_NONE"
            continue
            ;;
            opt_boot_only)
            WIND_DEXPREOPT_OPTION="DEXPREOPT_BOOT_ONLY"
            continue
            ;;
            opt_no_boot)
            WIND_DEXPREOPT_OPTION="DEXPREOPT_EXCEPT_BOOT"
            continue
            ;;
        esac
        case $command in
            factory)
            WIND_FACTORY_BUILD="yes"
            continue
            ;;
            no_gms)
            WIND_NO_GMS="yes"
            continue
            ;;
        esac
        ### set VARIANT
        if [ x$command == x"user" ] ;then
            if [ x$VARIANT != x"" ];then continue; fi
            VARIANT=user
        elif [ x$command == x"debug" ] || [ x$command == x"userdebug" ] ;then
            if [ x$VARIANT != x"" ];then continue; fi
            VARIANT=userdebug
        elif [ x$command == x"eng" ] ;then
            if [ x$VARIANT != x"" ];then continue; fi
            VARIANT=eng
        elif [ x$command == x"overall" ] || [ x$command == x"all" ] || [ x$command == x"amss" ] || [ x$command == x"pl" ] || [ x$command == x"mpss" ] || [ x$command == x"rpm_proc" ] || [ x$command == x"tz" ] || [ x$command == x"adsp" ] || [ x$command == x"common" ] ;then
            BUILD_MODE=$command
            if [ x$command == x"overall" ];then
        	RELEASE_PARAM=overall
            elif [ x$command == x"all" ];then
        	RELEASE_PARAM=all
            else
        	RELEASE_PARAM=amss
            fi
        elif [ x$command == x"userroot" ] ;then
            if [ x$VARIANT != x"" ];then continue; fi
            VARIANT=userroot
        ### set ACTION
        elif [ x$command == x"r" ] || [ x$command == x"remake" ];then
            if [ x$ACTION != x"" ];then continue; fi
            ACTION=remake
        elif [ x$command == x"n" ] || [ x$command == x"new" ];then
            if [ x$ACTION != x"" ];then continue; fi
            ACTION=new
        elif [ x$command == x"c" ] || [ x$command == x"clean" ];then
            if [ x$ACTION != x"" ];then continue; fi
            ACTION=clean
            CLEAN=c
            RELEASE_PARAM=none
        elif [ x$command == x"mmma" ];then
            if [ x$ACTION != x"" ];then continue; fi
            ACTION=mmma
            RELEASE_PARAM=none
        elif [ x$command == x"mmm" ];then
            if [ x$ACTION != x"" ];then continue; fi
            ACTION=mmm
            RELEASE_PARAM=none
        elif [ x$command == x"boot" ];then
            if [ x$ACTION != x"" ];then continue; fi
            ACTION=bootimage
            RELEASE_PARAM=boot
        elif [ x$command == x"system" ];then
            if [ x$ACTION != x"" ];then continue; fi
            ACTION=systemimage
            RELEASE_PARAM=system
        elif [ x$command == x"userdata" ];then
            if [ x$ACTION != x"" ];then continue; fi
            ACTION=userdataimage
            RELEASE_PARAM=userdata
        elif [ x$command == x"boot-nodeps" ];then
            if [ x$ACTION != x"" ];then continue; fi
            ACTION=bootimage-nodeps
            RELEASE_PARAM=boot
        elif [ x$command == x"snod" ];then
            if [ x$ACTION != x"" ];then continue; fi
            ACTION=snod
            RELEASE_PARAM=system
        elif [ x$command == x"userdata-nodeps" ];then
            if [ x$ACTION != x"" ];then continue; fi
            ACTION=userdataimage-nodeps
            RELEASE_PARAM=userdata
        elif [ x$command == x"ramdisk-nodeps" ];then
            if [ x$ACTION != x"" ];then continue; fi
            ACTION=ramdisk-nodeps
            RELEASE_PARAM=none
        elif [ x$command == x"recovery" ];then
            if [ x$ACTION != x"" ];then continue; fi
            ACTION=recoveryimage
            RELEASE_PARAM=recovery
        elif [ x$command == x"cacheimage-nodeps" ];then
            if [ x$ACTION != x"" ];then continue; fi
            ACTION=cacheimage-nodeps
            RELEASE_PARAM=cache
        elif [ x$command == x"vnod" ];then
            if [ x$ACTION != x"" ];then continue; fi
            ACTION=vnod
            RELEASE_PARAM=vendor
        elif [ x$command == x"apd" ];then
            if [ x$ACTION != x"" ];then continue; fi
            ACTION=apdimage
            RELEASE_PARAM=APD
        elif [ x$command == x"xrom" ];then
             if [ x$ACTION != x"" ];then continue; fi
             ACTION=xromimage
             RELEASE_PARAM=xrom
        elif [ x$command == x"vendor" ];then
            if [ x$ACTION != x"" ];then continue; fi
            ACTION=vendorimage
            RELEASE_PARAM=vendor
        elif [ x$command == x"otapackage" ] || [ x$command == x"ota" ] ;then
            if [ x$ACTION != x"" ];then continue; fi
            ACTION=otapackage
            if [ x$RELEASE_PARAM != x"overall" ];then
            RELEASE_PARAM=ota
            fi
        elif [ x$command == x"asusfw_otapackage" ];then
            if [ x$ACTION != x"" ];then continue; fi
            ACTION=asusfw_otapackage
            RELEASE_PARAM=asusfw_ota
        ### set MODULE
        elif [ x$command == x"k" ] || [ x$command == x"kernel" ];then
            if [ x$MODULE != x"" ];then continue; fi
            MODULE=k
            RELEASE_PARAM=bootimage
        elif [ x$command == x"aboot" ];then
            if [ x$MODULE != x"" ];then continue; fi
            ACTION=aboot
            RELEASE_PARAM=aboot
        elif [ x$command == x"colock" ];then
            CO_COLOCK_FLAG=yes
        elif [ x$command == x"unsign" ];then
            EFUSE_UNSIGN=yes
        else
            if [ x$MODULE != x"" ];then continue; fi
            if [ x$command != x"overall" ] || [ x$command != x"all" ] && [ x$command != x"android" ] && [ x$command != x"amss" ] && [ x$command != x"pl" ] && [ x$command != x"mpss" ] && [ x$command != x"rpm_proc" ] && [ x$command != x"tz" ] && [ x$command != x"adsp" ] && [ x$command != x"common" ];then
            MODULE=$command
            fi
        fi
    done
    OUT_PATH=$WsRootDir/out/target/product/$PRODUCT

    ota_amss_images=(
        $OUT_PATH/amss_images/sbl1.mbn
        $OUT_PATH/amss_images/tz.mbn
        $OUT_PATH/amss_images/devcfg.mbn
        $OUT_PATH/amss_images/keymaster64.mbn
        $OUT_PATH/amss_images/cmnlib_30.mbn
        $OUT_PATH/amss_images/cmnlib64_30.mbn
        $OUT_PATH/amss_images/rpm.mbn
        $OUT_PATH/amss_images/NON-HLOS.bin
        $OUT_PATH/amss_images/adspso.bin
        $OUT_PATH/mdtp.img
    )

    ota_overall_amss_images=(
        $OUT_PATH/overall_all_images/8917_sbl1.mbn
        $OUT_PATH/overall_all_images/8917_tz.mbn
        $OUT_PATH/overall_all_images/8917_devcfg.mbn
        $OUT_PATH/overall_all_images/8917_keymaster64.mbn
        $OUT_PATH/overall_all_images/8917_cmnlib_30.mbn
        $OUT_PATH/overall_all_images/8917_cmnlib64_30.mbn
        $OUT_PATH/overall_all_images/8917_rpm.mbn
        $OUT_PATH/overall_all_images/8917_NON-HLOS.bin
        $OUT_PATH/overall_all_images/8917_adspso.bin
        $OUT_PATH/overall_all_images/8937_sbl1.mbn
        $OUT_PATH/overall_all_images/8937_tz.mbn
        $OUT_PATH/overall_all_images/8937_devcfg.mbn
        $OUT_PATH/overall_all_images/8937_keymaster64.mbn
        $OUT_PATH/overall_all_images/8937_cmnlib_30.mbn
        $OUT_PATH/overall_all_images/8937_cmnlib64_30.mbn
        $OUT_PATH/overall_all_images/8937_rpm.mbn
        $OUT_PATH/overall_all_images/8937_NON-HLOS.bin
        $OUT_PATH/overall_all_images/8937_adspso.bin
        $OUT_PATH/mdtp.img
    )
    OTA_UPDATE_BACKUP_MBN="sbl1.mbn tz.mbn devcfg.mbn keymaster64.mbn cmnlib_30.mbn cmnlib64_30.mbn rpm.mbn"
    OVERALL_OTA_UPDATE_BACKUP_MBN="8917_sbl1.mbn 8917_tz.mbn 8917_devcfg.mbn 8917_keymaster64.mbn 8917_cmnlib_30.mbn 8917_cmnlib64_30.mbn 8917_rpm.mbn 8937_sbl1.mbn 8937_tz.mbn 8937_devcfg.mbn 8937_keymaster64.mbn 8937_cmnlib_30.mbn 8937_cmnlib64_30.mbn 8937_rpm.mbn"

    echo "********This build project PRODUCT is $PRODUCT,CHIP is $CHIP,RELEASE_PARAM is $RELEASE_PARAM********"
    #echo "PRODUCT=$PRODUCT VARIANT=$VARIANT ACTION=$ACTION"
    echo "Log Path $LOG_PATH"
	
    if [ x$COPYFILES == x"" ];then
        if [ x$ACTION == x"new" ] && [ x$MODULE == x"" ];then
            COPYFILES=yes;
        else
            COPYFILES=no;
        fi
    fi
    CUSTOM_FILES_PATH="./vendor/wind/custom_files/"
    if [ x$COPYFILES == x"yes" ];then
        copy_custom_files $PRODUCT;
    fi

    cd $WsRootDir/vendor/qcom/proprietary/
    if [ -d "E300L" ] || [ -d "A306" ];then
		git checkout . && git clean -df
		cp -a $WsRootDir/$CUSTOM_FILES_PATH/vendor/qcom/proprietary/$PROP/* .
		rm -rf E300L A306
    fi
    cd -

	if [ x$CONFIG_NAME == x"E300L_WW" ];then
		cp $amssPath/MSM8917.LA.3.0.1/E300L_WW/contents.xml $amssPath/MSM8917.LA.3.0.1/
	elif [ x$CONFIG_NAME == x"A306" ];then
		cp $amssPath/MSM8917.LA.3.0.1/A306/contents.xml $amssPath/MSM8917.LA.3.0.1/
	elif [ x$CONFIG_NAME == x"A307" ];then
	    cp $amssPath/MSM8937.LA.3.0.1/A307/contents.xml $amssPath/MSM8937.LA.3.0.1/
	fi

	if [ x$CONFIG_NAME == x"E300L_IN" ] || [ x$CONFIG_NAME == x"E300L_PH" ] || [ x"$RELEASE_PARAM" == x"overall" ];then
		cp $amssPath/MSM8937.LA.3.0.1/E300L_IN/contents.xml $amssPath/MSM8937.LA.3.0.1/
	elif [ x$CONFIG_NAME == x"E300L_CN" ];then
		cp $amssPath/MSM8937.LA.3.0.1/E300L_CN/contents.xml $amssPath/MSM8937.LA.3.0.1/
	fi

	confi_prop
	if [ -d $BASE_FILES ] && [ x$ACTION != x"otapackage" ] && [ x$ACTION != x"asusfw_otapackage" ];then
		restore_base
	fi

	if [ x$ACTION == x"asusfw_otapackage" ];then
	full_package_zip=$(find $OUT_PATH/ -name ${PRODUCT}-target_files-*.zip)
	if [ -f "$full_package_zip" ] ;then
		OTA_BUILD=yes
	fi
	fi

    if [ x$ACTION != x"otapackage" ] && [ x$ACTION != x"asusfw_otapackage" ];then
	for command in ${command_array[*]}
	do
		if [ x$command == x"overall" ];then
			echo "build all moudles"
			CLEAN=c
			build_pl
			build_rpm
			CLEAN=
			build_pl
			build_mpss
			build_rpm
			build_tz
			build_adsp
			if [ x$EFUSE_UNSIGN != x"yes" ];then
			build_sign
			fi
			echo "build android"
			build_android 
			echo -e "\033[40;32m Android build finished \033[0m"
			build_common
			if [ x$CHIP == x"8917" ];then
			cd $WsRootDir
			./release_version.sh $PRODUCT amssbackup
			if [ -d $BASE_FILES ];then
			restore_base
			fi
			CLEAN=c
			build_pl
			build_rpm
			CLEAN=
			CHIP=8937
			CONFIG_NAME=E300L_IN
			export WIND_CHIP=$CHIP
			confi_prop
			build_pl
			build_mpss
			build_rpm
			fi
		elif [ x$command == x"all" ];then
			echo "build all moudles"
			build_pl
			build_mpss
			build_rpm
			build_tz
			build_adsp
			echo -e "\033[40;32m All moudles build finished \033[0m"
			if [ x$EFUSE_UNSIGN != x"yes" ];then
			build_sign
			fi
			echo "build android"
			build_android
			echo -e "\033[40;32m Android build finished \033[0m"
		elif [ x$command == x"amss" ];then
			echo "build all in amss"
			build_pl
			build_mpss
			build_rpm
			build_tz
			build_adsp
			echo -e "\033[40;31m 32m moudles in amss build finished \033[0m"
		fi
	done
	fi

	for command in ${command_array[*]}
	do
		case $command in
			pl)
			build_pl
			;;
			mpss)
			build_mpss
			;;
			rpm_proc)
			build_rpm
			;;
			tz)
			build_tz
			;;
			adsp)
			build_adsp
			;;
			common)
			if [ x$EFUSE_UNSIGN != x"yes" ];then
			build_sign
			fi
			build_common
			;;
		esac			
	done

	cd $CUSTOMPATH/$PRODUCT/radio/
	if [ x$ACTION == x"otapackage" ] || [ x$ACTION == x"asusfw_otapackage" ];then
		if [ x$ACTION == x"asusfw_otapackage" ] && [ x$OTA_BUILD == x"yes" ];then
		echo "ota img builded!!"
		else
		if [ x$BUILD_MODE == x"overall" ];then
			rm -rf $CUSTOMPATH/$PRODUCT/radio/*.*
			for file in ${ota_overall_amss_images[*]}
			do
				if [ -f "$file" ];then
					cp $file $CUSTOMPATH/$PRODUCT/radio/
				else
					echo -e "\033[40;31m Copy otapackage amss files error: can't found $file \033[0m"
					exit 1
				fi
			done
			for file in $OVERALL_OTA_UPDATE_BACKUP_MBN;
			do
				cp $file ${file}.bak
			done
			mv 8917_cmnlib_30.mbn 8917_cmnlib.mbn
			mv 8917_cmnlib_30.mbn.bak 8917_cmnlib.mbn.bak
			mv 8917_cmnlib64_30.mbn 8917_cmnlib64.mbn
			mv 8917_cmnlib64_30.mbn.bak 8917_cmnlib64.mbn.bak
			mv 8917_keymaster64.mbn 8917_keymaster.mbn
			mv 8917_keymaster64.mbn.bak 8917_keymaster.mbn.bak
			mv 8937_cmnlib_30.mbn 8937_cmnlib.mbn
			mv 8937_cmnlib_30.mbn.bak 8937_cmnlib.mbn.bak
			mv 8937_cmnlib64_30.mbn 8937_cmnlib64.mbn
			mv 8937_cmnlib64_30.mbn.bak 8937_cmnlib64.mbn.bak
			mv 8937_keymaster64.mbn 8937_keymaster.mbn
			mv 8937_keymaster64.mbn.bak 8937_keymaster.mbn.bak
		else
			rm -rf $CUSTOMPATH/$PRODUCT/radio/*.*
			for file in ${ota_amss_images[*]}
			do
				if [ -f "$file" ];then
					cp $file $CUSTOMPATH/$PRODUCT/radio/
				else
					echo -e "\033[40;31m Copy otapackage amss files error: can't found $file \033[0m"
					exit 1
				fi
			done
			for file in $OTA_UPDATE_BACKUP_MBN;
			do
				cp $file ${file}.bak
			done
			mv cmnlib_30.mbn cmnlib.mbn
			mv cmnlib_30.mbn.bak cmnlib.mbn.bak
			mv cmnlib64_30.mbn cmnlib64.mbn
			mv cmnlib64_30.mbn.bak cmnlib64.mbn.bak
			mv keymaster64.mbn keymaster.mbn
			mv keymaster64.mbn.bak keymaster.mbn.bak
		fi
		fi
		cd $WsRootDir
		build_android
		#build_common
		release
	else
		if [ x$EFUSE_UNSIGN != x"yes" ] && [ x"$BUILD_MODE" != x"all" ] && [ x"$BUILD_MODE" != x"common" ];then
			build_sign
		fi
		if [ x"$BUILD_MODE" != x"" ] && [ x$CLEAN != x"c" ];then
			echo "BUILD_MODE release img"
			if [ -d "$WsRootDir/out/target/product/$PRODUCT" ];then
			if [ x"$RELEASE_PARAM" == x"overall" ] || [ x"$RELEASE_PARAM" == x"all" ] || [ x"$RELEASE_PARAM" == x"amss" ];then
			if [ x"$BUILD_MODE" != x"common" ];then
			build_common
			fi
			fi
			fi
			release
		elif [ x"$BUILD_MODE" == x"" ] && [ x"$ACTION" != x"" ];then
			echo "build_android"
			build_android
			if [ x$CLEAN != x"c" ] && [ x"$MODULE" == x"" ];then
			echo "build android release img"
			if [ -d "$WsRootDir/out/target/product/$PRODUCT" ];then
			if [ x"$RELEASE_PARAM" == x"overall" ] || [ x"$RELEASE_PARAM" == x"all" ] || [ x"$RELEASE_PARAM" == x"amss" ];then
			build_common
			fi
			fi
			release
			fi
		fi
	fi

	cd $WsRootDir/prebuilts/sdk/tools
	./jack-admin kill-server
	cd - > /dev/null
	
}

main $1 $2 $3 $4 $5 2>&1|tee $LOG_PATH/build.log

