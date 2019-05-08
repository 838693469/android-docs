#!/bin/bash

# default values as below:
export ANDROID_SET_JAVA_HOME=true
export HQ_BUILD_ARM_LICENSE=true
export BUILD_SIGN_FOR_SECBOOT=true
export HQ_PRODUCT_ID=

HQ_EFUSE_ENABLE=false
HQ_USE_CUST_KEY=false

BUILD_VARIANT=userdebug
BUILD_OBJECT=all
BUILD_MODE=remake
BUILD_TGT_FILES_PKG=false
CCACHE=true

ROOT_DIR=`pwd`
LOG_DIR=$ROOT_DIR/log
SYMBOLS=symbols
NON_HLOS_PLATFORM=non-hlos
VER_DIR_NAME=all_images
SPARSE_VER_DIR_NAME=all_sparse_images
#CPUS=`grep processor /proc/cpuinfo | wc -l`
CPUS=16
QCOM_PARAM_CFG=qcom_param.cfg

DEBUG=false
if [ "$DEBUG" = "true" ]; then
    MAKE_PRINT='-n'
else
    MAKE_PRINT=
fi


function usage(){
cat << EOF
Usage: ./mk.sh PROJECT [-m MODE] [-o OBJECT] [-v VARIANT] [-hs]
  PROJECT is a must, which should be a project name or a sub-project name.
  Example:
      short: ./mk sdm660_64 -m remake -o all -v userdebug
      long: ./mk sdm660_64 --mode=new --object=hlos --variant=user

      With default values, ./mk sdm660_64
      equals to ./mk sdm660_64 -m remake -o all -v userdebug

      when --mode=[mm mmm mma mmma]
      ./mk sdm660_64 --mode=mm --object=packages/apps/Calculator

Optional arguments:
  -h, --help            show this help message and exit
  -s, --sign            sign images for secure-boot
  -e, --efuse           enable efuse in version with specified sec.dat
  -c, --cust-key        use custom key to sign boot.img & system.img
  -l, --license         when OBJECT is [all non-hlos], it will make sure to compile
                        qualcomm BOOT and RPM.
  -t, --tgt_files       after compiling hlos, it will make target-files-package.
                        only valid when --object=hlos
  -o, --object=OBJECT
                        object option, default is "all". 
                        The following objects are supported until now:
                        all            includes all objects
                        hlos           aosp and qcom proprietary
                        non-hlos       includes ADSP,MPSS,TZ, 
                                       if sign flag is set, also includes BOOT and RPM
                        update-api     make update-api
                        tgt-files      make target-files-package
                        aboot          make lk
                        bootimage      boot.img,includes kernel,ramdisk.img and dt.img
                        systemimage    system.img
                        userdataimage  userdata.img
                        recoveryimage  recovery.img
                        vendorimage    vendor.img
                        qcom-boot      qualcomm BOOT component
                        qcom-rpm       qualcomm RPM component
                        qcom-modem     qualcomm MPSS component
                        qcom-adsp      qualcomm ADSP component
                        qcom-tz        qualcomm TZ component
                        <path>         directory path of modules, compatible with absolute path and relative path
                                       valid only when --mode=[mm mmm mma mmma]
  -v, --variant=VIRIANT
                        which defines TARGET_BUILD_VARIANT
                        should be "user" or "userdebug", default is "userdebug"
  -m, --mode=MODE
                        build mode, default is "remake"
                        new            clean and make
                        remake         make
                        clean          clean the generated object files, like *.o,
                                       valid only when --object=[all,hlos,non-hlos,qcom-{component}]
                        nodeps         builds hlos images ignoring dependencies
                                       valid only when --object=[bootimage systemimage userdataimage recoveryimage]
                        mm             builds all of the modules in the directory <path>, but not their dependencies
                        mmm            builds all of the modules in the supplied directory <path>, but not their dependencies
                        mma            builds all of the modules in the directory <path>, and their dependencies
                        mmma           builds all of the modules in the supplied directory <path>, and their dependencies
                        preconfig      generates Android.mk for apk specified by --object=<file path of apk>
                                       generates Android.mk for each apk in the supplied directory <apks' path>
                                       generates Android.mk for all apks when --object=all
                        prebuilt       prebuilts apk specified by --object=<file path of apk>
                                       prebuilts all apks in the supplied directory <apks' path>
                                       prebuilts all apks when --object=all
EOF
}

function check_gcc_version(){
    local required_version='4.8'
    local gcc_version_str=`gcc --version 2>&1 | grep '^gcc .*[ "]4\.[0-9][\. "$$]'`
    local gcc_version=$(expr "$gcc_version_str" : '.*\(4\.[0-9]\)\.[0-9].*')
    echo -e "Your gcc version is: $gcc_version_str"
    if [ "$gcc_version" != "$required_version" ]
    then
        echo "You are attempting to build with the incorrect version of gcc."
        echo "The required version is: $required_version."
        echo "Please update gcc version with vendor/qcom/non-hlos/hq_build/install_gcc4-8-1.sh"
        exit 1
    fi
}

function show_java_version(){
    echo "==============SHOW JAVA VERSION============="
    java -version
    javac -version
    echo "==============SHOW JAVA VERSION============="
}

function check_build_variant()
{
    if [[ "$BUILD_VARIANT" != "user" && "$BUILD_VARIANT" != "userdebug" ]]
    then
        echo "***** Unsupported BUILD_VARIANT=$BUILD_VARIANT *****"
        exit 1
    fi
}

function check_build_mode()
{
    local supported_mode=(new remake clean mm mmm mma mmma nodeps preconfig prebuilt)
    for obj in "${supported_mode[@]}"
    do
        if [ "$obj" = "$BUILD_MODE" ]; then
            return 0
        fi
    done

    echo "***** Unsupported BUILD_MODE=${BUILD_MODE} *****"
    exit 1
}

function check_security()
{
    if [[ $HQ_EFUSE_ENABLE = "true" && $BUILD_SIGN_FOR_SECBOOT = "false" ]]
    then
        echo "Error: HQ_EFUSE_ENABLE=$HQ_EFUSE_ENABLE BUILD_SIGN_FOR_SECBOOT=$BUILD_SIGN_FOR_SECBOOT"
        exit 1
    fi
}

function select_platform_match_project()
{
    local apq_prj=(q6006_prc q6006_row q6006_v_row q6008_row)
    for prj in "${apq_prj[@]}"
    do
	if [ "$prj" = "$HQ_PROJECT_ID" ]; then
	    export HQ_PRODUCT_Q6006=true
	    return
	fi
    done
    export HQ_PRODUCT_Q6006=false
}

# check project path
# before checking, HQ_PRODUCT_ID is like a6000;
#
# in case of enable_project_id=true,
# HQ_PRODUCT_ID will be changed from a6000 to TARGET_DEVICE, like hq_msm8917_64,
# and a6000 is assigned to HQ_PROJECT_ID as exported;
#
# in case of enable_project_id=false,
# just check if HQ_PRODUCT_ID does exist in device/*/*
function check_project_path()
{
    local enable_project_id=$1

    echo "check_project_path: HQ_PRODUCT_ID=$HQ_PRODUCT_ID enable_project_id=$enable_project_id"
    cd $ROOT_DIR
    if [ x$enable_project_id = x"true" ]; then
        if [ x$PROJECT_PATH = x"" ]; then
            echo "Error: PROJECT_PATH=$PROJECT_PATH"
            exit 1
        fi

        if [ ! -d $ROOT_DIR/$PROJECT_PATH ]; then
            echo "Error: $ROOT_DIR/$PROJECT_PATH doesnot exist"
            exit 1
        fi
        
        prj_paths=`find ./$PROJECT_PATH -maxdepth 3 -name $HQ_PRODUCT_ID`
        echo "prj_paths=$prj_paths"
        for path in $prj_paths
        do
            echo "path is $path"
            HQ_PRODUCT_ID=`echo "$path" | cut -d "/" -f 3`
            export HQ_VENDOR=`echo "$path" | cut -d "/" -f 4`
            export HQ_PROJECT_ID=`echo "$path" | cut -d "/" -f 5`
            echo "HQ_VENDOR=$HQ_VENDOR HQ_PROJECT_ID=$HQ_PROJECT_ID"
        done

        PROJECT_DIR=${ROOT_DIR}/huaqin/${HQ_PRODUCT_ID}/${HQ_VENDOR}/${HQ_PROJECT_ID}
        echo "PROJECT_DIR=$PROJECT_DIR"
        PROJECT_COPY_OUT_DIR=${ROOT_DIR}/huaqin/${HQ_PRODUCT_ID}/${HQ_VENDOR}/${HQ_PROJECT_ID}/copy_files/out_files
        echo "PROJECT_COPY_OUT_DIR=$PROJECT_COPY_OUT_DIR"
          
        if [ x$HQ_PRODUCT_ID = x"" ]; then
            echo "Error: No matched project name!"
            exit 1
        fi
    else
        prj_path=`find ./device/*/ -maxdepth 3 -name $HQ_PRODUCT_ID`
        echo "$prj_path"
        if [ x"$prj_path" = x"" ]; then
            echo "Error: ***** No matched project name! *****"
            exit 1
        fi
    fi
    echo "check_project_path:in the end, HQ_PRODUCT_ID=$HQ_PRODUCT_ID"
}

# init version dirs.
# $ROOT_DIR & $OUT_TARGET_DIR are assumed to be defined
function init_version_dirs()
{
    flash_scr_dir=`awk -F '=' '/^flash_scripts_dir/{print $2}' $QCOM_CFG_FILE`
    version_dir=`awk -F '=' '/^version_dir/{print $2}' $QCOM_CFG_FILE`
    image_dir=`awk -F '=' '/^image_dir_in_version/{print $2}' $QCOM_CFG_FILE`

    if [ x$flash_scr_dir != x"" ]; then
        FLASH_SCRIPTS_DIR=$ROOT_DIR/$flash_scr_dir
    fi

    if [ x$version_dir != x"" ]; then
        VER_DIR_NAME=$version_dir
        SPARSE_VER_DIR_NAME=${version_dir}_sparse
    fi

    if [ x$image_dir != x"" ]; then
        IMGS_DIR_NAME=$image_dir
    fi

    VERSION_DIR=$OUT_TARGET_DIR/$VER_DIR_NAME
    SPARSE_VERSION_DIR=$OUT_TARGET_DIR/$SPARSE_VER_DIR_NAME

    if [ x$IMGS_DIR_NAME != x"" ]; then
        VER_IMAGES_DIR=$VERSION_DIR/$IMGS_DIR_NAME
    else
        VER_IMAGES_DIR=$VERSION_DIR
    fi

    VERSION_FILE=$OUT_TARGET_DIR/$VER_DIR_NAME.zip
    SPARSE_VERSION_FILE=$OUT_TARGET_DIR/$SPARSE_VER_DIR_NAME.zip

    echo "VERSION_DIR=$VERSION_DIR SPARSE_VERSION_DIR=$SPARSE_VERSION_DIR VER_IMAGES_DIR=$VER_IMAGES_DIR"
    echo "VERSION_FILE=$VERSION_FILE SPARSE_VERSION_FILE=$SPARSE_VERSION_FILE"
}

# init variables
function init_variables()
{
    QCOM_CFG_FILE=$ROOT_DIR/build/make/hq_tools/$HQ_PRODUCT_ID/$QCOM_PARAM_CFG
    #QCOM_CFG_FILE=$ROOT_DIR/build/make/hq_tools/$HQ_PROJECT_ID/$QCOM_PARAM_CFG
    echo "init_variables"
    echo "111 HQ_PRODUCT_ID: ${HQ_PRODUCT_ID}"
    if [ ! -e $QCOM_CFG_FILE ]; then
        echo "Error: $QCOM_CFG_FILE doesnot exist!"
        exit 1
    fi

    QCOM_PLATFORM=`awk -F '=' '/^platform/{print $2}' $QCOM_CFG_FILE`
    MSM_DEVICE_DIR=`awk -F '=' '/^qcom_dir/{print $2}' $QCOM_CFG_FILE`
    NON_HLOS_PLATFORM=`awk -F '=' '/^nonhlos_dir/{print $2}' $QCOM_CFG_FILE`
    HQ_RFCARD_MODE=`awk -F '=' '/^rfcard_mode/{print $2}' $QCOM_CFG_FILE`
    CUST_KEY_DIR=`awk -F '=' '/^cust_key_dir/{print $2}' $QCOM_CFG_FILE`

    echo "222 HQ_RFCARD_MODE: ${HQ_RFCARD_MODE}"
    if [[ x$QCOM_PLATFORM = x"" || x$MSM_DEVICE_DIR = x"" || x$NON_HLOS_PLATFORM = x"" || x$HQ_RFCARD_MODE = x"" ]]
    then
        echo "Error: QCOM_PLATFORM=$QCOM_PLATFORM MSM_DEVICE_DIR=$MSM_DEVICE_DIR \
              NON_HLOS_PLATFORM=$NON_HLOS_PLATFORM HQ_RFCARD_MODE=$HQ_RFCARD_MODE"
        exit 1
    fi

    prebuilt_imgs_dir=`awk -F '=' '/^prebuilt_images_dir/{print $2}' $QCOM_CFG_FILE`
    if [ x$prebuilt_imgs_dir != x"" ]; then
        PREBUILT_IMGS_DIR=$ROOT_DIR/$prebuilt_imgs_dir
    fi

    SRC_OVERLAY_ENABLE=`awk -F '=' '/^src_overlay_enable/{print $2}' $QCOM_CFG_FILE`
    SRC_OVERLAY_IN_CASE=`awk -F '=' '/^src_overlay_in_case/{print $2}' $QCOM_CFG_FILE`

    src_overlay_dir=`awk -F '=' '/^src_overlay_dir/{print $2}' $QCOM_CFG_FILE`
    if [ x$src_overlay_dir != x"" ]; then
        SRC_OVERLAY_DIR=$ROOT_DIR/$src_overlay_dir
    fi

    # the following cannot be put before the others,
    # because HQ_PRODUCT_ID may be changed, in case of enable_project_id=true
    enable_project_id=`awk -F '=' '/^enable_project_id/{print $2}' $QCOM_CFG_FILE`
    PROJECT_PATH=`awk -F '=' '/^project_path/{print $2}' $QCOM_CFG_FILE`

    check_project_path $enable_project_id

    OUT_TARGET_DIR=$ROOT_DIR/out/target/product/$HQ_PRODUCT_ID
    SYMBOLS_DIR=$OUT_TARGET_DIR/symbols

    init_version_dirs
}

function make_nonhlos_component()
{
    sleep 3
    local component=$1
    
    echo "make_nonhlos_component component: ${component}"
    echo "make_nonhlos_component HQ_RFCARD_MODE: ${HQ_RFCARD_MODE}"
    cd ${ROOT_DIR}/vendor/qcom/${NON_HLOS_PLATFORM}/hq_build
    if [ $component = "modem" ]; then
        ./build_$component.sh $QCOM_PLATFORM $BUILD_MODE $HQ_RFCARD_MODE
    else
        ./build_$component.sh $QCOM_PLATFORM $BUILD_MODE
    fi

    if [ $? -gt 0 ]; then
        echo "for more information, please check $LOG_FILE_PATH"
        exit 1
    fi
}

function make_nonhlos()
{
    cd ${ROOT_DIR}/vendor/qcom/${NON_HLOS_PLATFORM}/hq_build
    ./build_non_hlos.sh $QCOM_PLATFORM $BUILD_MODE $HQ_BUILD_ARM_LICENSE $HQ_RFCARD_MODE
    if [ $? -gt 0 ]; then
        echo "for more information, please check $LOG_FILE_PATH"
        exit 1
    fi
}

function copy_nonhlos_component()
{
    local component=$1
    local dest_dir=$2
    cd ${ROOT_DIR}/vendor/qcom/${NON_HLOS_PLATFORM}
    #if [ ! -e copy-all-img.sh ]; then
        cp -f hq_build/copy-all-img.sh copy-all-img.sh
        chmod 777 copy-all-img.sh
    #fi

    if [ ! -e $dest_dir ]; then
        mkdir -p $dest_dir
    fi
    echo "./copy-all-img.sh $QCOM_PLATFORM $component $dest_dir"
    ./copy-all-img.sh $QCOM_PLATFORM $component $dest_dir

}

function copy_prebuilt_images()
{
    local dest_dir=$1
    echo "PREBUILT_IMGS_DIR=$PREBUILT_IMGS_DIR"
    if [ x$PREBUILT_IMGS_DIR = x"" ]; then
        return 0
    fi

    if [ -e $PREBUILT_IMGS_DIR ]; then
        echo "cp -f $PREBUILT_IMGS_DIR/* $dest_dir"
        cp -f $PREBUILT_IMGS_DIR/* $dest_dir
    fi
}

# copy sec.dat to dest_dir
function copy_efuse_if_needed()
{
    local dest_dir=$1
    if [ x$HQ_EFUSE_ENABLE = x"true" ]; then
        echo "cp -f $PREBUILT_IMGS_DIR/efuse/* $dest_dir"
        cp -f $PREBUILT_IMGS_DIR/efuse/* $dest_dir
    fi
}

function copy_nonhlos_component_elf()
{
    local component=$1
    local dest_dir=$2
    cd $ROOT_DIR/vendor/qcom/$NON_HLOS_PLATFORM
    
    #if [ ! -e copy-all-elf.sh ]; then
        cp -f hq_build/copy-all-elf.sh copy-all-elf.sh
        chmod 777 copy-all-elf.sh
    #fi
 
    echo "copy_nonhlos_component_elf QCOM_PLATFORM:$QCOM_PLATFORM component:$component dest_dir:$dest_dir"
    ./copy-all-elf.sh $QCOM_PLATFORM $component $dest_dir
}

function copy_lk_symbol()
{
    local dest_dir=$1
    cp -f ${OUT_TARGET_DIR}/obj/EMMC_BOOTLOADER_OBJ/build-msm*/lk $dest_dir
}

function copy_vmlinux()
{
    local dest_dir=$1
    cp -f ${OUT_TARGET_DIR}/obj/KERNEL_OBJ/vmlinux $dest_dir
}

function copy_secimagelog()
{
    local dest_dir=$1
    cp -f ${OUT_TARGET_DIR}/secimage.log $dest_dir
    cp -f ${OUT_TARGET_DIR}/secimage_hq.log $dest_dir
}

function backup_symbols()
{
    copy_lk_symbol $SYMBOLS_DIR
    copy_vmlinux $SYMBOLS_DIR
    copy_nonhlos_component_elf all $SYMBOLS_DIR
    local symbols_zip=$OUT_TARGET_DIR/${SYMBOLS}.zip
    if [ -e $symbols_zip ]; then
        rm -f $symbols_zip
    fi

    cd $SYMBOLS_DIR
    echo "${SYMBOLS}: pack ..."
    zip -r ../${SYMBOLS}.zip ./* >>/dev/null
    echo "${SYMBOLS}.zip is done."
}

function overlay_partition_if_needed()
{
    local rel_path_file=`awk -F '=' '/^partition/{print $2}' $QCOM_CFG_FILE`
    if [[ x$rel_path_file != x"" ]]; then
        local src_partition=$ROOT_DIR/$rel_path_file
        echo "src_partition=$src_partition"
        if [ ! -e $src_partition ]; then
            echo "Error: $src_partition does not exist!"
            exit 1
        fi
        local des_partition=$ROOT_DIR/vendor/qcom/$NON_HLOS_PLATFORM/$MSM_DEVICE_DIR/build/partition.xml
        cp -f $src_partition $des_partition
        echo "cp -f $src_partition $des_partition"
    fi
}

function overlay_contents_if_needed()
{
    local rel_path_file=`awk -F '=' '/^contents/{print $2}' $QCOM_CFG_FILE`
    if [[ x$rel_path_file != x"" ]]; then
        local src_contents=$ROOT_DIR/$rel_path_file
        echo "src_contents=$src_contents"
        if [ ! -e $src_contents ]; then
            echo "Error: $src_contents does not exist!"
            exit 1
        fi
        local des_contents=$ROOT_DIR/vendor/qcom/$NON_HLOS_PLATFORM/$MSM_DEVICE_DIR/contents.xml
        cp -f $src_contents $des_contents
        echo "cp -f $src_contents $des_contents"
    fi
}

function filter_out_readme()
{
    if [[ $1 =~ ^\./[Rr][Ee][Aa][Dd][Mm][Ee].* ]]
    then
        return 1
    fi
    return 0
}

function cd_project_dir()
{
    if [ "${PROJECT_DIR}" != "" ]
    then
    	cd $PROJECT_DIR
    	echo "cd project dir: `pwd`"
    else
        echo "no project dir"
        return 1  
    fi
}

function copy_src_files()
{
    echo "copy src files ..."
    echo "src_dir: $SRC_OVERLAY_DIR des_dir: $ROOT_DIR"
    if [ ! -e $SRC_OVERLAY_DIR ]; then
        echo "Error: $SRC_OVERLAY_DIR doesnot exist!"
        exit 1
    fi

    cd $SRC_OVERLAY_DIR
    local file_path_list=`find . -name "*"`
    for file_path in $file_path_list
    do
        filter_out_readme $file_path
        if [ $? -gt 0 ]; then continue; fi

        if [ -f $file_path ]; then
            local strip_file_path=${file_path:2}
            local src=$SRC_OVERLAY_DIR/$strip_file_path
            local des=$ROOT_DIR/$strip_file_path
            echo "cp -af $src $des"
            cp -af $src $des
        fi
    done

    if [ $? -gt 0 ]
    then
        echo "Failed to copy src files!"
        exit 1
    fi
}

function copy_src_files_if_needed()
{
    echo "SRC_OVERLAY_ENABLE=$SRC_OVERLAY_ENABLE SRC_OVERLAY_IN_CASE=$SRC_OVERLAY_IN_CASE"
    if [ x$SRC_OVERLAY_ENABLE = x"true" ]; then
        if [[ x$SRC_OVERLAY_IN_CASE == x"factory" && x$FACTORY_VERSION_MODE == x"true" ]] || \
           [[ x$SRC_OVERLAY_IN_CASE == x"normal" && x$FACTORY_VERSION_MODE == x"" ]] || \
           [[ x$SRC_OVERLAY_IN_CASE == x"both" ]]; then
            copy_src_files
        fi
    fi
}

function build_nonhlos_component()
{
    local component=$(expr "$1" : '^qcom-\(.*\)')
    make_nonhlos_component $component

    if [ "$BUILD_MODE" != "clean" ]; then
        generate_device_bins nonhlos
        copy_nonhlos_component $component $PREBUILT_IMGS_DIR
        copy_nonhlos_component $component $VER_IMAGES_DIR
        copy_nonhlos_component_elf $component $SYMBOLS_DIR
    fi
}

# usage: generate_device_bins <mode>
# mode:
#        nonhlos  (generates NON_HLOS.bin alone)
#        hlos     (generates sparse images if rawprogram0.xml exists)
#        null     (generates NON-HLOS.bin and sparse images)
function generate_device_bins()
{
    local mode=$1
    overlay_partition_if_needed
    overlay_contents_if_needed
    cd ${ROOT_DIR}/vendor/qcom/${NON_HLOS_PLATFORM}/
    cp -f hq_build/split_sparse.sh split_sparse.sh
    cp -f hq_build/build_ln.sh build_ln.sh
    cp -f hq_build/rm_ln.sh rm_ln.sh
    chmod 777 split_sparse.sh build_ln.sh rm_ln.sh
    ./split_sparse.sh $QCOM_PLATFORM $MSM_DEVICE_DIR $mode
}

function make_update_api()
{
    cd $ROOT_DIR
    make -j${CPUS} update-api $MAKE_PRINT
    if [ ${PIPESTATUS[0]} -gt 0 ]
    then
        echo "for more information, please check $LOG_FILE_PATH"
        exit 1
    fi
}

function make_target_files_package()
{
    cd $ROOT_DIR
    echo "make -j${CPUS} target-files-package $MAKE_PRINT"
    make -j${CPUS} target-files-package $MAKE_PRINT
    if [ ${PIPESTATUS[0]} -gt 0 ]
    then
        echo "for more information, please check $LOG_FILE_PATH"
        exit 1
    fi
}

function make_hlos()
{
    make_update_api
    case $BUILD_MODE in
        new) 
             if [ "$BUILD_VARIANT" = "user" ]; then
                 make -j${CPUS} $MAKE_PRINT
             else
                 make clean -j${CPUS} $MAKE_PRINT
                 make -j${CPUS} $MAKE_PRINT 
             fi
             ;;
        remake) make -j${CPUS} $MAKE_PRINT ;;
        clean) make clean -j${CPUS} $MAKE_PRINT ;;
    esac

    if [ ${PIPESTATUS[0]} -gt 0 ]
    then
        echo "for more information, please check $LOG_FILE_PATH"
        exit 1
    fi
}

function make_build_ninja()
{
    cd $ROOT_DIR
    make -j${CPUS} build_ninja $MAKE_PRINT

    if [ ${PIPESTATUS[0]} -gt 0 ]
    then
        echo "for more information, please check $LOG_FILE_PATH"
        exit 1
    fi
}

function copy_hlos_component()
{
    local obj=$1
    local dest_dir=$2
    cd $ROOT_DIR
    ./build/make/hq_tools/copy_ap_imgs.sh $HQ_PRODUCT_ID $dest_dir $obj
}

#make root package
function make_root()
{
    cd $ROOT_DIR
    if [-d "./out/target/product/$HQ_PRODUCT_ID/root"]; then
        rm -rf ./out/target/product/$HQ_PRODUCT_ID/root
    fi
    if [-d "./out/target/product/$HQ_PRODUCT_ID/recovery"]; then
        rm -rf ./out/target/product/$HQ_PRODUCT_ID/recovery
    fi

    choosecombo release $HQ_PRODUCT_ID eng
    make recoveryimage -j`expr $CPUS \* 2` 2>&1 | tee $HQ_PRODUCT_ID-recoveryimage.log
    if [ ! -f "./out/target/product/$HQ_PRODUCT_ID/recovery.img" ]; then
        make bootimage -j`expr $CPUS \* 2` 2>&1 | tee $HQ_PRODUCT_ID-bootimage.log
    fi
    if [${PIPESTATUS[0]} -ne 0]; then
        echo "build: make root image error!"
        exit 1
    fi

    if [-d "./out/target/product/$HQ_PRODUCT_ID/root_img"]; then
        rm -rf ./out/target/product/$HQ_PRODUCT_ID/root_img
    fi

    mkdir ./out/target/product/$HQ_PRODUCT_ID/root_img
    mv ./out/target/product/$HQ_PRODUCT_ID/boot.img ./out/target/product/$HQ_PRODUCT_ID/root_img
    if [ -f "./out/target/product/$HQ_PRODUCT_ID/recovery.img" ]; then
        mv ./out/target/product/$HQ_PRODUCT_ID/recovery.img ./out/target/product/$HQ_PRODUCT_ID/root_img
    fi
    
    mv -f ./out/target/product/$HQ_PRODUCT_ID/ramdisk.img ./out/target/product/$HQ_PRODUCT_ID/root_img
    mv -f ./out/target/product/$HQ_PRODUCT_ID/kernel ./out/target/product/$HQ_PRODUCT_ID/root_img
    mv -f ./out/target/product/$HQ_PRODUCT_ID/obj/KERNEL_OBJ/vmlinux ./out/target/product/$HQ_PRODUCT_ID/root_img
    mv -f ./out/target/product/$HQ_PRODUCT_ID/root ./out/target/product/$HQ_PRODUCT_ID/root_img
    mv -f ./out/target/product/$HQ_PRODUCT_ID/recovery ./out/target/product/$HQ_PRODUCT_ID/root_img
}

function switch_build_variant()
{
    choosecombo release $HQ_PRODUCT_ID $BUILD_VARIANT
}

function build_hlos()
{
    #if [ x$BUILD_VARIANT = x"user" ]; then
    #    make_root
    #    switch_build_variant
    #fi

    make_hlos
    if [ "$BUILD_MODE" != "clean" ]; then
        sign_if_needed $BUILD_SIGN_FOR_SECBOOT $BUILD_OBJECT
        copy_hlos_component all $VER_IMAGES_DIR
        copy_lk_symbol $SYMBOLS_DIR
        copy_vmlinux $SYMBOLS_DIR
    fi

    if [ "$BUILD_TGT_FILES_PKG" = "true" ]; then
        make_target_files_package
    fi

    echo "build hlos is done."
}

function build_non_hlos()
{
    make_nonhlos
    if [ "$BUILD_MODE" != "clean" ]; then
        sign_if_needed $BUILD_SIGN_FOR_SECBOOT $BUILD_OBJECT
        generate_device_bins nonhlos
        copy_nonhlos_component all $PREBUILT_IMGS_DIR
        copy_nonhlos_component all $VER_IMAGES_DIR
        copy_efuse_if_needed $VER_IMAGES_DIR
        copy_nonhlos_component_elf all $SYMBOLS_DIR
    fi
    echo "build non-hlos is done."
}

function build_aboot()
{
    cd $ROOT_DIR
    make aboot -j${CPUS} $MAKE_PRINT
    if [ ${PIPESTATUS[0]} -gt 0 ]
    then
        echo "for more information, please check $LOG_FILE_PATH"
        exit 1
    fi

    if [ "$BUILD_MODE" != "clean" ]; then
        #sign_if_needed $BUILD_SIGN_FOR_SECBOOT $BUILD_OBJECT
        copy_hlos_component lk $VER_IMAGES_DIR
        copy_lk_symbol $SYMBOLS_DIR
    fi
}

# $1=*image 
# normally [bootimage systemimage dataimage recoveryimage vendorimage]
function build_hlos_image()
{
    local obj=$1
    local partition=$(expr "$obj" : '\(.*\)image$')
    if [ "$BUILD_MODE" = "nodeps" ]; then
        obj=${obj}-nodeps
    fi

    cd $ROOT_DIR
    echo "build_hlos_image: obj=$obj partition=$partition"
    make $obj -j${CPUS} $MAKE_PRINT
    if [ ${PIPESTATUS[0]} -gt 0 ]
    then
        echo "for more information, please check $LOG_FILE_PATH"
        exit 1
    fi

    if [ "$BUILD_MODE" != "clean" ]; then
        cp -f ${OUT_TARGET_DIR}/${partition}.img $VER_IMAGES_DIR
        if [ "$partition" = "boot" ]; then
            copy_vmlinux $SYMBOLS_DIR
        fi
    fi
}

# mkdir all_images and generate all_images.zip
function zip_all_images()
{
    echo "=============== START TO GENERATE DOWNLOAD PACKAGE(UNSPARSED) ================"
    # delete old
    echo "zip_all_images: delete old folder and zip if exists"
    if [ -e $VERSION_DIR ]; then
        rm -rf $VERSION_DIR
    fi

    if [ -e $VERSION_FILE ]; then
        rm -f $VERSION_FILE
    fi

    # mkdir new
    echo "zip_all_images: copy all images(non-hlos and hlos images)"
    mkdir -p $VER_IMAGES_DIR
    if [ $? -gt 0 ]
    then
        echo "Error: fail to create dir $VER_IMAGES_DIR."
        exit 1
    fi

    # copy prebuilt images
    copy_prebuilt_images $VER_IMAGES_DIR

    # copy hlos image
    copy_hlos_component all $VER_IMAGES_DIR

    # copy non-hlos
    copy_nonhlos_component all $VER_IMAGES_DIR

    # copy efuse if need
    copy_efuse_if_needed $VER_IMAGES_DIR

    # flash_scripts
    if [ -e $FLASH_SCRIPTS_DIR ]; then
        echo "copying flash scripts ..."
        cp $FLASH_SCRIPTS_DIR/* $VERSION_DIR
    fi

    # cust_all_images
    cust_all_images $VERSION_DIR

    # backup rawprogram0.xml to rawprogram0_upgrade.xml and replace filename as "" for persist.img and fs_image.tar.gz.mbn.img
    local rawprogram0=${VER_IMAGES_DIR}/rawprogram0.xml
    local rawprogram0_upgrade=${VER_IMAGES_DIR}/rawprogram0_upgrade.xml
    if [ -e $rawprogram0 ]; then
        cp ${rawprogram0} ${rawprogram0_upgrade}
        sed -i 's/fs_image.tar.gz.mbn.img//g' ${rawprogram0_upgrade}
        sed -i 's/persist.img//g' ${rawprogram0_upgrade}
        sed -i 's/misc.img//g' ${rawprogram0_upgrade}
    fi

    # pack
    echo "$VERSION_DIR: pack ..."
    cd $VERSION_DIR
    zip -r ../$VER_DIR_NAME.zip ./* >>/dev/null
    echo "$VER_DIR_NAME.zip is done."
    echo "zip_all_images done."
}



# mkdir all_sparse_images and generate all_sparse_images.zip
function zip_all_sparse_images()
{
    echo "================ START TO GENERATE DOWNLOAD PACKAGE(SPARSED) ================="
    # delete old
    echo "all_sparse_images: delete old folder and zip if exists"
    if [ -e $SPARSE_VERSION_DIR ]; then
        rm -rf $SPARSE_VERSION_DIR
    fi

    if [ -e $SPARSE_VERSION_FILE ]; then
        rm -f $SPARSE_VERSION_FILE
    fi

    # mkdir new
    echo "all_sparse_images: copy all images(non-hlos, hlos and sparse images)"
    mkdir -p $SPARSE_VERSION_DIR
    if [ $? -gt 0 ]
    then
        echo "Error: fail to create dir $SPARSE_VERSION_DIR."
        exit 1
    fi

    # copy prebuilt images
    copy_prebuilt_images $SPARSE_VERSION_DIR

    # copy hlos image
    copy_hlos_component all $SPARSE_VERSION_DIR

    # copy non-hlos
    copy_nonhlos_component all $SPARSE_VERSION_DIR

    # copy efuse if need
    copy_efuse_if_needed $SPARSE_VERSION_DIR

    # cust for all_sparse_image
    cust_all_sparse_images $SPARSE_VERSION_DIR

    # md5 will be used by XI AN tools
    echo "MD5 checksum ..."
    echo "$ROOT_DIR/build/make/hq_tools/Md5Data.py $SPARSE_VERSION_DIR"
    python $ROOT_DIR/build/make/hq_tools/Md5Data.py $SPARSE_VERSION_DIR

    # backup rawprogram_unsparse.xml to rawprogram_unsparse_upgrade.xml and replace filename as "" for persist.img and fs_image.tar.gz.mbn.img
    local rawprogram_unsparse=${SPARSE_VERSION_DIR}/rawprogram_unsparse.xml
    local rawprogram_unsparse_upgrade=${SPARSE_VERSION_DIR}/rawprogram_unsparse_upgrade.xml
    #local rawprogram0_BLANK=${SPARSE_VERSION_DIR}/rawprogram0_BLANK.xml
    #local rawprogram0=${SPARSE_VERSION_DIR}/rawprogram0.xml
    #local validated_emmc_firehose=${SPARSE_VERSION_DIR}/validated_emmc_firehose*.mbn
    if [ -e $rawprogram_unsparse ]; then
        cp ${rawprogram_unsparse} ${rawprogram_unsparse_upgrade}
        sed -i 's/fs_image.tar.gz.mbn.img//g' ${rawprogram_unsparse_upgrade}
        sed -i 's/persist_1.img//g' ${rawprogram_unsparse_upgrade}
        sed -i 's/misc.img//g' ${rawprogram_unsparse_upgrade}
    fi
    #rm ${rawprogram_unsparse}
    #rm ${rawprogram0_BLANK}
    #rm ${rawprogram0}
    #rm ${validated_emmc_firehose}

    # pack
    cd $SPARSE_VERSION_DIR
    echo "$SPARSE_VERSION_DIR: pack ..."
    zip -r ../$SPARSE_VER_DIR_NAME.zip ./* >>/dev/null
    echo "$SPARSE_VER_DIR_NAME.zip is done."
}

function build_all()
{
    make_hlos
    make_nonhlos
    sign_if_needed $BUILD_SIGN_FOR_SECBOOT $BUILD_OBJECT
    generate_device_bins
    if [ "$BUILD_TGT_FILES_PKG" = "true" ]; then
        make_target_files_package
    fi
    backup_symbols
    #zip_all_images
    zip_all_sparse_images
}

function setup_ccache()
{
    if [[ x$CI_CCACHE_PATH != x"" && -d $CI_CCACHE_PATH ]]; then
        export CCACHE_DIR=$CI_CCACHE_PATH/.ccache/$HQ_PRODUCT_ID
    else
        export CCACHE_DIR=./.ccache/$HQ_PRODUCT_ID
    fi

    export USE_CCACHE=1
    echo "CCACHE_DIR=$CCACHE_DIR USE_CCACHE=$USE_CCACHE"
    if [ ! -e $CCACHE_DIR ]; then
        mkdir -p $CCACHE_DIR
    fi
}

function delete_ccache()
{
    prebuilts/misc/linux-x86/ccache/ccache -C
    rm -rf $CCACHE_DIR
}

function create_ccache()
{
    echo -e "\nINFO: Setting CCACHE with 50 GB\n"
    delete_ccache
    setup_ccache
    prebuilts/misc/linux-x86/ccache/ccache -M 50G
}

# Parse Parameters
function parse_params()
{
    TEMP=`getopt -o lescfthv:o:m: --long license,efuse,sign,cust-key,factory,tgt-files,help,variant:,object:,mode: -n '* ERROR' -- "$@"`
    if [ $? != 0 ] ; then echo error "$0 exited with doing nothing." >&2 ; exit 1 ; fi

    # Note the quotes around $TEMP: they are essential!  
    eval set -- "$TEMP"

    # set option values  
    while true; do
        if [ "$1" = "" ]; then break; fi
        case "$1" in
            -h | --help) usage; exit 1 ;;
            -l | --license) HQ_BUILD_ARM_LICENSE=true; shift ;;
            -e | --efuse) HQ_EFUSE_ENABLE=true; shift ;;
            -s | --sign) BUILD_SIGN_FOR_SECBOOT=true; shift ;;
            -c | --cust-key) HQ_USE_CUST_KEY=true; shift ;;
            -f | --factory) export FACTORY_VERSION_MODE=true; shift ;;
            -t | --tgt-files) BUILD_TGT_FILES_PKG=true; shift ;;
            -v | --variant) BUILD_VARIANT=$2; shift 2 ;;
            -o | --object) BUILD_OBJECT=$2; shift 2 ;;
            -m | --mode) BUILD_MODE=$2; shift 2 ;;
            --) HQ_PRODUCT_ID=$2; shift 2 ;;
            *) echo error "Invalid option! use [$0 -h] to view the help info." ; exit 1 ;;
         esac
    done
}

# check env
function check_env()
{
    check_gcc_version
    check_build_mode
    check_build_variant
    check_security
    select_platform_match_project
}

# Show Build Info
function show_build_info()
{
    show_java_version
    echo "================================================="
    echo "HQ_PROJECT_ID=$HQ_PROJECT_ID"
    echo "HQ_PRODUCT_Q6006=$HQ_PRODUCT_Q6006"
    echo "HQ_PRODUCT_ID=$HQ_PRODUCT_ID"
    echo "HQ_EFUSE_ENABLE=$HQ_EFUSE_ENABLE"
    echo "BUILD_SIGN_FOR_SECBOOT=$BUILD_SIGN_FOR_SECBOOT"
    echo "HQ_BUILD_ARM_LICENSE=$HQ_BUILD_ARM_LICENSE"
    echo "HQ_RFCARD_MODE=$HQ_RFCARD_MODE"
    echo "BUILD_VARIANT=$BUILD_VARIANT"
    echo "BUILD_OBJECT=$BUILD_OBJECT"
    echo "BUILD_MODE=$BUILD_MODE"
    echo "BUILD_TGT_FILES_PKG=$BUILD_TGT_FILES_PKG"
    echo "MSM_DEVICE_DIR=$MSM_DEVICE_DIR"
    echo "QCOM_PLATFORM=$QCOM_PLATFORM"
    echo "OUT_TARGET_DIR=$OUT_TARGET_DIR"
    echo "================================================="
}

function sign_if_needed()
{
    if [ "$1" == "true" ]; then
	echo -e "\n===================================== START TO SIGN IMAGES ======================================\n"
	cd ${ROOT_DIR}/vendor/qcom/${NON_HLOS_PLATFORM}

	if [ ! -e "./hq_build/sign_apq8009.sh" ]; then
	    echo -e "\n[`date +"%Y-%m-%d %H:%M:%S"`] ====== WARNING NO FIND : ./hq_build/sign_apq8009.sh ======\n"
	    return
	fi

	if [ "$2" == "hlos" ] || [ "$2" == "aboot" ]; then
	    ./hq_build/sign_apq8009.sh $QCOM_PLATFORM ${OUT_TARGET_DIR}/emmc_appsboot.mbn  2>&1 | tee ${LOG_DIR}/sign_images_ap.log
	elif [ "$2" == "non-hlos" ]; then
	    ./hq_build/sign_apq8009.sh $QCOM_PLATFORM "non-hlos"  2>&1 | tee ${LOG_DIR}/sign_images_bp.log
	else
	    ./hq_build/sign_apq8009.sh $QCOM_PLATFORM ${OUT_TARGET_DIR}/emmc_appsboot.mbn  2>&1 | tee ${LOG_DIR}/sign_images_ap.log
	    ./hq_build/sign_apq8009.sh $QCOM_PLATFORM "non-hlos"  2>&1 | tee ${LOG_DIR}/sign_images_bp.log
	fi

	cd -
	echo -e "\n===================================== SIGN IMAGES COMPLETE ======================================\n"
    fi
}

function add_project_copy_files_to_mk()
{   
    if [[ ! -e $PROJECT_COPY_OUT_DIR ]]; then
        echo "no project copy_out_files dir"
        return 1  
    fi

    cd $PROJECT_COPY_OUT_DIR
    
    local src_dir=`pwd`
    local file_path_list=`find . -name "*"`    
    local n=0
    local count=0

    #get file count
    for file_path in $file_path_list
    do
        filter_out_readme $file_path
        if [ $? -gt 0 ]; then continue; fi

        if [ -f ${file_path} ]; then
            local strip_file_path=${file_path:2}
            local exist=`grep -e ".*/${strip_file_path}:${strip_file_path}" $PRODUCT_COPY_FILES | wc -l`
            if [ $exist == 0 ]; then
                copy_file_path[count]=${file_path}
                let count+=1
            fi
        fi
    done
    echo "file count in project dir=$count"

    if [ $count -gt 0 ]; then
        echo "# project product copy files" >> $PRODUCT_COPY_FILES
        echo "PRODUCT_COPY_FILES += \\" >> $PRODUCT_COPY_FILES
        for file_path in ${copy_file_path[@]}
        do
            let n+=1
            local strip_file_path=${file_path:2}
            local src=${src_dir}/${strip_file_path}
            if [ $n == $count ]; then
                echo "    ${src}:${strip_file_path}" >> $PRODUCT_COPY_FILES
            else
                echo "    ${src}:${strip_file_path} \\" >> $PRODUCT_COPY_FILES
            fi
        done
    fi
}

function create_product_copy_files_mk()
{
    echo "================================ CREATE product_copy_file.mk ===================================="
    PRODUCT_COPY_FILES=${ROOT_DIR}/device/huaqin/${HQ_PRODUCT_ID}/product_copy_files.mk

    if [ -e $PRODUCT_COPY_FILES ]; then
        rm -f $PRODUCT_COPY_FILES
    fi

    touch $PRODUCT_COPY_FILES
    if [ $? -gt 0 ]; then
        echo "***** Failed to create $PRODUCT_COPY_FILES *****"
        exit 1
    fi

    echo "# Auto-generated product copy files makefile" > $PRODUCT_COPY_FILES
    echo "" >> $PRODUCT_COPY_FILES

    #add_sub_project_copy_files_to_mk
    #add_project_copy_files_to_mk
    echo "=============================== product_copy_file.mk CREATED ===================================="
}

# load functions
function load_functions()
{
    source $ROOT_DIR/build/make/hq_tools/3rd-party.sh
    #source $ROOT_DIR/build/make/hq_tools/$HQ_PRODUCT_ID/sign_images.sh
    #source $ROOT_DIR/build/make/hq_tools/$HQ_PRODUCT_ID/use_cust_key.sh
    source $ROOT_DIR/build/make/hq_tools/$HQ_PRODUCT_ID/package_version.sh
    #if [ $HQ_USE_CUST_KEY = "true" ]; then
    #    use_cust_key
    #fi
}

# init ccache
function init_ccache()
{
    if [ "$CCACHE" = "true" ]; then
        create_ccache
    fi
}

# lunch project
function lunch_project()
{
    cd $ROOT_DIR
    source build/envsetup.sh
    lunch ${HQ_PRODUCT_ID}-${BUILD_VARIANT}
    if [ $? -gt 0 ]; then
        exit 1
    fi
}

# init log file
function init_logfile()
{
    local obj=$1
    if [[ ! -e $LOG_DIR ]]; then
        mkdir -p $LOG_DIR
    fi
    
    if [ x$obj = x"all" ]; then
        obj=build_all
    fi

    dt_str=`date +"%Y-%m-%d_%H:%M:%S"`
    LOG_FILE=${obj}_${dt_str}.log
    LOG_FILE_PATH=$LOG_DIR/$LOG_FILE
}

# handle build mode. if handled, exit 0 
function handle_build_mode()
{
    init_logfile $BUILD_MODE
    case $BUILD_MODE in
        mm | mma)
            if [[ "$BUILD_OBJECT" =~ "$ROOT_DIR" ]]; then
                mm_dir=$BUILD_OBJECT
            else
                mm_dir=$ROOT_DIR/$BUILD_OBJECT
            fi

            if [ -d $mm_dir ]; then
                cd $mm_dir
                $BUILD_MODE 2>&1 | tee $LOG_FILE_PATH
                echo "log saved in $LOG_FILE_PATH"
                exit 0
            else
                echo "******Invalid BUILD_OBJECT=$BUILD_OBJECT"
                exit 1
            fi
            ;;
        mmm | mmma)
            if [[ "$BUILD_OBJECT" =~ "$ROOT_DIR" ]]; then
                mmm_dir=$BUILD_OBJECT
            else
                mmm_dir=$ROOT_DIR/$BUILD_OBJECT
            fi

            if [ -d $mmm_dir ]; then
                $BUILD_MODE $mmm_dir 2>&1 | tee $LOG_FILE_PATH
                echo "log saved in $LOG_FILE_PATH"
                exit 0
            else
                echo "******Invalid BUILD_OBJECT=$BUILD_OBJECT"
                exit 1
            fi 
            ;;  
        preconfig)
            preconfig_object $BUILD_OBJECT 2>&1 | tee $LOG_FILE_PATH
            exit 0
            ;;
        prebuilt)
            prebuilt_object $BUILD_OBJECT 2>&1 | tee $LOG_FILE_PATH
            exit 0
            ;;     
        nodeps)
            init_logfile $BUILD_OBJECT-$BUILD_MODE
            case $BUILD_OBJECT in
                bootimage | systemimage | userdataimage | recoveryimage | vendorimage)
                    build_hlos_image $BUILD_OBJECT 2>&1 | tee $LOG_FILE_PATH
                    exit 0 ;;
                *)
                    echo "***** Unsupported BUILD_OBJECT=${BUILD_OBJECT} *****"
                    echo "Only bootimage, systemimage, userdataimage and recoveryimage are allowed when --mode=nodeps"
                    exit 1 ;;
            esac
            ;;
        clean)
            case $BUILD_OBJECT in
                all | hlos | non-hlos | qcom-*) ;;
                *) echo "***** NO supported .PHONY *****"; exit 1 ;;
            esac
            ;;
    esac
}

# handle build object
function handle_build_object()
{
	if [ "${BUILD_MODE}" != "clean" ]; then
	    create_product_copy_files_mk
    	preconfig_object all
    	add_project_copy_files_to_mk
    	cd ${ROOT_DIR}
	fi
    init_logfile $BUILD_OBJECT
    case $BUILD_OBJECT in
        all)           build_all 2>&1 | tee $LOG_FILE_PATH ;;
        update-api)    make_update_api 2>&1 | tee $LOG_FILE_PATH ;;
        hlos)          build_hlos  2>&1 | tee $LOG_FILE_PATH ;;
        non-hlos)      build_non_hlos 2>&1 | tee $LOG_FILE_PATH ;;
        aboot)         build_aboot 2>&1 | tee $LOG_FILE_PATH ;;
        tgt-files)     make_target_files_package 2>&1 | tee $LOG_FILE_PATH ;;
        *image)        build_hlos_image $BUILD_OBJECT 2>&1 | tee $LOG_FILE_PATH ;;
        qcom-*)        build_nonhlos_component $BUILD_OBJECT 2>&1 | tee $LOG_FILE_PATH ;;
        build_ninja)   make_build_ninja 2>&1 | tee $LOG_FILE_PATH ;;
        *)             echo "***** Unsupported BUILD_OBJECT=${BUILD_OBJECT} *****"; exit 1 ;;
    esac
}

# do main
function do_main()
{
    parse_params $@
    load_functions
    init_variables
    init_version_dirs
    check_env
    show_build_info
    init_ccache
    copy_src_files_if_needed
    lunch_project
    handle_build_mode
    handle_build_object
}

# start
do_main $@

