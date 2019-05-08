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
        Clean build - build from scratch by removing (Default: false)

    -i, --image
        Specify image to be build/re-build (nonhols | modem | sbl1 | tz | rpm | adsp)

    -s, --sign_mbn
        Specify .mbn to be sign (sbl1 | adsp | tz)

USAGE
}


build_config_source() {
    echo -e "\nINFO: Config Source environment for $CHIP_ID\n"

    SBL1_DIR=BOOT.BF.3.3
    TZ_DIR=TZ.BF.4.0.5_WW
    RPM_DIR=RPM.BF.2.2
    ADSP_DIR=ADSP.8953.2.8.4_WW
    MPSS_DIR=MPSS.JO.3.0
    MSM_LA_DIR=MSM${CHIP_ID}.LA.3.1.2

    SECTOOLS_DIR=${None_HLOS}/${MSM_LA_DIR}/common/sectools
    SECIMAGE_FILE=${SECTOOLS_DIR}/config/${CHIP_ID}/${CHIP_ID}_secimage.xml
    SECIMAGE_OUTPUT=${SECTOOLS_DIR}/secimage_output/${CHIP_ID}

    case $CHIP_ID in
	8937)
	    SBL1_MBN=boot_images/build/ms/bin/FAASANAZ/sbl1.mbn
	    ADSP_MBN=adsp_proc/obj/8937/signed/adsp.mbn
	    TZ_MBN=trustzone_images/build/ms/bin/ZALAANAA/tz.mbn
	    ;;
	8917)
	    SBL1_MBN=boot_images/build/ms/bin/LAASANAZ/sbl1.mbn
	    ADSP_MBN=adsp_proc/obj/8937/signed/adsp.mbn
	    TZ_MBN=trustzone_images/build/ms/bin/ZALAANAA/tz.mbn
	    ;;
    esac

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
    echo "SBL1_MBN=$SBL1_MBN"
    echo "ADSP_MBN=$ADSP_MBN"
    echo "TZ_MBN=$TZ_MBN"
    echo -e "-------------------------------------------------"
    echo "SECTOOLS_DIR=$SECTOOLS_DIR"
    echo "SECIMAGE_FILE=$SECIMAGE_FILE"
    echo "SECIMAGE_OUTPUT=$SECIMAGE_OUTPUT"
    echo -e "=================================================\n"


    if false; then
	copy_path=${None_HLOS}/${MSM_LA_DIR}
	cp -vLrf ${copy_path}/E300L_WW/contents.xml ${copy_path}/contents.xml

	copy_path=${None_HLOS}/${MPSS_DIR}/modem_proc/core/storage/fs_tar/src
	cp -vLrf ${copy_path}/fs_signed_img_param_${CHIP_ID}.c ${copy_path}/fs_signed_img_param.c

	copy_path=${None_HLOS}/${MPSS_DIR}/modem_proc/mcfg/configs/mcfg_sw
	cp -vLrf ${copy_path}/generic_17/* ${copy_path}/generic/
	#rm -rf ${copy_path}/generic_17/ ${copy_path}/generic_37/
    fi
    sync
}

build_sign() {
    case $SIGN_MBN in
	sbl1)
	    SIGN_MBN=${None_HLOS}/${SBL1_DIR}/${SBL1_MBN}
	    ;;
	adsp)
	    SIGN_MBN=${None_HLOS}/${ADSP_DIR}/${ADSP_MBN}
	    ;;
	tz)
	    SIGN_MBN=${None_HLOS}/${TZ_DIR}/${TZ_MBN}
	    ;;
    esac
    if [ -z "$SIGN_MBN" ] || [ ! -e "$SIGN_MBN" ]; then
	echo -e "\n*** ERROR FILE NO EXISTS *** '${SIGN_MBN}'\n"
	exit 1
    fi

    echo -e "\nINFO: Sign '$SIGN_MBN' for $CHIP_ID\n"
    local mbn_filename=`basename ${SIGN_MBN}`

    python ${SECTOOLS_DIR}/sectools.py secimage -i ${SIGN_MBN} -c ${SECIMAGE_FILE} -sa
    if [ $? -ne 0 ]; then
	echo -e "\n====== ERROR Execute result is:     Failure ======\n"
	exit 1
    fi

    sign_result=`find -L ${SECIMAGE_OUTPUT} -name "${mbn_filename}"`
    md5sum $sign_result
    cp -vfLR --remove-destination ${sign_result} $SIGN_MBN
    cp -vfLR --remove-destination ${sign_result} $MBN_OUT_DIR/${CHIP_ID}_${mbn_filename}
}

build_nonhols() {
    echo -e "\n${QFIL_YELLOW}====== Build non HLOS: <$None_HLOS> ======${QFIL_WHITE}\n"


    #partition_xml=${None_HLOS}/MSM8953.LA.2.0/common/config/partition.xml
    #sed -i '/sec/ s/filename="sec.dat"/filename=""/g' ${partition_xml}

    # Build HLOS images
    rm -rf ${None_HLOS}/${MSM_LA_DIR}/common/build/bin
    sync

    #   build.py <mode>
    #   Examples:
    #       build.py --nonhlos  (generates NON_HLOS.bin alone)
    #       build.py --hlos     (generates sparse images if rawprogram0.xml exists)
    #       build.py            (generates NON-HLOS.bin and sparse images)
    cd ${None_HLOS}/${MSM_LA_DIR}/common/build
    python ./build.py --nonhlos
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
	echo -e "\n${QFIL_RED}[`date +"%Y-%m-%d %H:%M:%S"`] ====== [${FUNCNAME}] Execute result is:     Failure ======${QFIL_WHITE}\n"
	exit 1
    fi

    cp -vLrf ${None_HLOS}/${MSM_LA_DIR}/common/build/bin/asic/NON-HLOS.bin $MBN_OUT_DIR/${CHIP_ID}_NON-HLOS.bin
}

build_modem() {
    echo -e "\nINFO: Build MPSS for $CHIP_ID\n"
    cd ${None_HLOS}/${MPSS_DIR}/modem_proc/build/ms

    case $CHIP_ID in
	8937 | 8917)
	    # WTR2965
	    if [ "$CLEAN_BUILD" = "true" ]; then
		./build.sh 8937.genns.prod -c
	    fi
	    ./build.sh 8937.genns.prod -k
	    result=$?
	    ;;
	*)
	    echo -e "\nCHIP_ID Only: 8937 | 8917\n"
	    exit 1 ;;
    esac
    if [ $result -ne 0 ]; then
	echo -e "\n${QFIL_RED}[`date +"%Y-%m-%d %H:%M:%S"`] ====== [${FUNCNAME}] Execute result is:     Failure ======${QFIL_WHITE}\n"
	exit 1
    fi
}

build_sbl1() {
    echo -e "\nINFO: Build sbl1 for $CHIP_ID\n"
    cd ${None_HLOS}/${SBL1_DIR}/boot_images/build/ms
    #source setenv.sh

    if [ "$CLEAN_BUILD" = "true" ]; then
	rm -vf ${None_HLOS}/${SBL1_DIR}/${SBL1_MBN}
	./build.sh TARGET_FAMILY=${CHIP_ID} --prod -c
    fi
    ./build.sh TARGET_FAMILY=${CHIP_ID} --prod
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
	echo -e "\n${QFIL_RED}[`date +"%Y-%m-%d %H:%M:%S"`] ====== [${FUNCNAME}] Execute result is:     Failure ======${QFIL_WHITE}\n"
	exit 1
    fi
}

build_tz() {
    echo -e "\nINFO: Build trustzone for $CHIP_ID\n"
    cd ${None_HLOS}/${TZ_DIR}/trustzone_images/build/ms
    #source setenv.sh
    unset BUILD_ID
    #export SCONS_OVERRIDE_NUM_JOBS=1
    #export ARMTOOLS=ARMCT6 #FIXME

    case $CHIP_ID in
	8937 | 8917)
	    if [ "$CLEAN_BUILD" = "true" ]; then
		./build.sh CHIPSET=msm8937 devcfg sampleapp -c
	    fi
	    #./build.sh CHIPSET=msm8937 MAPREPORT=0 tz
	    ./build.sh CHIPSET=msm8937 devcfg sampleapp
	    result=$?
	    ;;
	*)
	    echo -e "\nCHIP_ID Only: 8937 | 8917\n"
	    exit 1 ;;
    esac
    if [ $result -ne 0 ]; then
	echo -e "\n${QFIL_RED}[`date +"%Y-%m-%d %H:%M:%S"`] ====== [${FUNCNAME}] Execute result is:     Failure ======${QFIL_WHITE}\n"
	exit 1
    fi
}

build_rpm() {
    echo -e "\nINFO: Build RPM for $CHIP_ID\n"
    cd ${None_HLOS}/${RPM_DIR}/rpm_proc/build
    unset $BUILD_ID

    if [ "$CLEAN_BUILD" = "true" ]; then
	./build_${CHIP_ID}.sh -c
    fi
    ./build_${CHIP_ID}.sh
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
	echo -e "\n${QFIL_RED}[`date +"%Y-%m-%d %H:%M:%S"`] ====== [${FUNCNAME}] Execute result is:     Failure ======${QFIL_WHITE}\n"
	exit 1
    fi
}

build_adsp() {
    echo -e "\nINFO: Build ADSP for $CHIP_ID\n"
    cd ${None_HLOS}/${ADSP_DIR}/adsp_proc/build

    case $CHIP_ID in
	8937 | 8917)
	    if [ "$CLEAN_BUILD" = "true" ]; then
		python build.py -c msm8937 -o clean
	    fi
	    python build.py -c msm8937 -o all
	    result=$?
	    ;;
	*)
	    echo -e "\nCHIP_ID Only: 8937 | 8917\n"
	    exit 1 ;;
    esac
    if [ $result -ne 0 ]; then
	echo -e "\n${QFIL_RED}[`date +"%Y-%m-%d %H:%M:%S"`] ====== [${FUNCNAME}] Execute result is:     Failure ======${QFIL_WHITE}\n"
	exit 1
    fi
}

build_all() {
    echo -e "\nINFO: Build all non-HLOS tree for $CHIP_ID\n"

    build_modem 2>&1 | tee ${LOG_FILE}_modem.log
    build_sbl1 2>&1 | tee ${LOG_FILE}_boot.log
    build_tz 2>&1 | tee ${LOG_FILE}_tz.log
    build_rpm 2>&1 | tee ${LOG_FILE}_rpm.log
    build_adsp 2>&1 | tee ${LOG_FILE}_adsp.log

    echo -e "\n${QFIL_YELLOW}[`date +"%Y-%m-%d %H:%M:%S"`] ====== Build all non-HLOS result:     Successfully ======${QFIL_WHITE}\n"
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
Secimage_output_DIR=${MBN_OUT_DIR}/secimage_output
Secimage_backup_DIR=${MBN_OUT_DIR}/secimage_backup
###########################################


# Setup getopt.
long_opts="help,clean_build,image:,log_file:,sign_mbn:"
getopt_cmd=$(getopt -o hci:l:s: --long "$long_opts" \
    -n $(basename $0) -- "$@") || \
    { echo -e "\nERROR: Getopt failed. Extra args\n"; usage; exit 1;}

eval set -- "$getopt_cmd"

while true; do
    case "$1" in
	-h|--help) usage; exit 0;;
	-c|--clean_build) CLEAN_BUILD="true";;
	-i|--image) IMAGE="$2"; shift;;
	-l|--log_file) LOG_FILE="$2"; shift;;
	-s|--sign_mbn) SIGN_MBN="$2"; IMAGE="sign"; shift;;
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
LOG_FILE=${LOG_DIR}/${CHIP_ID}

echo -e "\n================================================="
echo "None_HLOS=$None_HLOS"
echo "CHIP_ID=$CHIP_ID"
echo "CLEAN_BUILD=$CLEAN_BUILD"
echo "SIGN_MBN=$SIGN_MBN"
echo "IMAGE=$IMAGE"
echo "MBN_OUT_DIR=$MBN_OUT_DIR"
echo "Symbols_DIR=$Symbols_DIR"
echo "Secimage_output_DIR=$Secimage_output_DIR"
echo "Secimage_backup_DIR=$Secimage_backup_DIR"
echo -e "=================================================\n"


function main()
{
    build_config_source

    if [ -z "$SIGN_MBN" ]; then
	export TOOLS_PATH=/WorkSpace/Tools/qcom_Tools
	source ${TOOLS_PATH}/myenviron_amss.sh
    fi

    case $IMAGE in
	nonhols | modem | sbl1 | tz | rpm | adsp | sign)
	    build_$IMAGE 2>&1 | tee ${LOG_FILE}.log
	    if [ $? -ne 0 ]; then
		echo -e "\n[`date +"%Y-%m-%d %H:%M:%S"`] ====== $@ :     Failure ======\n"
	    fi
	    ;;
	*)
	    echo -e "\nIMAGE Only: nonhols | modem | sbl1 | tz | rpm | adsp\n"
	    exit 1 ;;
    esac
}


cd ${None_HLOS}
if [ -n "$IMAGE" ]; then
    LOG_FILE=${LOG_FILE}_${IMAGE}_${NOW_DATE}

    read -p "Warning: Please confirm that the information is correct [Continue] ?"
    main 2>&1 | tee ${LOG_FILE}.log
fi


sync
echo -e "\n${QFIL_GREEN}######## [${BASH_SOURCE}] make completed successfully  ########${QFIL_WHITE}\n"
sync
