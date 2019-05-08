#!/bin/bash
#
# Copyright (c) 2012, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.
#     * Neither the name of The Linux Foundation nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT
# ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

# -号表示开启这个选项，+表示关闭这个选项
set -o errexit
set -o errtrace
#set -o xtrace

#******************************#
QFIL_WHITE="\\033[0m"
QFIL_GREEN="\\033[40;32m"
QFIL_YELLOW="\\033[40;33m"
QFIL_RED="\\033[40;31m"
#******************************#


usage() {
cat <<USAGE

Usage:
    bash $0 <TARGET_PRODUCT> [OPTIONS]
        TARGET_PRODUCT (Default: msm8937_64)

Description:
    Builds Android tree for given TARGET_PRODUCT

OPTIONS:
    -c, --clean_build
        Clean build - build from scratch by removing entire out dir

    -d, --debug
        Enable debugging - captures all commands while doing the build

    -h, --help
        Display this help message

    -i, --image
        Specify image to be build/re-build (aboot | bootimage | systemimage | userdataimage | recoveryimage | vendorimage | persistimage | cacheimage | otapackage)

    -j, --jobs
        Specifies the number of jobs to run simultaneously (Default: 16)

    -k, --kernel_defconf
        Specify defconf file to be used for compiling Kernel

    -l, --sign_mbn
        Specify .mbn to be sign (emmc_appsboot.mbn)

    -m, --module
        Module to be build (run make)

    -p, --project
        Project to be build (mmm)

    -s, --setup_ccache
        Set CCACHE for faster incremental builds (true/false - Default: true)

    -u, --update-api
        Update APIs

    -v, --build_variant
        Build variant (Default: userdebug)

USAGE
}

function check_env_show_info() {
    # check_gcc_version
    local required_version='4.8'
    local gcc_version_str=`gcc --version 2>&1 | grep '^gcc .*[ "]4\.[0-9][\. "$$]'`
    local gcc_version=$(expr "$gcc_version_str" : '.*\(4\.[0-9]\)\.[0-9].*')
    echo -e "\nYour gcc version is: $gcc_version_str"
    if [ "$gcc_version" != "$required_version" ]
    then
        echo "You are attempting to build with the incorrect version of gcc."
        echo "The required version is: $required_version."
        echo "Please update gcc version with vendor/qcom/non-hlos/hq_build/install_gcc4-8-1.sh"
        exit 1
    fi

    echo -e "\n==============SHOW JAVA VERSION============="
    java -version
    javac -version
    echo -e "==============SHOW JAVA VERSION=============\n"
}

function build_sign() {
    echo -e "\nINFO: Sign '$SIGN_MBN' for $TARGET\n"

    local mbn_filename=`basename ${SIGN_MBN}`
    if [ -e "${SIGN_MBN}" ]; then
	python ${SECTOOLS_DIR}/sectools.py secimage -i ${SIGN_MBN} -c ${SECIMAGE_FILE} -sa
	if [ $? -ne 0 ]; then
	    echo -e "\n====== ERROR Execute result is:     Failure ======\n"
	    exit 1
	fi

	if [ "${mbn_filename}" == "emmc_appsboot.mbn" ]; then
	    md5sum ${SECIMAGE_OUTPUT}/appsbl/${mbn_filename}
	    local mbn_dir=${SIGN_MBN%/*}
	    cp -vfLR --remove-destination  ${SECIMAGE_OUTPUT}/appsbl/${mbn_filename} ${mbn_dir}/${TARGET}_${mbn_filename}
	fi
    else
	echo -e "\n*** ERROR FILE NO EXISTS *** '${SIGN_MBN}'\n"
	exit 1
    fi
}


clean_build() {
    echo -e "\nINFO: Removing entire out dir. . .\n"
    make clobber
}

build_android() {
    echo -e "\nINFO: Build Android tree for $TARGET\n"
    make $@
}

build_image() {
    if [ -d $ANDROID_PRODUCT_OUT ]; then
	# '-L'表示跟随所有的符号连接
	# -print0 参数表示find输出的每条结果后面加上 '\0' 而不是换行
	## -0 选项表示以 '\0' 为分隔符，一般与find结合使用 = (-d '\0')
	#find $ANDROID_PRODUCT_OUT -name "dex_bootjars" -prune -o -iregex '.*\.\(prop\)' -print0 | xargs -0 rm -vf

	local clean_image=${IMAGE%image}
	if [ -n "$clean_image" ]; then
	    if [ "${clean_image}" == "boot" ]; then
		clean_image=root 
	    fi
	    echo -e "\nINFO: delete '${clean_image}' dir . . .\n"
	    if [ -d "$ANDROID_PRODUCT_OUT/${clean_image}" ]; then
		rm -vrf $ANDROID_PRODUCT_OUT/${clean_image}
	    fi
	    sync
	fi
    fi

    echo -e "\nINFO: 'make $IMAGE $@' for $TARGET\n"
    make $IMAGE $@
}

build_module() {
    echo -e "\nINFO: Build $MODULE for $TARGET\n"
    make $MODULE $@
}

build_project() {
    echo -e "\nINFO: Build $PROJECT for $TARGET\n"
    mmm $PROJECT
}

update_api() {
    echo -e "\nINFO: Updating APIs\n"
    make update-api
}

setup_ccache() {
    export CCACHE_DIR=./.ccache
    export USE_CCACHE=1
}

delete_ccache() {
    prebuilts/misc/linux-x86/ccache/ccache -C
    rm -rf $CCACHE_DIR
}

create_ccache() {
    echo -e "\nINFO: Setting CCACHE with 10 GB\n"
    setup_ccache

    if [ ! -d "out" ]; then
        delete_ccache
        prebuilts/misc/linux-x86/ccache/ccache -M 10G
    fi
}


############## Set defaults ##############
TARGET="msm8937_64"
VARIANT="userdebug"
JOBS=16
CCACHE="true"

TOP_DIR=`pwd`
LOG_DIR=${TOP_DIR}/logs
if [ ! -d "$LOG_DIR" ]; then
    mkdir -p ${LOG_DIR}
fi
NOW_DATE=`date +%Y%m%d`

None_HLOS=${TOP_DIR}/amss_codes
###########################################


# Setup getopt.
long_opts="clean_build,debug,help,image:,jobs:,kernel_defconf:,sign_mbn:,module:,"
long_opts+="project:,setup_ccache:,update-api,build_variant:"
getopt_cmd=$(getopt -o cdhi:j:k:l:m:p:s:uv: --long "$long_opts" \
            -n $(basename $0) -- "$@") || \
            { echo -e "\nERROR: Getopt failed. Extra args\n"; usage; exit 1;}

eval set -- "$getopt_cmd"

while true; do
    case "$1" in
        -c|--clean_build) CLEAN_BUILD="true";;
        -d|--debug) DEBUG="true";;
        -h|--help) usage; exit 0;;
        -i|--image) IMAGE="$2"; shift;;
        -j|--jobs) JOBS="$2"; shift;;
        -k|--kernel_defconf) DEFCONFIG="$2"; shift;;
        -l|--sign_mbn) SIGN_MBN="$2"; shift;;
        -m|--module) MODULE="$2"; shift;;
        -p|--project) PROJECT="$2"; shift;;
        -u|--update-api) UPDATE_API="true";;
        -s|--setup_ccache) CCACHE="$2"; shift;;
        -v|--build_variant) VARIANT="$2"; shift;;
        --) shift; break;;
    esac
    shift
done

# Mandatory argument
if [ $# -eq 0 ]; then
    echo -e "${QFIL_YELLOW}"
    read -p "Warning: Use Default TARGET_PRODUCT='$TARGET' [Y/N]: " SIZECHECK
    echo -e "${QFIL_WHITE}"
    case $SIZECHECK in
	"y" | "Y")
	    ;;
	"n" | "N" | *)
	    usage
	    exit 1
	    ;;
    esac
elif [ $# -gt 1 ]; then
    echo -e "\nERROR: Extra inputs. Need TARGET_PRODUCT only\n"
    usage
    exit 1
else
    TARGET="$1"; shift
fi

LOG_FILE=${LOG_DIR}/${TARGET}

CMD=" -j$JOBS"
if [ "$DEBUG" = "true" ]; then
    CMD+=" showcommands"
fi
if [ -n "$DEFCONFIG" ]; then
    CMD+=" KERNEL_DEFCONFIG=$DEFCONFIG"
fi

echo -e "\n================================================="
echo "TARGET=$TARGET"
echo "SIGN_MBN=$SIGN_MBN"
echo "None_HLOS=$None_HLOS"
echo "CLEAN_BUILD=$CLEAN_BUILD"
echo "DEBUG=$DEBUG"
echo "IMAGE=$IMAGE"
echo "JOBS=$JOBS"
echo "DEFCONFIG=$DEFCONFIG"
echo "MODULE=$MODULE"
echo "PROJECT=$PROJECT"
echo "UPDATE_API=$UPDATE_API"
echo "CCACHE=$CCACHE"
echo "VARIANT=$VARIANT"
echo "CMD=\"$CMD\""
echo -e "=================================================\n"


if [ -n "$SIGN_MBN" ]; then
    LOG_FILE=${LOG_FILE}_sign_${NOW_DATE}

    case $TARGET in
	8937)
	    CHIP_ID="8937"
	    ;;
	8917)
	    CHIP_ID="8917"
	    ;;
	*)
	    echo -e "\nTARGET Only: 8937 | 8917\n"
	    exit 1 ;;
    esac

    SECTOOLS_DIR=${None_HLOS}/MSM${CHIP_ID}.LA.3.1.2/common/sectools
    SECIMAGE_FILE=${SECTOOLS_DIR}/config/${CHIP_ID}/${CHIP_ID}_secimage.xml
    SECIMAGE_OUTPUT=${SECTOOLS_DIR}/secimage_output/${CHIP_ID}
    echo -e "\n================================================="
    echo "SECTOOLS_DIR=$SECTOOLS_DIR"
    echo "SECIMAGE_FILE=$SECIMAGE_FILE"
    echo "SECIMAGE_OUTPUT=$SECIMAGE_OUTPUT"
    echo -e "=================================================\n"

    build_sign 2>&1 | tee ${LOG_FILE}.log
    exit 0
fi


if [ "$CCACHE" = "true" ]; then
    create_ccache
fi

check_env_show_info

source build/envsetup.sh
lunch $TARGET-$VARIANT
if [ ! "$ANDROID_PRODUCT_OUT" ]; then
    echo -e "\nERORR: Couldn't locate output files.  Try running 'lunch' first.\n"
    exit 1 
fi
echo -e "\n${QFIL_YELLOW}====== ${FUNCNAME[0]}: <$ANDROID_PRODUCT_OUT> ======${QFIL_WHITE}\n"



if [ "$CLEAN_BUILD" = "true" ]; then
    clean_build
fi

if [ "$UPDATE_API" = "true" ]; then
    LOG_FILE=${LOG_FILE}_update_api_${NOW_DATE}
    update_api | tee ${LOG_FILE}.log
fi

if [ -n "$MODULE" ]; then
    LOG_FILE=${LOG_FILE}_${MODULE}_${NOW_DATE}
    build_module "$CMD" | tee ${LOG_FILE}.log
fi

if [ -n "$PROJECT" ]; then
    LOG_FILE=${LOG_FILE}_mmm_${NOW_DATE}
    build_project | tee ${LOG_FILE}.log
fi

if [ -n "$IMAGE" ]; then
    LOG_FILE=${LOG_FILE}_${IMAGE}_${NOW_DATE}

    case $IMAGE in
	aboot | bootimage | systemimage | userdataimage | recoveryimage | vendorimage | persistimage | cacheimage | otapackage)
	    build_image "$CMD" 2>&1 | tee ${LOG_FILE}.log
	    if [ $? -ne 0 ]; then
		echo -e "\n[`date +"%Y-%m-%d %H:%M:%S"`] ====== $@ :     Failure ======\n"
	    fi
	    ;;
	*)
	    echo -e "\nOnly: aboot | bootimage | systemimage | userdataimage | recoveryimage | vendorimage | persistimage | cacheimage | otapackage\n"
	    exit 1 ;;
    esac
fi


#LOG_FILE=${LOG_FILE}_android_${NOW_DATE}
#build_android "$CMD" | tee ${LOG_FILE}.log
