#!/bin/bash
#########################################################################
# File Name: sign_apq8009.sh
# Author: WangSen
# Email: wangs_hs@163.com
# Created Time: 2018年04月03日 星期二 16时23分51秒
#########################################################################

qcom_platform=$1

sectools_dir=vendor/qcom/non-hlos/common/tools/sectools
secimage_output=${sectools_dir}/secimage_output/${qcom_platform}
SECIMAGE_FILE=${sectools_dir}/config/8909/8909_secimage.xml

if [ "${qcom_platform}" = "8909" ]; then
    boot_files=(
    "boot_images/build/ms/bin/8909/emmc/sbl1.mbn  ${secimage_output}/sbl1"
    "boot_images/build/ms/bin/8909/emmc/prog_emmc_firehose_8909_ddr.mbn  ${secimage_output}/prog_emmc_ddr"
    "boot_images/build/ms/bin/8909/emmc/validated_emmc_firehose_8909_ddr.mbn  ${secimage_output}/validated_emmc_ddr"
    )

    rpm_files=(
    "rpm_proc/build/ms/bin/8909/pm8916/rpm.mbn  ${secimage_output}/rpm"
    )

    tz_files=(
    "trustzone_images/build/ms/bin/MAZAANAA/tz.mbn  ${secimage_output}/qsee"
    "trustzone_images/build/ms/bin/MAZAANAA/keymaster.mbn  ${secimage_output}/keymaster"
    "trustzone_images/build/ms/bin/MAZAANAA/keymaster64.mbn  ${secimage_output}/keymaster64"
    "trustzone_images/build/ms/bin/MAZAANAA/sampleapp.mbn  ${secimage_output}/sampleapp"
    "trustzone_images/build/ms/bin/MAZAANAA/widevine.mbn  ${secimage_output}/widevine"
    "trustzone_images/build/ms/bin/MAZAANAA/cmnlib.mbn  ${secimage_output}/cmnlib"
    )

    adsp_files=()

    modem_files=(
    "modem_proc/build/ms/bin/8909.genns.prod/mba.mbn  ${secimage_output}/mba"
    "modem_proc/build/ms/bin/8909.genns.prod/mcfg_hw.mbn  ${secimage_output}/mcfg_hw"
    "modem_proc/build/ms/bin/8909.genns.prod/mcfg_sw.mbn  ${secimage_output}/mcfg_sw"
    "modem_proc/build/ms/bin/8909.genns.prod/qdsp6sw.mbn  ${secimage_output}/modem"
    )

    common_files=(
    "wcnss_proc/build/ms/bin/SCAQMAZ/reloc/wcnss.mbn  ${secimage_output}/wcnss"
    "venus_proc/build/bsp/asic/build/PROD/mbn/reloc/signed/venus.mbn  ${secimage_output}/venus"
    )
else
    echo -e "\n====== ERROR NO SUPPORT: ${qcom_platform} ======\n"
    exit 1
fi


#sign
function sectools_exce()
{
    if [ $# -ne 2 ]; then
	echo -e "\n###### Error: $* ######\n"
	exit 1
    fi
    local file_name=$1
    local out_file_name=`basename ${file_name}`
    if [ "${out_file_name}" == "qdsp6sw.mbn" ]; then
	local out_file=$2/modem.mbn
    else
	local out_file=$2/${out_file_name}
    fi

    if [ -e "${file_name}" ]; then
	python ${sectools_dir}/sectools.py secimage -i ${file_name} -c ${SECIMAGE_FILE} -sa
	if [ $? -ne 0 ]; then
	    echo -e "\n====== ERROR Execute result is:     Failure ======\n"
	    exit 1
	fi

	if [ -e "${out_file}" ]; then
	    cp -f ${out_file} ${file_name}
	else
	    echo -e "\n*** CP ERROR FILE NO EXISTS*** ${out_file}\n"
	    exit 1
	fi
    else
	echo -e "\n*** ERROR FILE NO EXISTS*** ${file_name}\n"
	exit 1
    fi
}

rm -rf ${secimage_output}
#components
if [ "$2" = "non-hlos" ]; then
    components="common modem boot tz rpm adsp"
else
    echo -e "\n############## SIGN AP IMAGES: $2 ##############\n"
    lk_file=${secimage_output}/appsbl

    sectools_exce $2 ${lk_file}
    exit 0
fi


#main
echo -e "\n############## SIGN BP IMAGES: $components #############\n"
for m in $components
do
    module_files=${m}"_files[@]"

    for i in "${!module_files}"
    do
	i=vendor/qcom/non-hlos/${i}
	echo -e "\n====== ${i} ======\n"

	sectools_exce $i
	echo -e "\n### ================================================================= ###\n"
	sync
    done

    if [ "$m" = "modem" ]; then
	vendor/qcom/non-hlos/hq_build/sign_directory.sh ${qcom_platform} "mcfg_sw"
    fi
done

