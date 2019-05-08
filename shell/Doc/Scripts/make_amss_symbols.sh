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

set -o errexit
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
    bash $0 <CHIP_ID> [OPTIONS]
        CHIP_ID (Default: 8937)

Description:
    Builds AMSS tree for given CHIP_ID

OPTIONS:
    -h, --help
        Display this help message

    -c, --clean_build
        Clean build - build from scratch by removing

    -i, --image
        Specify image to be build/re-build (common | modem | boot | tz | rpm | adsp)

    -s, --sign_mbn
        Specify .mbn to be sign (all)

USAGE
}


build_symbols () {
    common_files=(
    CNSS.PR.4.0/wcnss_proc/build/ms/8937*.elf
    )

    adsp_files=(
    ${ADSP_DIR}/adsp_proc/build/ms/*.elf
    ${ADSP_DIR}/adsp_proc/qdsp6/qshrink/src/msg_hash.txt
    )

    modem_files=(
    ${MPSS_DIR}/modem_proc/build/ms/*.elf
    ${MPSS_DIR}/modem_proc/build/myps/qshrink/msg_hash.txt
    )

    boot_files=(
    ${SBL1_DIR}/boot_images/core/boot/secboot3/hw/msm${CHIP_ID}/sbl1/*.elf
    )

    rpm_files=(
    ${RPM_DIR}/rpm_proc/core/bsp/rpm/build/*.elf
    )

    tz_files=(
    ${TZ_DIR}/trustzone_images/core/bsp/qsee/build/ZALAANAA/*.elf
    ${TZ_DIR}/trustzone_images/core/bsp/devcfg/build/ZALAANAA/*.elf
    )


    echo -e "\nINFO: Symbols '$IMAGE' for $CHIP_ID\n"

    if [ ! -d "$Symbols_DIR" ]; then
	mkdir -p $Symbols_DIR
    fi

    for m in $Components
    do
	if [ -d "$Symbols_DIR/${m}" ]; then
	    rm -rf $Symbols_DIR/${m}
	fi
	mkdir -p $Symbols_DIR/${m}

	module_files=${m}"_files[@]"
	for i in "${!module_files}"
	do
	    cp -vLrf $i $Symbols_DIR/${m}
	done
    done
}

build_config_source() {
    echo -e "\nINFO: Config Source environment for $CHIP_ID\n"

    SBL1_DIR=BOOT.BF.3.3
    TZ_DIR=TZ.BF.4.0.5_WW
    RPM_DIR=RPM.BF.2.2
    ADSP_DIR=ADSP.8953.2.8.4_WW
    MPSS_DIR=MPSS.JO.3.0
    MSM_LA_DIR=MSM${CHIP_ID}.LA.3.0.1

    echo -e "\n================================================="
    echo "LOG_FILE=$LOG_FILE"
    echo -e "-------------------------------------------------"
    echo "MSM_LA_DIR=$MSM_LA_DIR"
    echo "SBL1_DIR=$SBL1_DIR"
    echo "TZ_DIR=$TZ_DIR"
    echo "RPM_DIR=$RPM_DIR"
    echo "ADSP_DIR=$ADSP_DIR"
    echo "MPSS_DIR=$MPSS_DIR"
    echo -e "-------------------------------------------------"
    echo -e "=================================================\n"
    sync
}


############## Set defaults ##############
TOP_DIR=`pwd`
CHIP_ID="8937"

LOG_DIR=${TOP_DIR}/logs
if [ ! -d "$LOG_DIR" ]; then
    mkdir -p ${LOG_DIR}
fi
#NOW_DATE=`date +%Y%m%d_%H-%M-%S`
NOW_DATE=`date +%Y%m%d`

None_HLOS=${TOP_DIR}
echo -e "\nINFO: Build None_HLOS is <$None_HLOS>\n"

MBN_OUT_DIR=${None_HLOS}/out
if [ ! -d "$MBN_OUT_DIR" ]; then
    mkdir -p ${MBN_OUT_DIR}
fi
Symbols_DIR=${MBN_OUT_DIR}/symbols
###########################################


# Setup getopt.
long_opts="help,clean_build,image:,log_file:,sign_mbn"
getopt_cmd=$(getopt -o hci:l:s --long "$long_opts" \
            -n $(basename $0) -- "$@") || \
            { echo -e "\nERROR: Getopt failed. Extra args\n"; usage; exit 1;}

eval set -- "$getopt_cmd"

while true; do
    case "$1" in
        -h|--help) usage; exit 0;;
        -c|--clean_build) CLEAN_BUILD="true";;
        -i|--image) IMAGE="$2"; shift;;
        -l|--log_file) LOG_FILE="$2"; shift;;
        -s|--sign_mbn) IMAGE="all"; shift;;
        --) shift; break;;
    esac
    shift
done

# Mandatory argument
if [ $# -eq 0 ]; then
    echo -e "${QFIL_YELLOW}"
    read -p "Warning: Use Default CHIP_ID='${CHIP_ID}' [Y/N]: " SIZECHECK
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
    echo -e "\nERROR: Extra inputs. Only need CHIP_ID .\n"
    usage
    exit 1
else
    CHIP_ID="$1"; shift
fi
LOG_FILE=${LOG_DIR}/symbols_${CHIP_ID}

echo -e "\n================================================="
echo "None_HLOS=$None_HLOS"
echo "CHIP_ID=$CHIP_ID"
echo "CLEAN_BUILD=$CLEAN_BUILD"
echo "IMAGE=$IMAGE"
echo "MBN_OUT_DIR=$MBN_OUT_DIR"
echo "Symbols_DIR=$Symbols_DIR"
echo -e "=================================================\n"


case $IMAGE in
    all)
	Components="common modem boot tz rpm adsp"
	;;
    common | modem | boot | tz | rpm | adsp)
	Components="$IMAGE"
	if [ $? -ne 0 ]; then
	    echo -e "\n[`date +"%Y-%m-%d %H:%M:%S"`] ====== $@ :     Failure ======\n"
	fi
	;;
    *)
	echo -e "\nIMAGE Only: common | modem | boot | tz | rpm | adsp\n"
	exit 1 ;;
esac


LOG_FILE=${LOG_FILE}_${IMAGE}_${NOW_DATE}

build_config_source

read -p "Warning: Please confirm that the information is correct [Continue] ?"

cd $None_HLOS
build_symbols 2>&1 | tee ${LOG_FILE}.log


sync
echo -e "\n${QFIL_GREEN}######## [${BASH_SOURCE}] make completed successfully  ########${QFIL_WHITE}\n"
sync
