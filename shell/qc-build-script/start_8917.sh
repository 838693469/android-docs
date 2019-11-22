#!/bin/bash
WHITE="\\033[0m"
GREEN="\\033[40;32m"
YELLOW="\\033[40;33m"
RED="\\033[40;31m"


start__envsetup()
{
    echo "===envsetup_start"
        
	#source  environment
	source ${TOOLS_PATH}/envsetup.sh

	export MAKE_PATH=/usr/bin
    export PYTHON_PATH=/usr/bin

	ARM_COMPILER="5.01"
	ARM_COMPILER_BUILD_ID="94"
    export ARMROOT=${TOOLS_PATH}
	export ARMTOOLS=ARMCT5.01
    export ARMTOOL=${TOOLS_PATH}/rvct/${ARM_COMPILER}/${ARM_COMPILER_BUILD_ID}
	export ARMLMD_LICENSE_FILE=${ARMTOOL}/DSlicense.lic
	export ARMLIB=${ARMTOOL}/lib
	export ARMINC=${ARMTOOL}/include
	export ARMCONF=${ARMTOOL}/bin
	export ARMDLL=${ARMTOOL}/bin
	export ARMBIN=${ARMTOOL}/bin
	export ARMHOME=${ARMROOT}
    
    #export LLVMBIN=${ARMTOOL}/bin  
    #export LLVMLIB=${ARMTOOL}/lib
    #export LLVMINC=${ARMTOOL}/include
    #export LLVM32INC=${ARMTOOL}/include
    #export LLVMTOOLPATH=${ARMTOOL}

#TZ env
export LLVMTOOLS=LLVM
export LLVMROOT=${TOOLS_PATH}/llvm/3.5.2.5
export LLVMBIN=$LLVMROOT/bin
export LLVMLIB=$LLVMROOT/lib/clang/3.5.2/lib/linux
export MUSLPATH=$LLVMROOT/tools/lib64
export MUSL32PATH=$LLVMROOT/tools/lib32
export LLVMINC=$MUSLPATH/include
export LLVM32INC=$MUSL32PATH/include
export LLVMTOOLPATH=$LLVMROOT/tools/bin
export GNUROOT=${TOOLS_PATH}/linaro-toolchain/gcc-linaro-4.9-2014.11-x86_64_aarch64-elf
export GNUARM7=${TOOLS_PATH}/linaro-toolchain/gcc-linaro-4.9-2014.11-x86_64_arm-linux-gnueabihf
#export PATH=$GNUTOOL:$PATH 
    
    
    

	export HEXAGON_ROOT=${TOOLS_PATH}/hexagon/HEXAGON_Tools
    #Defualt setting from build_cfg.xml of hexgen
	#export HEXAGON_RTOS_RELEASE=5.0.07
	#export HEXAGON_Q6VERSION=v5
	#export HEXAGON_IMAGE_ENTRY:=0x08400000
	
    export PATH=./:$PYTHON_PATH:$MAKE_PATH:$ARMBIN:$ARM_COMPILER_PATH:$PATH
    echo "===envsetup_end"
}

print_info()
{
    echo 
    echo "Build:"
    #echo -e "0. ${GREEN}ALL${WHITE}"
    echo -e "1. ${GREEN}boot_images${WHITE}"
    echo -e "2. ${GREEN}modem${WHITE}"
    echo -e "3. ${GREEN}rpm${WHITE}"
    echo -e "4. ${GREEN}trustzone${WHITE}"
    #echo -e "5. ${GREEN}adsp${WHITE}"
    echo -e "Your choice:\c"
    read build_choose
    
    if [ -z "${build_choose}" ] || [ ${build_choose} -lt 0 ] || [ ${build_choose} -gt 5 ]; then
        print_info
    fi
    
    #add modem choice
    #if [ ${build_choose} == 2 ]; then
    #    echo -e "1. S89116${GREEN}AA1${WHITE}"
    #    echo -e "2. S89116${GREEN}BA1${WHITE}"
    #    echo -e "3. S89116${GREEN}CA1${WHITE}"
    #    echo -e "Your choice:\c"
    #    read build_choose_modem
    #    if [ -z "${build_choose_modem}" ] || [ ${build_choose_modem} -lt 1 ] || [ ${build_choose_modem} -gt 3 ]; then
    #        print_info
    #    fi
    #fi
}

make__adsp()
{
    ADSPLOGFILE=${ERROR_FILE}/adsp_log.txt && rm -rf ${ADSPLOGFILE}
    cd ${TOPDIR}/ADSP.8953.2.8.2/adsp_proc
    python ./build/build.py -c msm8937 -o clean 2>&1 | tee -a ${ADSPLOGFILE}
    python ./build/build.py -c msm8937 -o all 2>&1 | tee -a ${ADSPLOGFILE}
    
    ADSP_RELEASE_DIR=${TOPDIR}/out/adsp
    rm -rf ${ADSP_RELEASE_DIR}
    mkdir -p ${ADSP_RELEASE_DIR}
    cp ${TOPDIR}/ADSP.8953.2.8.2/adsp_proc/build/dynamic_signed/8937/adspso.bin ${ADSP_RELEASE_DIR}
    cp ${TOPDIR}/ADSP.8953.2.8.2/adsp_proc/build/ms/*_reloc.elf ${ADSP_RELEASE_DIR}
 

}

make__boot()
{
    BOOTLOGFILENAME=${ERROR_FILE}/boot_images_log.txt && rm -rf ${BOOTLOGFILENAME}
    
    cd ${TOPDIR}/BOOT.BF.3.3/boot_images/build/ms
    ./build.sh TARGET_FAMILY=8917 --prod -c 2>&1 | tee -a ${BOOTLOGFILENAME}
    ./build.sh TARGET_FAMILY=8917 --prod 2>&1 | tee -a ${BOOTLOGFILENAME}
    BOOT_MAKE_RESULT=${PIPESTATUS[0]}
    
    BOOT_RELEASE_DIR=${TOPDIR}/out/boot
    rm -rf ${BOOT_RELEASE_DIR}
    mkdir -p ${BOOT_RELEASE_DIR}
    cp ${TOPDIR}/BOOT.BF.3.3/boot_images/build/ms/bin/LAASANAZ/sbl1.mbn ${BOOT_RELEASE_DIR}
    cp ${TOPDIR}/BOOT.BF.3.3/boot_images/build/ms/bin/LAADANAZ/prog_emmc_firehose_8917_ddr.mbn ${BOOT_RELEASE_DIR}
    cp ${TOPDIR}/BOOT.BF.3.3/boot_images/core/boot/secboot3/hw/msm8917/sbl1/SBL1_ASIC.elf ${BOOT_RELEASE_DIR}    
   
    
}

make__modem()
{   

    MODEMLOGFILENAME=${ERROR_FILE}/modem_proc_log.txt && rm -rf ${MODEMLOGFILENAME}
    
    #cd ${TOPDIR}/modem_proc/build/ms
    #./build.sh 8916.genns.prod -k -c | tee -a ${MODEMLOGFILENAME}
    #./build.sh 8916.genns.prod -k | tee -a ${MODEMLOGFILENAME}
    
    cd ${TOPDIR}/MPSS.JO.3.0/modem_proc/build/ms
    ./build.sh 8937.genns.prod -k -c | tee -a ${MODEMLOGFILENAME}
    ./build.sh 8937.genns.prod -k | tee -a ${MODEMLOGFILENAME}   
    MODEM_MAKE_RESULT=${PIPESTATUS[0]}
    
     
    MODEM_RELEASE_DIR=${TOPDIR}/out/modem
    rm -rf ${MODEM_RELEASE_DIR}
    mkdir -p ${MODEM_RELEASE_DIR} 
    rm -rf ${TOPDIR}/MSM8917.LA.3.0/common/build/bin
    cd ${TOPDIR}/MSM8917.LA.3.0/common/build && python ./build.py --nonhlos
    cp ${TOPDIR}/MSM8917.LA.3.0/common/build/bin/asic/NON-HLOS.bin ${MODEM_RELEASE_DIR}
    cp ${TOPDIR}/MSM8917.LA.3.0/common/build/gpt_main0.bin ${MODEM_RELEASE_DIR}
    cp ${TOPDIR}/MSM8917.LA.3.0/common/build/gpt_backup0.bin ${MODEM_RELEASE_DIR}
    cp ${TOPDIR}/MSM8917.LA.3.0/common/build/patch0.xml ${MODEM_RELEASE_DIR}
    cp ${TOPDIR}/MPSS.JO.3.0/modem_proc/build/ms/M89378937.genns.prodQ*.elf ${MODEM_RELEASE_DIR} 
    cp ${TOPDIR}/MPSS.JO.3.0/modem_proc/build/ms/orig_MODEM_PROC_IMG_8937.genns.prodQ.elf ${MODEM_RELEASE_DIR}
    cp ${TOPDIR}/MSM8917.LA.3.0/common/sectools/resources/build/fileversion2/sec.dat ${MODEM_RELEASE_DIR}
    cp ${TOPDIR}/MPSS.JO.3.0/modem_proc/build/myps/qshrink/msg_hash.txt ${MODEM_RELEASE_DIR}
    
    #change by wangguolong.wt,change reason:add two define to workable BT && IMET repeat write
    unset FACTORY_FEATURE_NV_IMEI_OVERWRITE
    unset FACTORY_FEATURE_NV_BT_ADDR_OVERWRITE
}

make__rpm()
{
    RPMLOGFILENAME=${ERROR_FILE}/rpm_log.txt && rm -rf ${RPMLOGFILENAME}
    
    cd ${TOPDIR}/RPM.BF.2.2/rpm_proc/build
    echo "unset BUILD_ID"
    unset BUILD_ID
    ./build_8937_8917.sh -c | tee -a ${RPMLOGFILENAME}
    ./build_8937_8917.sh | tee -a ${RPMLOGFILENAME}
    RPM_MAKE_RESULT=${PIPESTATUS[0]}
    
    RPM_RELEASE_DIR=${TOPDIR}/out/rpm
    rm -rf ${RPM_RELEASE_DIR}
    mkdir -p ${RPM_RELEASE_DIR}
    cp ${TOPDIR}/RPM.BF.2.2/rpm_proc/build/ms/bin/8917/rpm.mbn ${RPM_RELEASE_DIR}
    cp ${TOPDIR}/RPM.BF.2.2/rpm_proc/core/bsp/rpm/build/8917/RPM_AAAAANAAR.elf ${RPM_RELEASE_DIR}
   
}

make__tz()
{

    cpu_bind
    
    TZLOGFILENAME=${ERROR_FILE}/tz_log.txt && rm -rf ${TZLOGFILENAME}
    
    cd ${TOPDIR}/TZ.BF.4.0.5/trustzone_images/build/ms
    ./build.sh CHIPSET=msm8937 devcfg sampleapp -c 
    ./build.sh CHIPSET=msm8937 devcfg sampleapp | tee -a ${TZLOGFILENAME}
    ./build.sh CHIPSET=msm8937 goodixfp
	./build.sh CHIPSET=msm8937 sw_fp
    TZ_MAKE_RESULT=${PIPESTATUS[0]}

    TZ_RELEASE_DIR=${TOPDIR}/out/tz
    rm -rf ${TZ_RELEASE_DIR}
    mkdir -p ${TZ_RELEASE_DIR} 
    cp ${TOPDIR}/TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/devcfg.mbn ${TZ_RELEASE_DIR}
    cp ${TOPDIR}/TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/tz.mbn ${TZ_RELEASE_DIR}
    cp ${TOPDIR}/TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/cmnlib.mbn ${TZ_RELEASE_DIR}
    cp ${TOPDIR}/TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/cmnlib64.mbn ${TZ_RELEASE_DIR}
    cp ${TOPDIR}/TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/keymaster.mbn ${TZ_RELEASE_DIR}
    cp ${TOPDIR}/TZ.BF.4.0.5/trustzone_images/core/bsp/qsee/build/ZALAANAA/qsee.elf ${TZ_RELEASE_DIR}
    cp ${TOPDIR}/TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/signed/goodixfp.mbn ${TZ_RELEASE_DIR}
    cp ${TOPDIR}/TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/signed/sw_fp.mbn ${TZ_RELEASE_DIR}    
    #add lksecapp.mbn
    cp ${TOPDIR}/TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/lksecapp.mbn ${TZ_RELEASE_DIR}
    
}

chk_make_result()
{

	if [ "$MODEM_MAKE_RESULT" = "0" ]; then
		echo -e "[modem] compile result is:    ${GREEN}Success${WHITE}"
	else
		echo -e "[modem] compile result is:    ${RED}Failure${WHITE}"
	fi
	if [ "$RPM_MAKE_RESULT"  = "0" ]; then
		echo -e "[rpm] compile result is:      ${GREEN}Success${WHITE}"
	else
		echo -e "[rpm] compile result is:      ${RED}Failure${WHITE}"
	fi
	if [  "$TZ_MAKE_RESULT" = "0" ]; then
		echo -e "[tz] compile result is:       ${GREEN}Success${WHITE}"
	else
		echo -e "[tz] compile result is:       ${RED}Failure${WHITE}"
	fi
	if [ "$BOOT_MAKE_RESULT"  = "0" ]; then
		echo -e "[boot] compile result is:     ${GREEN}Success${WHITE}"
	else
		echo -e "[boot] compile result is:     ${RED}Failure${WHITE}"
	fi
    
}



start__release()
{
    echo "test"
    # ===  BOOT === #   

    
    # === MODEM === #

    
    # === RPM === #　　　　

    
    # === TZ ==== #　    

    
    # === ADSP ==== #　    
    #if [ ${build_choose} -eq 5 ];then
    #    ADSP_RELEASE_DIR=${TOPDIR}/out/adsp
    #fi
    
}

start__make()
{
    #print_info

# ===  BOOT === #   
make__boot 

# === RPM === #　　　　
make__rpm

# === TZ ==== #　    
make__tz        

# === ADSP ==== #　    
make__adsp
          
# === MODEM === #
make__modem      

}

cpu_bind()
{
    echo "[bind_type]: $bind_type"
    cp ${TOPDIR}/TZ.BF.4.0.5/trustzone_images/core/securemsm/trustzone/qsee/mink/oem/config/msm8937/${bind_type}_oem_config.xml ${TOPDIR}/TZ.BF.4.0.5/trustzone_images/core/securemsm/trustzone/qsee/mink/oem/config/msm8937/oem_config.xml
    unset bind_type
}

#=====================================================
#main start
export TOPDIR=$PWD
ERROR_FILE=${TOPDIR}/out/buildlog
TOOLS_PATH=${TOPDIR}/tools
WINGCUST_DIR=${TOPDIR}/wingcust
bind_type=bind


while [ $# -ne 0 ];do
    case "$1" in
    "--ubind")
        export bind_type=ubind
        shift;;
    "--factory")
        export FACTORY_FEATURE_NV_IMEI_OVERWRITE=ON
        export FACTORY_FEATURE_NV_BT_ADDR_OVERWRITE=ON
        shift;;
    *)  
        shift;;
    esac
done


if [ ! -d ${ERROR_FILE} ];then
    mkdir -p ${ERROR_FILE}
fi

start__envsetup
start__make


