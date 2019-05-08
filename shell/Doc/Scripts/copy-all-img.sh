#!/bin/bash

echo -e "\n========================= BEGIN TO COPY IMAGES =========================\n"

#platform
qcom_platform=$1
if [[ "${qcom_platform}" != "8917" && \
      "${qcom_platform}" != "8953" ]]
then
    echo "Unsupported QCOM TARGET_FAMILY=$1"
    exit 1
else
    echo "QCOM TARGET_FAMILY=${qcom_platform}"
fi

#components
if [ "$2" = "all" ]; then
#    echo "copy_all_img: HQ_BUILD_USE_SIGN=$HQ_BUILD_USE_SIGN"
#    if [ "$HQ_BUILD_USE_SIGN" = "true" ]; then
        components="common adsp modem tz boot rpm"
#    else
#        components="common adsp modem tz"
#    fi
else
    components="common "$2
fi

echo "copy components: $components"

#mkdir
CHIPCODE_DEST_DIR=$3
if [ "${CHIPCODE_DEST_DIR}" == "" ] ; 
then
    echo "Invalid CHIPCODE_DEST_DIR!"
    exit 1
fi

if [ ! -d "$CHIPCODE_DEST_DIR" ]; then
    mkdir -p $CHIPCODE_DEST_DIR
    if [ $? != 0 ]; then exit 1; fi
fi

echo "Destination dir: $CHIPCODE_DEST_DIR"

if [ "${qcom_platform}" = "8917" ]; then
common_files=(
MSM8917.LA.2.0/common/build/bin/asic/NON-HLOS.bin
MSM8917.LA.2.0/common/build/gpt_both0.bin
MSM8917.LA.2.0/common/build/gpt_main0.bin
MSM8917.LA.2.0/common/build/gpt_backup0.bin
MSM8917.LA.2.0/common/sectools/resources/build/fileversion2/sec.dat
MSM8917.LA.2.0/common/config/partition.xml
MSM8917.LA.2.0/common/build/zeros_1sector.bin
MSM8917.LA.2.0/common/build/zeros_33sectors.bin
MSM8917.LA.2.0/common/build/rawprogram0_BLANK.xml
MSM8917.LA.2.0/common/build/rawprogram0.xml
MSM8917.LA.2.0/common/build/patch0.xml
)

adsp_files=(
ADSP.8953.2.8.2/adsp_proc/build/dynamic_signed/8937/adspso.bin
)

modem_files=()

boot_files=(
BOOT.BF.3.3/boot_images/build/ms/bin/LAASANAZ/sbl1.mbn
BOOT.BF.3.3/boot_images/build/ms/bin/LAADANAZ/prog_emmc_firehose_8917_ddr.mbn
BOOT.BF.3.3/boot_images/build/ms/bin/LAADANAZ/validated_emmc_firehose_8917_ddr.mbn
)

rpm_files=(
RPM.BF.2.2/rpm_proc/build/ms/bin/8917/rpm.mbn
)

tz_files=(
TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/tz.mbn
TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/devcfg.mbn
TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/keymaster.mbn
TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/cmnlib.mbn
TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/cmnlib64.mbn
TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/lksecapp.mbn
)


elif [ "${qcom_platform}" = "8953" ]; then
common_files=(
MSM8953.LA.2.0/common/build/bin/asic/NON-HLOS.bin
MSM8953.LA.2.0/common/build/gpt_both0.bin
MSM8953.LA.2.0/common/build/gpt_main0.bin
MSM8953.LA.2.0/common/build/gpt_backup0.bin
MSM8953.LA.2.0/common/sectools/resources/build/fileversion2/sec.dat
MSM8953.LA.2.0/common/config/partition.xml
MSM8953.LA.2.0/common/build/zeros_1sector.bin
MSM8953.LA.2.0/common/build/zeros_33sectors.bin
MSM8953.LA.2.0/common/build/rawprogram0_BLANK.xml
MSM8953.LA.2.0/common/build/rawprogram0.xml
MSM8953.LA.2.0/common/build/patch0.xml
)

modem_files=()

adsp_files=(
ADSP.8953.2.8.2/adsp_proc/build/dynamic_signed/8953/adspso.bin
)

boot_files=(
BOOT.BF.3.3/boot_images/build/ms/bin/JAASANAZ/sbl1.mbn
BOOT.BF.3.3/boot_images/build/ms/bin/JAADANAZ/prog_emmc_firehose_8953_ddr.mbn
BOOT.BF.3.3/boot_images/build/ms/bin/JAADANAZ/validated_emmc_firehose_8953_ddr.mbn
)

rpm_files=(
RPM.BF.2.4/rpm_proc/build/ms/bin/8953/rpm.mbn
)

tz_files=(
TZ.BF.4.0.5/trustzone_images/build/ms/bin/SANAANAA/tz.mbn
TZ.BF.4.0.5/trustzone_images/build/ms/bin/SANAANAA/devcfg.mbn
TZ.BF.4.0.5/trustzone_images/build/ms/bin/SANAANAA/keymaster.mbn
TZ.BF.4.0.5/trustzone_images/build/ms/bin/SANAANAA/cmnlib.mbn
TZ.BF.4.0.5/trustzone_images/build/ms/bin/SANAANAA/cmnlib64.mbn
TZ.BF.4.0.5/trustzone_images/build/ms/bin/SANAANAA/lksecapp.mbn
)

fi

#copy to des dir
for m in $components
do
    files=$m"_files[@]"
    for file in ${!files}
    do
        echo "Copy: $file"
        if [ -e $file ]; then
            cp  $file $CHIPCODE_DEST_DIR
        else
            echo "***FILE NO EXISTS*** $file"
        fi
    done
done
echo -e "\n========================= COPY IMAGES COMPLETE =========================\n"

