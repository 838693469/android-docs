#!/bin/bash

echo -e "\n========================== BEGIN TO COPY ELFS ==========================\n"

#platform
qcom_platform=$1
if [[ "${qcom_platform}" != "8937" && \
      "${qcom_platform}" != "8953" ]]
then
    echo "Unsupported QCOM TARGET_FAMILY=$1"
    exit 1
else
    echo "QCOM TARGET_FAMILY=${qcom_platform}"
fi

#components
if [ "$2" = "all" ]; then
        components="adsp modem tz boot rpm"
else
    components=$2
fi

echo "copy components elf: $components"

#mkdir
# elf dest dir should be out/target/product/${HQ_TARGET_DEVICE}/symbols
ELF_DES_DIR=$3
if [ "${ELF_DES_DIR}" == "" ] ; 
then
    echo "Invalid ELF_DES_DIR!"
    exit 1
fi


if [ "${qcom_platform}" = "8937" ]; then
adsp_files=(
ADSP.8953.2.8.2/adsp_proc/build/ms/*.elf
)

modem_files=(
MPSS.JO.2.0/modem_proc/build/ms/*.elf
MPSS.JO.2.0/modem_proc/build/myps/qshrink/*.qsr4
)

boot_files=(
BOOT.BF.3.3/boot_images/core/bsp/bootloaders/sbl1/build/LAASANAZ/SBL1_ASIC.elf
)

rpm_files=(
RPM.BF.2.2/rpm_proc/core/bsp/rpm/build/8937/RPM_AAAAANAAR.elf
)

tz_files=(
TZ.BF.4.0.5/trustzone_images/core/bsp/qsee/build/ZALAANAA/qsee.elf
TZ.BF.4.0.5/trustzone_images/core/bsp/devcfg/build/ZALAANAA/devcfg.elf
TZ.BF.4.0.5/trustzone_images/core/bsp/monitor/build/ZALAANAA/mon.elf
)

fi

#copy to dest dir
for m in $components
do
    # mkdir if needed
    m_elf_des_dir=$ELF_DES_DIR"/$m"
    echo "dest dir: $m_elf_des_dir"
    if [[ ! -e $m_elf_des_dir ]]; then
        echo "mkdir: $m_elf_des_dir"
        mkdir -p $m_elf_des_dir
        if [ $? != 0 ]; then exit 1; fi
    fi

    files=$m"_files[@]"
    for file in ${!files}
    do
        echo "Copy: $file"
        if [ -e $file ]; then
            cp  $file $m_elf_des_dir
        else
            echo "***FILE NO EXISTS*** $file"
        fi
    done
done
echo -e "\n========================== COPY ELFS COMPLETE ==========================\n"

