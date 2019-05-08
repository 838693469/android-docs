#!/bin/bash
#########################################################################
# File Name: myenviron_amss.sh
# Author: WangSen
# Email: wangs_hs@163.com
# Created Time: 2018年01月26日 星期五 09时49分22秒
#########################################################################

#****************************************#
CPU_Processor=`cat /proc/cpuinfo |grep processor | wc -l`
export thread_jobs=$[${CPU_Processor} + 4]
#****************************************#
export QFIL_WHITE="\\033[0m"
export QFIL_GREEN="\\033[40;32m"
export QFIL_YELLOW="\\033[40;33m"
export QFIL_RED="\\033[40;31m"
#****************************************#

### README
# 00:1B:11:09:9E:69
# rm <target_root>/BOOT.BF.3.3/boot_images/build/ms/setenv.sh
# rm <target root>/MPSS.JO.2.0/modem_proc/build/ms/setenv.sh

export TOOLS_PATH=/WorkSpace/Tools/qcom_Tools

function environment_setup()
{
    echo -e "\n${QFIL_YELLOW}====== [amss] Configure the environment ======${QFIL_WHITE}\n"
    export BUILDSPEC=KLOCWORK

    ###### LICENSE ######
    export ARMLMD_LICENSE_FILE=${TOOLS_PATH}/ARMLMD_LICENSE_FILE/DSlicense.lic
    export LM_LICENSE_FILE=${ARMLMD_LICENSE_FILE}

    export PYTHON_PATH=/usr/bin
    export PYTHONPATH=${PYTHON_PATH}
    export MAKE_PATH=/usr/bin
    #export ARMTOOLS=ARMCT5.01
    export ARMROOT=${TOOLS_PATH}/ARM_Compiler_5.01u3
    export ARM_COMPILER_PATH=${ARMROOT}/bin64
    export ARMLIB=${ARMROOT}/lib
    export ARMINCLUDE=${ARMROOT}/include
    export ARMINC=${ARMINCLUDE}
    export ARMCONF=${ARMROOT}/bin64
    export ARMDLL=${ARMROOT}/bin64
    export ARMBIN=${ARMROOT}/bin64
    export ARMHOME=$ARMROOT
    export PATH=${PYTHON_PATH}:${MAKE_PATH}:${ARM_COMPILER_PATH}:${PATH}

    ###### Build RPM images ######
    export ARMPATH=${ARM_COMPILER_PATH}
    export ARMTOOLS=RVCT41
    # Force to set job number to 1 to avoid ARM license concurrency access conflicts
    #export SCONS_OVERRIDE_NUM_JOBS=1

    ###### Build TZ images ######
    export LLVMTOOLS=LLVM
    export LLVMROOT=${TOOLS_PATH}/llvm/3.5.2.5
    export LLVMBIN=$LLVMROOT/bin
    export LLVMLIB=$LLVMROOT/lib/clang/3.5.2/lib/linux
    export MUSLPATH=$LLVMROOT/tools/lib64
    export MUSL32PATH=$LLVMROOT/tools/lib32
    export LLVMINC=$MUSLPATH/include
    export LLVM32INC=$MUSL32PATH/include
    export LLVMTOOLPATH=$LLVMROOT/tools/bin
    ###### GCC ######
    export GNUROOT=${TOOLS_PATH}/linaro-toolchain/gcc-linaro-4.9-2014.11-x86_64_aarch64-elf
    export GNUARM7=${TOOLS_PATH}/linaro-toolchain/gcc-linaro-4.9-2014.11-x86_64_arm-linux-gnueabihf
    export PATH=$GNUTOOL:$PATH 

    ###### Build MPSS ADSP images ######
    export HEXAGON_ROOT=${TOOLS_PATH}/HEXAGON_Tools
    #Defualt setting from build_cfg.xml of hexgen
    export HEXAGON_RTOS_RELEASE=8.0.09
    #export HEXAGON_Q6VERSION=v55
    #export HEXAGON_IMAGE_ENTRY=0x86C00000
}

environment_setup
echo -e "\n-------------------------------------------------------\n"
env
echo -e "\n-------------------------------------------------------\n"

sync
echo -e "\n${QFIL_GREEN}######## [${BASH_SOURCE[0]}] Execute successfully  ########${QFIL_WHITE}\n"
