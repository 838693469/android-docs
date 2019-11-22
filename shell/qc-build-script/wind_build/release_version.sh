#!/bin/bash
####################################################################################################################
###   		release_version命令 : 默认release所有image，和下面的all参数效果一样                         	####
###  兼容8917与8937版本（fastboot下载）：./release_version.sh E300L_WW overall					####
###  兼容8917与8937版本（xtt下载）：./release_version.sh E300L_WW overall xtt					####
###  （以上两种方式包含所有需要的文件，含symbols）								####
###  release all含symbols：./release_version.sh E300L_WW symbols						####
###     all images(ap and amss): ./release_version.sh msm8937_64 all                                            ####
###     all images(xtt下载): ./release_version.sh msm8937_64 xtt                                            	####
###              ap images: ./release_version.sh msm8937_64 ap                                                  ####
###                 amss images: ./release_version.sh msm8937_64 amss                                           ####
###                    boot.img: ./release_version.sh msm8937_64 boot                                           ####
###                  system.img: ./release_version.sh msm8937_64 system                                         ####
### ap images except system.img: ./release_version.sh msm8937_64 system-                                        ####
###           emmc_appsboot.mbn: ./release_version.sh msm8937_64 aboot                                          ####
###                  vendor.img: ./release_version.sh msm8937_64 vendor                                         ####
###                recovery.img: ./release_version.sh msm8937_64 recovery                                       ####
###                userdata.img: ./release_version.sh msm8937_64 userdata                                       ####
####################################################################################################################
rootDir=`pwd`
user=`whoami`
PRODUUCT_NAME=
AMSS_Path=amss
CHIPID_DIR=MSM8937.LA.3.0.1
FILES=""
VER_NO=$(cat version | head -1 | awk -F '=' '{print $2}')
UL_NO=$(cat version | sed -n 2p | awk -F '_|-' '{print $3}')


#flag of md5 is exsit or not
function check_md5file(){
if [ -f $OUT_Path/checklist.md5 ];then
    check_tmp=$(grep "\-verified." $OUT_Path/checklist.md5)
    if [[ x$check_tmp != x"" ]];then
        return 1
    else
        return 0
    fi
else
    write_md5
    return 2
fi
}
#write some information to md5 file
function write_md5(){
echo "/*" >> $OUT_Path/checklist.md5
echo "* wind-mobi md5sum checklist" >> $OUT_Path/checklist.md5
echo "*/" >> $OUT_Path/checklist.md5
}
#dispaly green in screen for seccuss

function echo_greeen(){
echo -e "\033[40;32m$1 \033[0m"
}

function release_symbols(){
if [ -d "$sysbols_zip" ];then
    rm -rf $sysbols_zip
    rm -rf $OUT_Path/all_symbols.zip
fi

mkdir -p $OUT_Path/all_symbols
cd $OUT_Path/all_symbols
#cp -a $OUT_Path/symbols/ ap_symbols
cp $OUT_Path/obj/KERNEL_OBJ/vmlinux .
mkdir -p amss_symbols

mkdir -p amss_symbols/CNSS.PR.4.0/wcnss_proc/build/ms
cp $rootDir/$AMSS_Path/CNSS.PR.4.0/wcnss_proc/build/ms/*.elf amss_symbols/CNSS.PR.4.0/wcnss_proc/build/ms/

mkdir -p amss_symbols/RPM.BF.2.2/rpm_proc/core/bsp/rpm/build
cp $rootDir/$AMSS_Path/RPM.BF.2.2/rpm_proc/core/bsp/rpm/build/RPM_AAAAANAAR.elf amss_symbols/RPM.BF.2.2/rpm_proc/core/bsp/rpm/build/

if [ x$PRODUUCT_NAME == x"A306" ];then
mkdir -p amss_symbols/MPSS.JO.3.0/modem_proc/build/ms
mkdir -p amss_symbols/MPSS.JO.3.0/modem_proc/build/myps/qshrink
cp $rootDir/$AMSS_Path/MPSS.JO.3.0_A306/modem_proc/build/ms/*.elf amss_symbols/MPSS.JO.3.0/modem_proc/build/ms/
cp $rootDir/$AMSS_Path/MPSS.JO.3.0_A306/modem_proc/build/myps/qshrink/msg_hash.txt amss_symbols/MPSS.JO.3.0/modem_proc/build/myps/qshrink/
else
mkdir -p amss_symbols/MPSS.JO.3.0/modem_proc/build/ms
mkdir -p amss_symbols/MPSS.JO.3.0/modem_proc/build/myps/qshrink
cp $rootDir/$AMSS_Path/MPSS.JO.3.0/modem_proc/build/ms/*.elf amss_symbols/MPSS.JO.3.0/modem_proc/build/ms/
cp $rootDir/$AMSS_Path/MPSS.JO.3.0/modem_proc/build/myps/qshrink/msg_hash.txt amss_symbols/MPSS.JO.3.0/modem_proc/build/myps/qshrink/
fi

if [ x$PRODUUCT_NAME == x"E300L_WW" ] || [ x$PRODUUCT_NAME == x"8917" ];then
mkdir -p amss_symbols/TZ.BF.4.0.5_WW/trustzone_images/core/bsp/qsee/build/ZALAANAA
cp $rootDir/$AMSS_Path/TZ.BF.4.0.5_WW/trustzone_images/core/bsp/qsee/build/ZALAANAA/qsee.elf amss_symbols/TZ.BF.4.0.5_WW/trustzone_images/core/bsp/qsee/build/ZALAANAA

mkdir -p amss_symbols/ADSP.8953.2.8.4_WW/adsp_proc/build/ms
mkdir -p amss_symbols/ADSP.8953.2.8.4_WW/adsp_proc/qdsp6/qshrink/src
cp $rootDir/$AMSS_Path/ADSP.8953.2.8.4_WW/adsp_proc/build/ms/*.elf amss_symbols/ADSP.8953.2.8.4_WW/adsp_proc/build/ms/
cp $rootDir/$AMSS_Path/ADSP.8953.2.8.4_WW/adsp_proc/qdsp6/qshrink/src/msg_hash.txt amss_symbols/ADSP.8953.2.8.4_WW/adsp_proc/qdsp6/qshrink/src/
elif [ x$PRODUUCT_NAME == x"A306" ];then
mkdir -p amss_symbols/TZ.BF.4.0.5_A306/trustzone_images/core/bsp/qsee/build/ZALAANAA
cp $rootDir/$AMSS_Path/TZ.BF.4.0.5_A306/trustzone_images/core/bsp/qsee/build/ZALAANAA/qsee.elf amss_symbols/TZ.BF.4.0.5_A306/trustzone_images/core/bsp/qsee/build/ZALAANAA

mkdir -p amss_symbols/ADSP.8953.2.8.4_A306/adsp_proc/build/ms
mkdir -p amss_symbols/ADSP.8953.2.8.4_A306/adsp_proc/qdsp6/qshrink/src
cp $rootDir/$AMSS_Path/ADSP.8953.2.8.4_A306/adsp_proc/build/ms/*.elf amss_symbols/ADSP.8953.2.8.4_A306/adsp_proc/build/ms/
cp $rootDir/$AMSS_Path/ADSP.8953.2.8.4_A306/adsp_proc/qdsp6/qshrink/src/msg_hash.txt amss_symbols/ADSP.8953.2.8.4_A306/adsp_proc/qdsp6/qshrink/src/
else
mkdir -p amss_symbols/TZ.BF.4.0.5/trustzone_images/core/bsp/qsee/build/ZALAANAA
cp $rootDir/$AMSS_Path/TZ.BF.4.0.5/trustzone_images/core/bsp/qsee/build/ZALAANAA/qsee.elf amss_symbols/TZ.BF.4.0.5/trustzone_images/core/bsp/qsee/build/ZALAANAA

mkdir -p amss_symbols/ADSP.8953.2.8.4/adsp_proc/build/ms
mkdir -p amss_symbols/ADSP.8953.2.8.4/adsp_proc/qdsp6/qshrink/src
cp $rootDir/$AMSS_Path/ADSP.8953.2.8.4/adsp_proc/build/ms/*.elf amss_symbols/ADSP.8953.2.8.4/adsp_proc/build/ms/
cp $rootDir/$AMSS_Path/ADSP.8953.2.8.4/adsp_proc/qdsp6/qshrink/src/msg_hash.txt amss_symbols/ADSP.8953.2.8.4/adsp_proc/qdsp6/qshrink/src/
fi

echo "start zip all_symbols.zip"
cd $OUT_Path

if [ x"$need_backup_amss_images" == x"yes" ]; then
    if [ -d "all_symbols_8917" ];then
    rm -rf all_symbols_8917
    rm -rf all_symbols_8917.zip
    fi
    mv all_symbols all_symbols_8917
    rm all_symbols_8917/vmlinux
    #zip -r all_symbols_8917.zip all_symbols_8917
elif [ x"$overall_images" == x"yes" ];then
    if [ -d "overall_symbols" ];then
    rm -rf overall_symbols/
    rm -rf overall_symbols.zip
    fi
    mv all_symbols overall_symbols
    cp -a symbols/ overall_symbols/ap_symbols
    cp -a all_symbols_8917/amss_symbols overall_symbols/amss_symbols_8917
    mv overall_symbols/amss_symbols overall_symbols/amss_symbols_8937
    zip -r overall_symbols.zip overall_symbols/
else
    cp -a symbols/ all_symbols/ap_symbols
    zip -r all_symbols.zip all_symbols
fi

if [ x"$need_backup_amss_images" != x"yes" ]; then
if [ x"$overall_images" == x"yes" ]; then
#    filesize=`ls -lk all_symbols_8917.zip | awk '{print $5}'`
#    echo_greeen "all_symbols_8917.zip ---- $filesize Bytes"
    filesize=`ls -lk overall_symbols.zip | awk '{print $5}'`
    echo_greeen "overall_symbols.zip ---- $filesize Bytes"
#    md5=`md5sum -b all_symbols_8917.zip`
#    if [ -f "$OUT_Path/checklist.md5" ]; then
#        line=`grep -n "all_symbols_8917.zip" $OUT_Path/checklist.md5 | cut -d ":" -f 1`
#    fi
#    if [ x"$line" != x"" ]; then
#        sed -i $line's/.*/'"$md5"'/' $OUT_Path/checklist.md5
#    else
#        echo "$md5" >> $OUT_Path/checklist.md5
#    fi
    md5=`md5sum -b overall_symbols.zip`
    if [ -f "$OUT_Path/checklist.md5" ]; then
        line=`grep -n "overall_symbols.zip" $OUT_Path/checklist.md5 | cut -d ":" -f 1`
    fi
    if [ x"$line" != x"" ]; then
        sed -i $line's/.*/'"$md5"'/' $OUT_Path/checklist.md5
    else
        echo "$md5" >> $OUT_Path/checklist.md5
    fi
#    cp all_symbols_8917.zip /data/mine/test/MT6572/$user/
    cp overall_symbols.zip /data/mine/test/MT6572/$user/
else
    filesize=`ls -lk all_symbols.zip | awk '{print $5}'`
    echo_greeen "all_symbols.zip ---- $filesize Bytes"
    md5=`md5sum -b all_symbols.zip`
    if [ -f "$OUT_Path/checklist.md5" ]; then
        line=`grep -n "all_symbols.zip" $OUT_Path/checklist.md5 | cut -d ":" -f 1`
    fi
    if [ x"$line" != x"" ]; then
        sed -i $line's/.*/'"$md5"'/' $OUT_Path/checklist.md5
    else
        echo "$md5" >> $OUT_Path/checklist.md5
    fi
    cp all_symbols.zip /data/mine/test/MT6572/$user/
fi
fi
cd $rootDir
}

command_array=($1 $2 $3 $4 $5)

for command in ${command_array[*]}; do
	case $command in
	8917 | E300L_WW | E300L_IN | E300L_PH )
        PRODUUCT_NAME=E300L_WW
	continue
	;;
	8937 | E300L_CN)
        PRODUUCT_NAME=E300L_CN
	continue
	;;
    A306 | A307)
        PRODUUCT_NAME=A306
    continue
    ;;
	esac

	if [ x$command == x"xtt" ] ;then
        xtt_download="yes"
	elif [ x$command = x"symbols" ];then
        sysbols_flag=1
	elif [ x$command = x"user" ];then
        VARIANT=user
	fi
done

release_param=$2

if [ x"$2" == x"symbols" ];then
    sysbols_flag=1
    release_param=all
elif [ x"$2" == x"user" ];then
    VARIANT=user
    release_param=all
elif [ x"$2" == x"xtt" ];then
    xtt_download="yes"
    release_param=xtt
fi

if [ x"$release_param" = x"" ];then
   release_param=all
fi

if [ x$PRODUUCT_NAME == x"E300L_WW" ] || [ x$PRODUUCT_NAME == x"A306" ] || [ x$PRODUUCT_NAME == x"8917" ];then
    if [ x"$1" == x"E300L_IN" ] || [ x"$1" == x"E300L_PH" ] || [ x"$1" == x"A307" ] ;then
        CHIPID_DIR=MSM8937.LA.3.0.1
    else
        CHIPID_DIR=MSM8917.LA.3.0.1
    fi
else
CHIPID_DIR=MSM8937.LA.3.0.1
fi

if [ x"$release_param" == x"overall" ];then
OUT_Path=$rootDir/out/target/product/E300L_WW
else
OUT_Path=$rootDir/out/target/product/$PRODUUCT_NAME
fi

file_msm8917_amss_images=(
	$AMSS_Path/BOOT.BF.3.3/boot_images/build/ms/bin/LAASANAZ/sbl1.mbn
	$AMSS_Path/BOOT.BF.3.3/boot_images/build/ms/bin/LAADANAZ/prog_emmc_firehose_8917_ddr.mbn
	$AMSS_Path/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/tz.mbn
	$AMSS_Path/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/devcfg.mbn
	$AMSS_Path/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/keymaster64.mbn
	$AMSS_Path/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/cmnlib_30.mbn
	$AMSS_Path/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/cmnlib64_30.mbn
	$AMSS_Path/RPM.BF.2.2/rpm_proc/build/ms/bin/8917/rpm.mbn
	$AMSS_Path/MSM8917.LA.3.0.1/common/build/bin/asic/NON-HLOS.bin
	$AMSS_Path/MSM8917.LA.3.0.1/common/build/gpt_main0.bin
	$AMSS_Path/MSM8917.LA.3.0.1/common/sectools/resources/build/fileversion2/sec.dat
	$AMSS_Path/MSM8917.LA.3.0.1/common/build/gpt_backup0.bin
	$AMSS_Path/MSM8917.LA.3.0.1/common/build/patch0.xml
	$AMSS_Path/ADSP.8953.2.8.4_WW/adsp_proc/build/dynamic_signed/8937/adspso.bin
	$AMSS_Path/ADSP.8953.2.8.4_WW/adsp_proc/build/ms/bin/AAAAAAAA/dsp2.mbn
)

file_msm8917_a306_amss_images=(
	$AMSS_Path/BOOT.BF.3.3/boot_images/build/ms/bin/LAASANAZ/sbl1.mbn
	$AMSS_Path/BOOT.BF.3.3/boot_images/build/ms/bin/LAADANAZ/prog_emmc_firehose_8917_ddr.mbn
	$AMSS_Path/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/tz.mbn
	$AMSS_Path/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/devcfg.mbn
	$AMSS_Path/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/keymaster64.mbn
	$AMSS_Path/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/cmnlib_30.mbn
	$AMSS_Path/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/cmnlib64_30.mbn
	$AMSS_Path/RPM.BF.2.2/rpm_proc/build/ms/bin/8917/rpm.mbn
	$AMSS_Path/MSM8917.LA.3.0.1/common/build/bin/asic/NON-HLOS.bin
	$AMSS_Path/MSM8917.LA.3.0.1/common/build/gpt_main0.bin
	$AMSS_Path/MSM8917.LA.3.0.1/common/sectools/resources/build/fileversion2/sec.dat
	$AMSS_Path/MSM8917.LA.3.0.1/common/build/gpt_backup0.bin
	$AMSS_Path/MSM8917.LA.3.0.1/common/build/patch0.xml
	$AMSS_Path/ADSP.8953.2.8.4_A306/adsp_proc/build/dynamic_signed/8937/adspso.bin
	$AMSS_Path/ADSP.8953.2.8.4_A306/adsp_proc/build/ms/bin/AAAAAAAA/dsp2.mbn
)

file_msm8937_a307_amss_images=(
	$AMSS_Path/BOOT.BF.3.3/boot_images/build/ms/bin/FAASANAZ/sbl1.mbn
	$AMSS_Path/BOOT.BF.3.3/boot_images/build/ms/bin/FAADANAZ/prog_emmc_firehose_8937_ddr.mbn
	$AMSS_Path/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/tz.mbn
	$AMSS_Path/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/devcfg.mbn
	$AMSS_Path/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/keymaster64.mbn
	$AMSS_Path/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/cmnlib_30.mbn
	$AMSS_Path/TZ.BF.4.0.5_A306/trustzone_images/build/ms/bin/ZALAANAA/cmnlib64_30.mbn
	$AMSS_Path/RPM.BF.2.2/rpm_proc/build/ms/bin/8937/rpm.mbn
	$AMSS_Path/MSM8937.LA.3.0.1/common/build/bin/asic/NON-HLOS.bin
	$AMSS_Path/MSM8937.LA.3.0.1/common/build/gpt_main0.bin
	$AMSS_Path/MSM8937.LA.3.0.1/common/sectools/resources/build/fileversion2/sec.dat
	$AMSS_Path/MSM8937.LA.3.0.1/common/build/gpt_backup0.bin
	$AMSS_Path/MSM8937.LA.3.0.1/common/build/patch0.xml
	$AMSS_Path/ADSP.8953.2.8.4_A306/adsp_proc/build/dynamic_signed/8937/adspso.bin
	$AMSS_Path/ADSP.8953.2.8.4_A306/adsp_proc/build/ms/bin/AAAAAAAA/dsp2.mbn
)
file_msm8937_amss_images=(
	$AMSS_Path/BOOT.BF.3.3/boot_images/build/ms/bin/FAASANAZ/sbl1.mbn
	$AMSS_Path/BOOT.BF.3.3/boot_images/build/ms/bin/FAADANAZ/prog_emmc_firehose_8937_ddr.mbn
	$AMSS_Path/TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/tz.mbn
	$AMSS_Path/TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/devcfg.mbn
	$AMSS_Path/TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/keymaster64.mbn
	$AMSS_Path/TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/cmnlib_30.mbn
	$AMSS_Path/TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/cmnlib64_30.mbn
	$AMSS_Path/RPM.BF.2.2/rpm_proc/build/ms/bin/8937/rpm.mbn
	$AMSS_Path/MSM8937.LA.3.0.1/common/build/bin/asic/NON-HLOS.bin
	$AMSS_Path/MSM8937.LA.3.0.1/common/build/gpt_main0.bin
	$AMSS_Path/MSM8937.LA.3.0.1/common/sectools/resources/build/fileversion2/sec.dat
	$AMSS_Path/MSM8937.LA.3.0.1/common/build/gpt_backup0.bin
	$AMSS_Path/MSM8937.LA.3.0.1/common/build/patch0.xml
	$AMSS_Path/ADSP.8953.2.8.4/adsp_proc/build/dynamic_signed/8937/adspso.bin
	$AMSS_Path/ADSP.8953.2.8.4/adsp_proc/build/ms/bin/AAAAAAAA/dsp2.mbn
)

file_msm8937_amss_in_images=(
	$AMSS_Path/BOOT.BF.3.3/boot_images/build/ms/bin/FAASANAZ/sbl1.mbn
	$AMSS_Path/BOOT.BF.3.3/boot_images/build/ms/bin/FAADANAZ/prog_emmc_firehose_8937_ddr.mbn
	$AMSS_Path/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/tz.mbn
	$AMSS_Path/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/devcfg.mbn
	$AMSS_Path/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/keymaster64.mbn
	$AMSS_Path/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/cmnlib_30.mbn
	$AMSS_Path/TZ.BF.4.0.5_WW/trustzone_images/build/ms/bin/ZALAANAA/cmnlib64_30.mbn
	$AMSS_Path/RPM.BF.2.2/rpm_proc/build/ms/bin/8937/rpm.mbn
	$AMSS_Path/MSM8937.LA.3.0.1/common/build/bin/asic/NON-HLOS.bin
	$AMSS_Path/MSM8937.LA.3.0.1/common/build/gpt_main0.bin
	$AMSS_Path/MSM8937.LA.3.0.1/common/sectools/resources/build/fileversion2/sec.dat
	$AMSS_Path/MSM8937.LA.3.0.1/common/build/gpt_backup0.bin
	$AMSS_Path/MSM8937.LA.3.0.1/common/build/patch0.xml
	$AMSS_Path/ADSP.8953.2.8.4_WW/adsp_proc/build/dynamic_signed/8937/adspso.bin
	$AMSS_Path/ADSP.8953.2.8.4_WW/adsp_proc/build/ms/bin/AAAAAAAA/dsp2.mbn
)

file_msm8917_amss_qf_xml=(
	$AMSS_Path/MSM8917.LA.3.0.1/common/build/rawprogram0.xml
)

file_msm8937_amss_qf_xml=(
	$AMSS_Path/MSM8937.LA.3.0.1/common/build/rawprogram0.xml
)

file_qf_ap_images=(
	$OUT_Path/emmc_appsboot.mbn
	$OUT_Path/boot.img
	$OUT_Path/logo.bin
	$OUT_Path/splash.img
	$OUT_Path/system.img
	$OUT_Path/userdata.img
	$OUT_Path/recovery.img
	$OUT_Path/vendor.img
	$OUT_Path/cache.img
	$OUT_Path/mdtp.img
	$OUT_Path/persist.img
)

file_xtt_ap_images=(
	$OUT_Path/emmc_appsboot.mbn
	$OUT_Path/boot.img
	$OUT_Path/userdata.img
	$OUT_Path/cache.img
	$OUT_Path/recovery.img
	$OUT_Path/mdtp.img
)

if [ x"$release_param" == x"overall" ];then
source_amss_images=(${file_msm8937_amss_in_images[@]})
else
if [ x$PRODUUCT_NAME == x"E300L_WW" ] || [ x$PRODUUCT_NAME == x"8917" ];then
if [ x"$1" == x"E300L_IN" ] || [ x"$1" == x"E300L_PH" ];then
source_amss_images=(${file_msm8937_amss_in_images[@]})
else
source_amss_images=(${file_msm8917_amss_images[@]})
fi
elif [ x$PRODUUCT_NAME == x"A306" ];then
    if [ x$1 == x"A307" ];then
        source_amss_images=(${file_msm8937_a307_amss_images[@]})
    else
        source_amss_images=(${file_msm8917_a306_amss_images[@]})
    fi
else
source_amss_images=(${file_msm8937_amss_images[@]})
fi
fi

if [ x"$release_param" != x"xtt" ] && [ x"$release_param" != x"overall" ] && [ x"$release_param" != x"amssbackup" ];then
if [ x$PRODUUCT_NAME == x"E300L_WW" ] || [ x$PRODUUCT_NAME == x"8917" ];then
if [ x"$1" == x"E300L_IN" ] || [ x"$1" == x"E300L_PH" ];then
source_amss_images=(${source_amss_images[@]} ${file_msm8937_amss_qf_xml[@]})
else
source_amss_images=(${source_amss_images[@]} ${file_msm8917_amss_qf_xml[@]})
fi
elif [ x$PRODUUCT_NAME == x"A306" ];then
    if [ x$1 == x"A307" ];then
        source_amss_images=(${source_amss_images[@]} ${file_msm8937_amss_qf_xml[@]})
    else
        source_amss_images=(${source_amss_images[@]} ${file_msm8917_amss_qf_xml[@]})
    fi
else
source_amss_images=(${source_amss_images[@]} ${file_msm8937_amss_qf_xml[@]})
fi
fi

sysbols_zip=$OUT_Path/all_symbols
AMSS_images=$OUT_Path/amss_images
Overall_all_images=$OUT_Path/overall_all_images
AMSS8917_backup_images=$OUT_Path/amss_images_8917
AMSS8937_backup_images=$OUT_Path/amss_images_8937

if [ -f boot_su.img ];then
    boot_su_flag=1
    cp boot_su.img $OUT_Path/
fi

ALL_AMSS_RELEASE_FILES="sbl1.mbn tz.mbn devcfg.mbn keymaster64.mbn cmnlib_30.mbn cmnlib64_30.mbn rpm.mbn NON-HLOS.bin gpt_main0.bin sec.dat gpt_backup0.bin patch0.xml adspso.bin dsp2.mbn"
AMSS_OVERALL_RELEASE_FILES="sbl1.mbn tz.mbn devcfg.mbn keymaster64.mbn cmnlib_30.mbn cmnlib64_30.mbn rpm.mbn NON-HLOS.bin gpt_main0.bin sec.dat gpt_backup0.bin patch0.xml adspso.bin dsp2.mbn"
ALL_AMSS_OVERALL_RELEASE_FILES="sbl1.mbn tz.mbn devcfg.mbn keymaster64.mbn cmnlib_30.mbn cmnlib64_30.mbn rpm.mbn NON-HLOS.bin gpt_main0.bin sec.dat gpt_backup0.bin patch0.xml adspso.bin dsp2.mbn"
ALL_QF_AP_RELEASE_FILES_EXCEPT_SYSTEM="emmc_appsboot.mbn boot.img logo.bin splash.img userdata.img recovery.img vendor.img cache.img mdtp.img persist.img"
ALL_XTT_AP_RELEASE_FILES_EXCEPT_SYSTEM="emmc_appsboot.mbn boot.img logo.bin splash.img cache.img userdata.img recovery.img mdtp.img"


if [ x$PRODUUCT_NAME == x"E300L_WW" ] || [ x$PRODUUCT_NAME == x"8917" ];then
if [ x"$1" == x"E300L_IN" ] || [ x"$1" == x"E300L_PH" ];then
ALL_AMSS_RELEASE_FILES=${ALL_AMSS_RELEASE_FILES}" prog_emmc_firehose_8937_ddr.mbn"
else
ALL_AMSS_RELEASE_FILES=${ALL_AMSS_RELEASE_FILES}" prog_emmc_firehose_8917_ddr.mbn"
fi
elif [ x$PRODUUCT_NAME == x"A306" ];then
    if [ x$1 == x"A307" ];then
        ALL_AMSS_RELEASE_FILES=${ALL_AMSS_RELEASE_FILES}" prog_emmc_firehose_8937_ddr.mbn"
    else
        ALL_AMSS_RELEASE_FILES=${ALL_AMSS_RELEASE_FILES}" prog_emmc_firehose_8917_ddr.mbn"
    fi
else
ALL_AMSS_RELEASE_FILES=${ALL_AMSS_RELEASE_FILES}" prog_emmc_firehose_8937_ddr.mbn"
fi

if [ x"$release_param" != x"xtt" ];then
if [ x$PRODUUCT_NAME == x"A306" ];then
	ALL_AMSS_RELEASE_FILES=${ALL_AMSS_RELEASE_FILES}" rawprogram0.xml rawprogram0_upgrade.xml"
else
	if [ x"$VARIANT" == x"user" ];then
		ALL_AMSS_RELEASE_FILES=${ALL_AMSS_RELEASE_FILES}" rawprogram0.xml"
	else
		ALL_AMSS_RELEASE_FILES=${ALL_AMSS_RELEASE_FILES}" rawprogram0.xml rawprogram0_rework.xml"
	fi
fi
fi

if [ x"$release_param" == x"overall" ];then
ALL_AMSS_RELEASE_FILES="8917_sbl1.mbn 8917_tz.mbn 8917_devcfg.mbn 8917_keymaster64.mbn 8917_cmnlib_30.mbn 8917_cmnlib64_30.mbn 8917_rpm.mbn 8917_NON-HLOS.bin 8917_gpt_main0.bin 8917_sec.dat 8917_gpt_backup0.bin patch0_8917.xml 8917_adspso.bin 8917_dsp2.mbn prog_emmc_firehose_8917_ddr.mbn 8937_sbl1.mbn 8937_tz.mbn 8937_devcfg.mbn 8937_keymaster64.mbn 8937_cmnlib_30.mbn 8937_cmnlib64_30.mbn 8937_rpm.mbn 8937_NON-HLOS.bin 8937_gpt_main0.bin 8937_sec.dat 8937_gpt_backup0.bin patch0_8937.xml 8937_adspso.bin 8937_dsp2.mbn prog_emmc_firehose_8937_ddr.mbn"
fi

if [ -f $OUT_Path/APD.img ]; then
    ALL_QF_AP_RELEASE_FILES_EXCEPT_SYSTEM=${ALL_QF_AP_RELEASE_FILES_EXCEPT_SYSTEM}" APD.img"
    ALL_XTT_AP_RELEASE_FILES_EXCEPT_SYSTEM=${ALL_XTT_AP_RELEASE_FILES_EXCEPT_SYSTEM}" APD.img"
fi

if [ -f $OUT_Path/xrom.img ]; then
    ALL_QF_AP_RELEASE_FILES_EXCEPT_SYSTEM=${ALL_QF_AP_RELEASE_FILES_EXCEPT_SYSTEM}" xrom.img"
    ALL_XTT_AP_RELEASE_FILES_EXCEPT_SYSTEM=${ALL_XTT_AP_RELEASE_FILES_EXCEPT_SYSTEM}" xrom.img"
fi

if [ -f $OUT_Path/asusfw.img ]; then
    ALL_QF_AP_RELEASE_FILES_EXCEPT_SYSTEM=${ALL_QF_AP_RELEASE_FILES_EXCEPT_SYSTEM}" asusfw.img"
    ALL_XTT_AP_RELEASE_FILES_EXCEPT_SYSTEM=${ALL_XTT_AP_RELEASE_FILES_EXCEPT_SYSTEM}" asusfw.img"
fi

if [ x"$boot_su_flag" == x"1" ];then
    ALL_QF_AP_RELEASE_FILES_EXCEPT_SYSTEM=${ALL_QF_AP_RELEASE_FILES_EXCEPT_SYSTEM}" boot_su.img"
    ALL_XTT_AP_RELEASE_FILES_EXCEPT_SYSTEM=${ALL_XTT_AP_RELEASE_FILES_EXCEPT_SYSTEM}" boot_su.img"
fi

if [ x"$release_param" == x"overall" ];then
    cp $rootDir/vendor/wind/qcn_partition_img/fs_image.tar.gz.mbn.E300L.8917.full.band.img $OUT_Path/fs_image.tar.gz.mbn.8917.img
    cp $rootDir/vendor/wind/qcn_partition_img/fs_image.tar.gz.mbn.E300L.8937.full.band.img $OUT_Path/fs_image.tar.gz.mbn.8937.img
    cp $rootDir/vendor/wind/debugpolicy_mbn/8917/dp_AP_signed.mbn $OUT_Path/8917_dp_AP_signed.mbn
    cp $rootDir/vendor/wind/debugpolicy_mbn/8917/dp_MSA_signed.mbn $OUT_Path/8917_dp_MSA_signed.mbn
    cp $rootDir/vendor/wind/debugpolicy_mbn/8937/dp_AP_signed.mbn $OUT_Path/8937_dp_AP_signed.mbn
    cp $rootDir/vendor/wind/debugpolicy_mbn/8937/dp_MSA_signed.mbn $OUT_Path/8937_dp_MSA_signed.mbn
    ALL_QF_AP_RELEASE_FILES_EXCEPT_SYSTEM=${ALL_QF_AP_RELEASE_FILES_EXCEPT_SYSTEM}" fs_image.tar.gz.mbn.8917.img fs_image.tar.gz.mbn.8937.img 8917_dp_AP_signed.mbn 8917_dp_MSA_signed.mbn 8937_dp_AP_signed.mbn 8937_dp_MSA_signed.mbn"
    ALL_XTT_AP_RELEASE_FILES_EXCEPT_SYSTEM=${ALL_XTT_AP_RELEASE_FILES_EXCEPT_SYSTEM}" fs_image.tar.gz.mbn.8917.img fs_image.tar.gz.mbn.8937.img 8917_dp_AP_signed.mbn 8917_dp_MSA_signed.mbn 8937_dp_AP_signed.mbn 8937_dp_MSA_signed.mbn"
else
    if [ x$PRODUUCT_NAME == x"E300L_WW" ] || [ x$PRODUUCT_NAME == x"8917" ];then
        if [ x"$1" == x"E300L_IN" ] || [ x"$1" == x"E300L_PH" ];then
            cp $rootDir/vendor/wind/qcn_partition_img/fs_image.tar.gz.mbn.E300L.8937.full.band.img $OUT_Path/fs_image.tar.gz.mbn.8937.img
            cp $rootDir/vendor/wind/debugpolicy_mbn/8937/dp_AP_signed.mbn $OUT_Path/dp_AP_signed.mbn
            cp $rootDir/vendor/wind/debugpolicy_mbn/8937/dp_MSA_signed.mbn $OUT_Path/dp_MSA_signed.mbn
            ALL_QF_AP_RELEASE_FILES_EXCEPT_SYSTEM=${ALL_QF_AP_RELEASE_FILES_EXCEPT_SYSTEM}" fs_image.tar.gz.mbn.8937.img dp_AP_signed.mbn dp_MSA_signed.mbn"
            ALL_XTT_AP_RELEASE_FILES_EXCEPT_SYSTEM=${ALL_XTT_AP_RELEASE_FILES_EXCEPT_SYSTEM}" fs_image.tar.gz.mbn.8937.img dp_AP_signed.mbn dp_MSA_signed.mbn"
        else
            cp $rootDir/vendor/wind/qcn_partition_img/fs_image.tar.gz.mbn.E300L.8917.full.band.img $OUT_Path/fs_image.tar.gz.mbn.8917.img
            cp $rootDir/vendor/wind/debugpolicy_mbn/8917/dp_AP_signed.mbn $OUT_Path/dp_AP_signed.mbn
            cp $rootDir/vendor/wind/debugpolicy_mbn/8917/dp_MSA_signed.mbn $OUT_Path/dp_MSA_signed.mbn
            ALL_QF_AP_RELEASE_FILES_EXCEPT_SYSTEM=${ALL_QF_AP_RELEASE_FILES_EXCEPT_SYSTEM}" fs_image.tar.gz.mbn.8917.img dp_AP_signed.mbn dp_MSA_signed.mbn"
            ALL_XTT_AP_RELEASE_FILES_EXCEPT_SYSTEM=${ALL_XTT_AP_RELEASE_FILES_EXCEPT_SYSTEM}" fs_image.tar.gz.mbn.8917.img dp_AP_signed.mbn dp_MSA_signed.mbn"
        fi
    elif [ x$PRODUUCT_NAME == x"A306" ];then
	if [ x$1 == x"A307" ];then
		cp $rootDir/vendor/wind/qcn_partition_img/A307/fs_image.tar.gz.mbn.img $OUT_Path/fs_image.tar.gz.mbn.8937.img
		cp $rootDir/vendor/wind/debugpolicy_mbn/8937/dp_AP_signed.mbn $OUT_Path/dp_AP_signed.mbn
		cp $rootDir/vendor/wind/debugpolicy_mbn/8937/dp_MSA_signed.mbn $OUT_Path/dp_MSA_signed.mbn
		ALL_QF_AP_RELEASE_FILES_EXCEPT_SYSTEM=${ALL_QF_AP_RELEASE_FILES_EXCEPT_SYSTEM}" fs_image.tar.gz.mbn.8937.img dp_AP_signed.mbn dp_MSA_signed.mbn"
		ALL_XTT_AP_RELEASE_FILES_EXCEPT_SYSTEM=${ALL_XTT_AP_RELEASE_FILES_EXCEPT_SYSTEM}" fs_image.tar.gz.mbn.8937.img dp_AP_signed.mbn dp_MSA_signed.mbn"
	else
		cp $rootDir/vendor/wind/qcn_partition_img/fs_image.tar.gz.mbn.A306.8917.full.band.img $OUT_Path/fs_image.tar.gz.mbn.8917.img
		cp $rootDir/vendor/wind/debugpolicy_mbn/8917/dp_AP_signed.mbn $OUT_Path/dp_AP_signed.mbn
		cp $rootDir/vendor/wind/debugpolicy_mbn/8917/dp_MSA_signed.mbn $OUT_Path/dp_MSA_signed.mbn
		ALL_QF_AP_RELEASE_FILES_EXCEPT_SYSTEM=${ALL_QF_AP_RELEASE_FILES_EXCEPT_SYSTEM}" fs_image.tar.gz.mbn.8917.img dp_AP_signed.mbn dp_MSA_signed.mbn"
            ALL_XTT_AP_RELEASE_FILES_EXCEPT_SYSTEM=${ALL_XTT_AP_RELEASE_FILES_EXCEPT_SYSTEM}" fs_image.tar.gz.mbn.8917.img dp_AP_signed.mbn dp_MSA_signed.mbn"
        fi

    else
        cp $rootDir/vendor/wind/qcn_partition_img/fs_image.tar.gz.mbn.E301L.cn.band.img $OUT_Path/fs_image.tar.gz.mbn.8937.img
        cp $rootDir/vendor/wind/debugpolicy_mbn/8937/dp_AP_signed.mbn $OUT_Path/8937_dp_AP_signed.mbn
        cp $rootDir/vendor/wind/debugpolicy_mbn/8937/dp_MSA_signed.mbn $OUT_Path/8937_dp_MSA_signed.mbn
        ALL_QF_AP_RELEASE_FILES_EXCEPT_SYSTEM=${ALL_QF_AP_RELEASE_FILES_EXCEPT_SYSTEM}" fs_image.tar.gz.mbn.8937.img dp_AP_signed.mbn dp_MSA_signed.mbn"
        ALL_XTT_AP_RELEASE_FILES_EXCEPT_SYSTEM=${ALL_XTT_AP_RELEASE_FILES_EXCEPT_SYSTEM}" fs_image.tar.gz.mbn.8937.img dp_AP_signed.mbn dp_MSA_signed.mbn"
    fi
fi

ALL_QF_AP_RELEASE_FILES=${ALL_QF_AP_RELEASE_FILES_EXCEPT_SYSTEM}" system.img"

need_release_amss_images=""
need_backup_amss_images=""
overall_images=""

RELEASE_FILES=""
case $release_param in
    overall)
        if [ x"$xtt_download" == x"yes" ];then
        RELEASE_FILES=$ALL_XTT_AP_RELEASE_FILES_EXCEPT_SYSTEM
        else
        RELEASE_FILES=$ALL_QF_AP_RELEASE_FILES
        fi
        need_release_amss_images="yes"
        overall_images="yes"
        ;;
    all)
        RELEASE_FILES=$ALL_QF_AP_RELEASE_FILES
        need_release_amss_images="yes"
        ;;
    xtt)
        RELEASE_FILES=$ALL_XTT_AP_RELEASE_FILES_EXCEPT_SYSTEM
        need_release_amss_images="yes"
        ;;
    ap)
        RELEASE_FILES=$ALL_QF_AP_RELEASE_FILES
        ;;
    system-)
        RELEASE_FILES=$ALL_QF_AP_RELEASE_FILES_EXCEPT_SYSTEM
        ;;        
    system)
        RELEASE_FILES="system.img"
        ;;
    amss)
        need_release_amss_images="yes"
        ;;
    amssbackup)
        need_backup_amss_images="yes"
        ;;
    boot)
        RELEASE_FILES="boot.img"
        ;;
    aboot)
        RELEASE_FILES="emmc_appsboot.mbn"
        ;;	
    recovery)
        RELEASE_FILES="recovery.img"
        ;;
    vendor)
        RELEASE_FILES="vendor.img"
        ;;
    userdata)
        RELEASE_FILES="userdata.img"
        ;;
    ota)
        build_type=$(grep 'ro.build.type' out/target/product/A306/system/build.prop | head -1 | awk -F '=' '{print $2}')
        cd $OUT_Path
        ota_files=`ls -dt ${PRODUUCT_NAME}-ota-*.zip | head -n 1`
        cp "$ota_files" UL-ASUS_X00R-WW-"$UL_NO"-"$build_type".zip
        ota_files=UL-ASUS_X00R-WW-"$UL_NO"-"$build_type".zip

        if [ -d $OUT_Path/obj/PACKAGING/target_files_intermediates ]; then
            cd $OUT_Path/obj/PACKAGING/target_files_intermediates
            target_files=`ls -dt ${PRODUUCT_NAME}-target_files-*.zip | head -n 1`
        fi

        if [ -f $OUT_Path/target_files-package.zip ]; then
            cd $OUT_Path
            adups_target=`ls -dt target_files-package*.zip | head -n 1`
        fi

        if [ -f $OUT_Path/obj/KERNEL_OBJ/vmlinux ]; then
        {
            cd $OUT_Path/obj/KERNEL_OBJ
            if [ -f ./vmlinux.zip ]; then
            rm -rf vmlinux.zip
            fi
            zip -rq vmlinux.zip vmlinux
            mv $OUT_Path/obj/KERNEL_OBJ/vmlinux.zip $OUT_Path
            vmlinux_files=vmlinux.zip
        }
        fi
        cd $rootDir
        if [ -f $OUT_Path/symbols.zip ];then
            RELEASE_FILES="$target_files $ota_files $adups_target $vmlinux_files symbols.zip"
        else
            RELEASE_FILES="$target_files $ota_files $adups_target $vmlinux_files "
        fi
        ;;
    asusfw_ota)
        cd $OUT_Path
        ota_files=`ls -dt ${PRODUUCT_NAME}-ota-asusfw*.zip | head -n 1`
        cd $rootDir
        RELEASE_FILES="$ota_files"
        ;;
    diff)
        if [ -f ./updateA2B.zip ] &&  [ -f ./updateB2C.zip ] ; then
            diff_files="updateA2B.zip updateB2C.zip"
        elif  [ -f ./updateA2B.zip ]; then
            diff_files=updateA2B.zip
        elif  [ -f ./updateB2C.zip ]; then
            diff_files=updateB2C.zip
        fi
        RELEASE_FILES="$diff_files"
        ;;
    none)
        ;;
    *)
        echo "not supported!!"
        exit 1
        ;;
esac

if [ x"$need_backup_amss_images" == x"yes" ]; then
echo_greeen "Start Backup"
if [ -d $AMSS8917_backup_images ];then
	rm -rf $AMSS8917_backup_images
fi
mkdir -p $AMSS8917_backup_images
if [ -d $AMSS8937_backup_images ];then
	rm -rf $AMSS8937_backup_images
fi
mkdir -p $AMSS8937_backup_images

for file in ${source_amss_images[*]}
do
	if [ -f "$file" ];then
		cp $file $AMSS8917_backup_images
	else
		echo -e "\033[40;31m Backup error: can't found $file \033[0m"
		#exit 1
	fi
done
release_symbols
echo_greeen "Backup Sucess"
else
if [ x"$overall_images" = x"yes" ]; then
echo_greeen "start release"
if [ -d $Overall_all_images ];then
	rm -rf $Overall_all_images
fi
mkdir -p $Overall_all_images

for file in ${source_amss_images[*]}
do
	if [ -f "$file" ];then
		cp $file $AMSS8937_backup_images
	else
		echo -e "\033[40;31m release error: can't found $file \033[0m"
		#exit 1
	fi
done

cd $AMSS8917_backup_images
for file in $AMSS_OVERALL_RELEASE_FILES;
do
	if [ -f "$file" ];then
		if [ x"$file" = x"patch0.xml" ]; then
			cp $file $Overall_all_images/patch0_8917.xml
		else
			cp $file $Overall_all_images/8917_$file
		fi
	else
		echo -e "\033[40;31m modify 8917 name error: can't found $file \033[0m"
		#exit 1
	fi
done
cp prog_emmc_firehose_8917_ddr.mbn $Overall_all_images/
cd $AMSS8937_backup_images
for file in $AMSS_OVERALL_RELEASE_FILES;
do
	if [ -f "$file" ];then
		if [ x"$file" = x"patch0.xml" ]; then
			cp $file $Overall_all_images/patch0_8937.xml
		else
			cp $file $Overall_all_images/8937_$file
		fi
	else
		echo -e "\033[40;31m modify 8937 name error: can't found $file \033[0m"
		#exit 1
	fi
done
cp prog_emmc_firehose_8937_ddr.mbn $Overall_all_images/

cd $OUT_Path
if [ x"$target_files" == x"" ] || [ x"$ota_files" == x"" ];then
for file in $RELEASE_FILES; do
	if [ -f "$file" ];then
		cp $file $Overall_all_images/
	else
		echo -e "\033[40;31m Copy android img error: can't found $file \033[0m"
		#exit 1
	fi
done
fi
cd $rootDir
if [ x"$xtt_download" == x"yes" ];then
cp -a $AMSS_Path/MSM8917.LA.3.0.1/common/build/bin/asic/sparse_images/* $Overall_all_images/
cp -a $AMSS_Path/MSM8937.LA.3.0.1/common/build/bin/asic/sparse_images/rawprogram_unsparse.xml $Overall_all_images/rawprogram_unsparse_8937.xml
cd $Overall_all_images
mv rawprogram_unsparse.xml rawprogram_unsparse_8917.xml
if [ -f "rawprogram_unsparse_8917.xml" ];then
for file in $AMSS_OVERALL_RELEASE_FILES;
do
	if [ x"$file" != x"patch0.xml" ];then
        sed -i "s/$file/8917_$file/g" rawprogram_unsparse_8917.xml
        sed -i "s/$file/8937_$file/g" patch0_8917.xml
	fi
done
else
	echo -e "\033[40;31m Can't found rawprogram_unsparse_8917.xml \033[0m"
fi
if [ -f "rawprogram_unsparse_8937.xml" ];then
for file in $AMSS_OVERALL_RELEASE_FILES;
do
	if [ x"$file" != x"patch0.xml" ];then
        sed -i "s/$file/8937_$file/g" rawprogram_unsparse_8937.xml
        sed -i "s/$file/8937_$file/g" patch0_8937.xml
	fi
done
else
	echo -e "\033[40;31m Can't found rawprogram_unsparse_8937.xml \033[0m"
fi
if [ x"$VARIANT" == x"user" ];then
	sed -i "s/persist_1.img//g" rawprogram_unsparse_8917.xml
	sed -i "s/persist_1.img//g" rawprogram_unsparse_8937.xml
	sed -i "s/fs_image.tar.gz.mbn.8917.img//g" rawprogram_unsparse_8917.xml
	sed -i "s/fs_image.tar.gz.mbn.8937.img//g" rawprogram_unsparse_8937.xml
else
	cp rawprogram_unsparse_8917.xml rawprogram_unsparse_rework_8917.xml
	cp rawprogram_unsparse_8937.xml rawprogram_unsparse_rework_8937.xml
	sed -i "s/persist_1.img//g" rawprogram_unsparse_rework_8917.xml
	sed -i "s/persist_1.img//g" rawprogram_unsparse_rework_8937.xml
	sed -i "s/fs_image.tar.gz.mbn.8917.img//g" rawprogram_unsparse_rework_8917.xml
	sed -i "s/fs_image.tar.gz.mbn.8937.img//g" rawprogram_unsparse_rework_8937.xml
fi
else
cp -a $AMSS_Path/MSM8917.LA.3.0.1/common/build/rawprogram0.xml $Overall_all_images/rawprogram0_8917.xml
cp -a $AMSS_Path/MSM8937.LA.3.0.1/common/build/rawprogram0.xml $Overall_all_images/rawprogram0_8937.xml
cd $Overall_all_images
if [ -f "rawprogram0_8917.xml" ];then
for file in $AMSS_OVERALL_RELEASE_FILES;
do
	if [ x"$file" != x"patch0.xml" ];then
        sed -i "s/$file/8917_$file/g" rawprogram0_8917.xml
        sed -i "s/$file/8937_$file/g" patch0_8917.xml
	fi
done
else
	echo -e "\033[40;31m Can't found rawprogram0_8917.xml \033[0m"
fi
if [ -f "rawprogram0_8937.xml" ];then
for file in $AMSS_OVERALL_RELEASE_FILES;
do
	if [ x"$file" != x"patch0.xml" ];then
        sed -i "s/$file/8937_$file/g" rawprogram0_8937.xml
        sed -i "s/$file/8937_$file/g" patch0_8937.xml
	fi
done
else
	echo -e "\033[40;31m Can't found rawprogram0_8937.xml \033[0m"
fi
if [ x"$VARIANT" == x"user" ];then
	sed -i "s/persist.img//g" rawprogram0_8917.xml
	sed -i "s/persist.img//g" rawprogram0_8937.xml
	sed -i "s/fs_image.tar.gz.mbn.8917.img//g" rawprogram0_8917.xml
	sed -i "s/fs_image.tar.gz.mbn.8937.img//g" rawprogram0_8937.xml
else
	cp rawprogram0_8917.xml rawprogram0_rework_8917.xml
	cp rawprogram0_8937.xml rawprogram0_rework_8937.xml
	sed -i "s/persist.img//g" rawprogram0_rework_8917.xml
	sed -i "s/persist.img//g" rawprogram0_rework_8937.xml
	sed -i "s/fs_image.tar.gz.mbn.8917.img//g" rawprogram0_rework_8917.xml
	sed -i "s/fs_image.tar.gz.mbn.8937.img//g" rawprogram0_rework_8937.xml
fi
fi
rm $Overall_all_images/emmc_appsboot.mbn
cp $OUT_Path/8917_emmc_appsboot.mbn $Overall_all_images
cp $OUT_Path/8937_emmc_appsboot.mbn $Overall_all_images
cp $OUT_Path/8917_dp_AP_signed.mbn $Overall_all_images
cp $OUT_Path/8917_dp_MSA_signed.mbn $Overall_all_images
cp $OUT_Path/8937_dp_AP_signed.mbn $Overall_all_images
cp $OUT_Path/8937_dp_MSA_signed.mbn $Overall_all_images
if [ x"$xtt_download" == x"yes" ];then
sed -i "s/emmc_appsboot.mbn/8917_emmc_appsboot.mbn/g" rawprogram_unsparse_8917.xml
sed -i "s/emmc_appsboot.mbn/8937_emmc_appsboot.mbn/g" rawprogram_unsparse_8937.xml
sed -i "s/dp_AP_signed.mbn/8917_dp_AP_signed.mbn/g" rawprogram_unsparse_8917.xml
sed -i "s/dp_MSA_signed.mbn/8917_dp_MSA_signed.mbn/g" rawprogram_unsparse_8917.xml
sed -i "s/dp_AP_signed.mbn/8937_dp_AP_signed.mbn/g" rawprogram_unsparse_8937.xml
sed -i "s/dp_MSA_signed.mbn/8937_dp_MSA_signed.mbn/g" rawprogram_unsparse_8937.xml
sed -i "s/emmc_appsboot.mbn/8917_emmc_appsboot.mbn/g" rawprogram_unsparse_rework_8917.xml
sed -i "s/emmc_appsboot.mbn/8937_emmc_appsboot.mbn/g" rawprogram_unsparse_rework_8937.xml
sed -i "s/dp_AP_signed.mbn/8917_dp_AP_signed.mbn/g" rawprogram_unsparse_rework_8917.xml
sed -i "s/dp_AP_signed.mbn/8937_dp_AP_signed.mbn/g" rawprogram_unsparse_rework_8937.xml
sed -i "s/dp_MSA_signed.mbn/8917_dp_MSA_signed.mbn/g" rawprogram_unsparse_rework_8917.xml
sed -i "s/dp_MSA_signed.mbn/8937_dp_MSA_signed.mbn/g" rawprogram_unsparse_rework_8937.xml
else
sed -i "s/emmc_appsboot.mbn/8917_emmc_appsboot.mbn/g" rawprogram0_8917.xml
sed -i "s/emmc_appsboot.mbn/8937_emmc_appsboot.mbn/g" rawprogram0_8937.xml
sed -i "s/dp_AP_signed.mbn/8917_dp_AP_signed.mbn/g" rawprogram0_8917.xml
sed -i "s/dp_MSA_signed.mbn/8917_dp_MSA_signed.mbn/g" rawprogram0_8917.xml
sed -i "s/dp_AP_signed.mbn/8937_dp_AP_signed.mbn/g" rawprogram0_8937.xml
sed -i "s/dp_MSA_signed.mbn/8937_dp_MSA_signed.mbn/g" rawprogram0_8937.xml
sed -i "s/emmc_appsboot.mbn/8917_emmc_appsboot.mbn/g" rawprogram0_rework_8917.xml
sed -i "s/emmc_appsboot.mbn/8937_emmc_appsboot.mbn/g" rawprogram0_rework_8937.xml
sed -i "s/dp_AP_signed.mbn/8917_dp_AP_signed.mbn/g" rawprogram0_rework_8917.xml
sed -i "s/dp_MSA_signed.mbn/8917_dp_MSA_signed.mbn/g" rawprogram0_rework_8917.xml
sed -i "s/dp_AP_signed.mbn/8937_dp_AP_signed.mbn/g" rawprogram0_rework_8937.xml
sed -i "s/dp_MSA_signed.mbn/8937_dp_MSA_signed.mbn/g" rawprogram0_rework_8937.xml
fi
cd $rootDir
check_md5file
release_symbols
if [ -d $Overall_all_images ];then
    echo "tar Overall_all_images ..."
    cd $OUT_Path
    if [ -f "overall_all_images.tar.gz.apk" ]; then
	rm -rf overall_all_images.tar.gz.apk
    fi
    tar -czf overall_all_images.tar.gz overall_all_images
    zip -r overall_all_images.tar.gz.apk overall_all_images.tar.gz
    rm -rf overall_all_images.tar.gz
    FILES=$FILES" "$OUT_Path"/"overall_all_images.tar.gz.apk
    filesize=`ls -lk overall_all_images.tar.gz.apk | awk '{print $5}'`
    echo_greeen "overall_all_images.tar.gz.apk ---- $filesize Bytes"
    md5=`md5sum -b overall_all_images.tar.gz.apk`
    if [ -f "$OUT_Path/checklist.md5" ]; then
        line=`grep -n "overall_all_images.tar.gz.apk" $OUT_Path/checklist.md5 | cut -d ":" -f 1`
    fi
    if [ x"$line" != x"" ]; then
        sed -i $line's/.*/'"$md5"'/' $OUT_Path/checklist.md5
    else
        echo "$md5" >> $OUT_Path/checklist.md5
    fi
fi
cd $rootDir
if [ x"$target_files" != x"" ] || [ x"$ota_files" != x"" ];then
for file in $RELEASE_FILES; do
    if [ x"$target_files" != x"" ] && [ x"$file" == x"$target_files" ]; then
        FILES=$FILES" "$OUT_Path"/obj/PACKAGING/target_files_intermediates/"$file
        cd $OUT_Path/obj/PACKAGING/target_files_intermediates
    elif [ x"$file" == x"updateA2B.zip" ] || [ x"$file" == x"updateB2C.zip" ] ;then
        FILES=$FILES" "$rootDir"/"$file
        cd $rootDir
    else
        FILES=$FILES" "$OUT_Path"/"$file
        cd $OUT_Path
    fi
    md5=`md5sum -b $file`
    if [ -f "$OUT_Path/checklist.md5" ]; then
        if [ x"$target_files" != x"" ] && [ x"$file" == x"$target_files" ] ;then
            line=`grep -n "\-target_files-" $OUT_Path/checklist.md5 | cut -d ":" -f 1`
        elif [ x"$ota_files" != x"" ] && [ x"$file" == x"$ota_files" ] ;then
            line=`grep -n "\-ota-" $OUT_Path/checklist.md5 | cut -d ":" -f 1`
        else
            line=`grep -n "$file" $OUT_Path/checklist.md5 | cut -d ":" -f 1`
        fi
    fi
    if [ x"$line" != x"" ]; then
        sed -i $line's/.*/'"$md5"'/' $OUT_Path/checklist.md5
    else
        echo "$md5" >> $OUT_Path/checklist.md5
    fi
done
fi
cd $rootDir
else
echo_greeen "start release"
if [ x"$need_release_amss_images" == x"yes" ]; then
if [ -d $AMSS_images ];then
	rm -rf $AMSS_images
fi
mkdir -p $AMSS_images
fi
if [ x"$need_release_amss_images" == x"yes" ]; then
for file in ${source_amss_images[*]}
do
	if [ -f "$file" ];then
		echo_greeen $file
		cp $file $AMSS_images
	else
		echo -e "\033[40;31m release error: can't found $file \033[0m"
		#exit 1
	fi
done
if [ x$PRODUUCT_NAME == x"A306" ];then
	echo_greeen rawprogram0_upgrade.xml
else
	if [ x"$VARIANT" != x"user" ];then
		echo_greeen rawprogram0_rework.xml
	fi
fi

check_md5file
if [ x"$sysbols_flag" == x"1" ];then
release_symbols
fi
cd $AMSS_images
if [ x"$release_param" != x"xtt" ];then
if [ x$PRODUUCT_NAME == x"A306" ];then
	if [ x"$VARIANT" == x"user" ];then
		sed -i "s/persist.img//g" rawprogram0.xml
		sed -i "s/fs_image.tar.gz.mbn.8917.img//g" rawprogram0.xml
		sed -i "s/fs_image.tar.gz.mbn.8937.img//g" rawprogram0.xml
		cp rawprogram0.xml rawprogram0_upgrade.xml
	else
		cp rawprogram0.xml rawprogram0_upgrade.xml
		sed -i "s/persist.img//g" rawprogram0_upgrade.xml
		sed -i "s/fs_image.tar.gz.mbn.8917.img//g" rawprogram0_upgrade.xml
		sed -i "s/fs_image.tar.gz.mbn.8937.img//g" rawprogram0_upgrade.xml
	fi
else
	if [ x"$VARIANT" == x"user" ];then
		sed -i "s/persist.img//g" rawprogram0.xml
	else
		cp rawprogram0.xml rawprogram0_rework.xml
		sed -i "s/persist.img//g" rawprogram0_rework.xml
	fi
fi
fi

for file in $ALL_AMSS_RELEASE_FILES; do
    md5=`md5sum -b $file`
    if [ -f "$OUT_Path/checklist.md5" ]; then
        line=`grep -n "$file" $OUT_Path/checklist.md5 | cut -d ":" -f 1`
    fi
    if [ x"$line" != x"" ]; then
        sed -i $line's/.*/'"$md5"'/' $OUT_Path/checklist.md5
    else
        echo "$md5" >> $OUT_Path/checklist.md5
    fi
done
cd $rootDir
fi

if [ x"$need_release_amss_images" = x"yes" ]; then
cp $AMSS_images/* /data/mine/test/MT6572/$user/
fi
if [ x"$RELEASE_FILES" != x"" ]; then
cd $OUT_Path
for file in $RELEASE_FILES; do
    if [[ "$file" =~ "system" ]] || [ x"$file" == x"symbols.zip" ];then
        filesize=`ls -lk $file | awk '{print $5}'`
        echo_greeen "$file ---- $filesize Bytes"
    elif [[ "$file" =~ "vendor" ]] ;then
        filesize=`ls -lk $file | awk '{print $5}'`
        echo_greeen "$file ---- $filesize Bytes"
    elif [ x"$target_files" != x"" ] && [ x"$file" == x"$target_files" ] ;then
        filesize=`ls -lk obj/PACKAGING/target_files_intermediates/$file | awk '{print $5}'`
        echo_greeen "$file ---- $filesize Bytes"
    elif [ x"$ota_files" != x"" ] && [ x"$file" == x"$ota_files" ] ;then
        filesize=`ls -lk $file | awk '{print $5}'`
        echo_greeen "$file ---- $filesize Bytes"
    elif [ x"$vmlinux_files" != x"" ] && [ x"$file" == x"$vmlinux_files" ] ;then
        filesize=`ls -lk $file | awk '{print $5}'`
        echo_greeen "$file ---- $filesize Bytes"
    else
        echo_greeen "$file"
    fi

    if [ x"$target_files" != x"" ] && [ x"$file" == x"$target_files" ] ;then
        FILES=$FILES" "$OUT_Path"/obj/PACKAGING/target_files_intermediates/"$file
    elif [ x"$file" == x"updateA2B.zip" ] || [ x"$file" == x"updateB2C.zip" ] ;then
        FILES=$FILES" "$rootDir"/"$file
    else
        FILES=$FILES" "$OUT_Path"/"$file
    fi
done
cd $rootDir
for file in $RELEASE_FILES; do
    if [ x"$target_files" != x"" ] && [ x"$file" == x"$target_files" ]; then
        cd $OUT_Path/obj/PACKAGING/target_files_intermediates
    elif [ x"$file" == x"updateA2B.zip" ] || [ x"$file" == x"updateB2C.zip" ] ;then
        cd $rootDir
    else
        cd $OUT_Path
    fi
    md5=`md5sum -b $file`
    if [ -f "$OUT_Path/checklist.md5" ]; then
        if [ x"$target_files" != x"" ] && [ x"$file" == x"$target_files" ] ;then
            line=`grep -n "\-target_files-" $OUT_Path/checklist.md5 | cut -d ":" -f 1`
        elif [ x"$ota_files" != x"" ] && [ x"$file" == x"$ota_files" ] ;then
            line=`grep -n "\-ota-" $OUT_Path/checklist.md5 | cut -d ":" -f 1`
        else
            line=`grep -n "$file" $OUT_Path/checklist.md5 | cut -d ":" -f 1`
        fi
    fi
    if [ x"$line" != x"" ]; then
        sed -i $line's/.*/'"$md5"'/' $OUT_Path/checklist.md5
    else
        echo "$md5" >> $OUT_Path/checklist.md5
    fi
done

cd $OUT_Path
if [ x"$release_param" == x"xtt" ];then
    echo "tar sparse_images ..."
    if [ -d "sparse_images" ];then
	    rm -rf sparse_images
    fi
    mkdir -p sparse_images
    cp -a $rootDir/$AMSS_Path/$CHIPID_DIR/common/build/bin/asic/sparse_images/* sparse_images/
	cd sparse_images
	if [ x$PRODUUCT_NAME == x"A306" ];then
		if [ x"$VARIANT" == x"user" ];then
			sed -i "s/persist_1.img//g" rawprogram_unsparse.xml
			sed -i "s/fs_image.tar.gz.mbn.8917.img//g" rawprogram_unsparse.xml
			sed -i "s/fs_image.tar.gz.mbn.8937.img//g" rawprogram_unsparse.xml
			cp rawprogram_unsparse.xml rawprogram_unsparse_upgrade.xml
		else
			cp rawprogram_unsparse.xml rawprogram_unsparse_upgrade.xml
			sed -i "s/persist_1.img//g" rawprogram_unsparse_upgrade.xml
			sed -i "s/fs_image.tar.gz.mbn.8917.img//g" rawprogram_unsparse_upgrade.xml
			sed -i "s/fs_image.tar.gz.mbn.8937.img//g" rawprogram_unsparse_upgrade.xml
		fi
	else
		if [ x"$VARIANT" == x"user" ];then
			sed -i "s/persist_1.img//g" rawprogram_unsparse.xml
		else
			cp rawprogram_unsparse.xml rawprogram_unsparse_rework.xml
			sed -i "s/persist.img//g" rawprogram_unsparse_rework.xml
		fi
	fi
	cd $OUT_Path
    tar -czf sparse_images.tar.gz sparse_images
    zip -r sparse_images.tar.gz.apk sparse_images.tar.gz
	rm -rf sparse_images.tar.gz
    FILES=$FILES" "$OUT_Path"/"sparse_images.tar.gz.apk
    filesize=`ls -lk sparse_images.tar.gz.apk | awk '{print $5}'`
    echo_greeen "sparse_images.tar.gz.apk ---- $filesize Bytes"
    md5=`md5sum -b sparse_images.tar.gz.apk`
    if [ -f "$OUT_Path/checklist.md5" ]; then
        line=`grep -n "sparse_images.tar.gz.apk" $OUT_Path/checklist.md5 | cut -d ":" -f 1`
    fi
    if [ x"$line" != x"" ]; then
        sed -i $line's/.*/'"$md5"'/' $OUT_Path/checklist.md5
    else
        echo "$md5" >> $OUT_Path/checklist.md5
    fi
    cd $rootDir
fi
fi
fi

if [ -f "$OUT_Path/checklist.md5" ]; then
    FILES=$FILES" "$OUT_Path"/"checklist.md5
fi
cp $FILES /data/mine/test/MT6572/$user/

echo_greeen "Sucess!"
fi
