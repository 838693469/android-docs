# resign images using wingtech key
# zhouliquan@wingtech.com
# 2017-4-20 11:34:45

echo "$PWD"

set -x

WT_MSM_ROOT=MSM8937.LA.3.0
WT_MPSS_ROOT=MPSS.JO.3.0
WT_SECTOOLS_HOME=$WT_MSM_ROOT/common/sectools/
WT_SECIMAGE_XML_PATH=$WT_SECTOOLS_HOME/config/8937/8937_secimage.xml
WT_SECIMAGE_OUTPUT_PATH=$WT_SECTOOLS_HOME/secimage_output/8937/

SIGNED_OUT_FOLDER=signed_out_8937
rm -fr $SIGNED_OUT_FOLDER
mkdir $SIGNED_OUT_FOLDER -p

#####
# mbn path which is needed to generate NON-HLOS.bin.
# need to check every project.
#
FILE_PATH_4_GENERATE_NON_HLOS=(
    TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/cmnlib.mbn
    TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/cmnlib64.mbn
    #TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/mdtp.mbn
    ADSP.8953.2.8.2/adsp_proc/obj/8937/signed/adsp.mbn
    TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/isdbtmm.mbn
    #TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/dhsecapp.mbn
    TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/smplap64.mbn
    TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/fingerprint.mbn
    #CPE.TSF.1.0/cpe_proc/build/ms/bin/AAAAAAAA/cpe_9335.mbn
    #TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/qmpsecap.mbn
    TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/cppf.mbn
    TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/widevine.mbn
    CNSS.PR.4.0/wcnss_proc/build/ms/bin/8937/reloc/wcnss.mbn
    #TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/securemm.mbn
    VIDEO.VE_ULT.3.1/venus_proc/build/bsp/asic/build/PROD/mbn/reloc/signed/venus.mbn
    MPSS.JO.3.0/modem_proc/build/ms/bin/8937.genns.prod/qdsp6sw.mbn
    TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/smplap32.mbn
    #TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/fingerprint64.mbn
    #TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/gptest.mbn
    TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/signed/goodixfp.mbn
	TZ.BF.4.0.5/trustzone_images/build/ms/bin/ZALAANAA/signed/sw_fp.mbn
    MPSS.JO.3.0/modem_proc/build/ms/bin/8937.genns.prod/mba.mbn
)

######
# mbn which will be download directly
# need to check every project.
#
FILE_PATH_4_DOWNLOAD=(
    ./out/boot/sbl1.mbn
    ./out/boot/prog_emmc_firehose_8937_ddr.mbn
    ./out/rpm/rpm.mbn
    ./out/tz/cmnlib.mbn
    ./out/tz/cmnlib64.mbn
    ./out/tz/devcfg.mbn
    ./out/tz/keymaster.mbn
    ./out/tz/tz.mbn
    #./out/tz/lksecapp.mbn
    #./out/adsp/adspso.bin
)


#signed 3rd TA add by zkx 20160918
MBN_3RD_TA_PATH=(
    ./out/tz/goodixfp.mbn
	./out/tz/sw_fp.mbn
)


function wt_sign_mbn_4_download()
{
    rm -fr ./$WT_SECIMAGE_OUTPUT_PATH
    echo "signed images"
    for i in "${FILE_PATH_4_DOWNLOAD[@]}"
    do
        echo ${i}
        python $WT_SECTOOLS_HOME/sectools.py secimage -i ${i} -c ./$WT_SECIMAGE_XML_PATH -sa
    done
    #copy files
    echo "copy signed bin to signed_out"
    for i in "${FILE_PATH_4_DOWNLOAD[@]}"
    do
        echo $i
        cp $WT_SECIMAGE_OUTPUT_PATH/`basename $i .mbn`/`basename $i` $SIGNED_OUT_FOLDER
    done
    cp ./$WT_SECIMAGE_OUTPUT_PATH/prog_emmc_firehose_ddr/prog_emmc_firehose_8937_ddr.mbn $SIGNED_OUT_FOLDER
    cp $WT_SECIMAGE_OUTPUT_PATH/qsee/tz.mbn $SIGNED_OUT_FOLDER
}

function wt_sign_mbn_4_NON_HLOS()
{
    rm -fr ./$WT_MSM_ROOT/common/sectools/secimage_output
    echo "signed images"
    for i in "${FILE_PATH_4_GENERATE_NON_HLOS[@]}"
    do
        echo ${i}
        python $WT_SECTOOLS_HOME/sectools.py secimage -i ${i} -c ./$WT_SECIMAGE_XML_PATH -sa
    done

    #copy files
    for i in ${FILE_PATH_4_GENERATE_NON_HLOS[@]}
    do
        echo $i
        cp $WT_SECIMAGE_OUTPUT_PATH/`basename $i .mbn`/`basename $i` $i
    done
    #copy files
    cp $WT_SECIMAGE_OUTPUT_PATH/modem/modem.mbn ./MPSS.JO.3.0/modem_proc/build/ms/bin/8937.genns.prod/qdsp6sw.mbn

#SIGNED_OUT_NONHLOS_FOLDER=./signed_out/nonhlos
#rm -fr $SIGNED_OUT_NONHLOS_FOLDER
#mkdir $SIGNED_OUT_NONHLOS_FOLDER -p
#for i in ${FILE_PATH_4_GENERATE_NON_HLOS[@]}
#do
#    echo $i
#    cp $i ${SIGNED_OUT_NONHLOS_FOLDER}
#done
}

function wt_build_non_hlos()
{
    cd ./$WT_MSM_ROOT/common/build/
    python build.py --nonhlos
    cd -
}

function wt_build_sec_dat()
{
    python $WT_SECTOOLS_HOME/sectools.py fuseblower --platform=8937 --generate --validate
}

function wt_signed_3rd_ta()
{
    for i in "${MBN_3RD_TA_PATH[@]}"
    do
        echo ${i}
        python $WT_SECTOOLS_HOME/sectools.py secimage -i ${i} -c ./$WT_SECIMAGE_XML_PATH -sa -o $SIGNED_OUT_FOLDER
    done
}

function wt_build_dp_mbn()
{
    cd $WT_MSM_ROOT/common/sectools
    python sectools.py debugpolicy -c config/8937/8937_debugpolicy.xml -e config/8937/8937_dbgp_secimage.xml -g
    cd -
    rm -fr $SIGNED_OUT_FOLDER/dp
    mkdir -p $SIGNED_OUT_FOLDER/dp
    cp $WT_MSM_ROOT/common/sectools/debugpolicy_output/* $SIGNED_OUT_FOLDER/dp
}


#Step.1. sign and copy out's file to signed_out
wt_sign_mbn_4_download
cp ./out/adsp/adspso.bin $SIGNED_OUT_FOLDER
cp ./out/tz/lksecapp.mbn $SIGNED_OUT_FOLDER

#Step.2. sign mbn for nonhlos, then rebuild nonhlos.
wt_sign_mbn_4_NON_HLOS
wt_build_non_hlos
cp ./$WT_MSM_ROOT/common/build/bin/asic/NON-HLOS.bin $SIGNED_OUT_FOLDER

##Step.3. sign 3rd TA(.mbn)
#wt_signed_3rd_ta

###################################################
#
#Some options for developing or testing
#

#Build sec.dat.
#wt_build_sec_dat
cp ./$WT_MSM_ROOT/common/sectools/fuseblower_output/v2/sec.dat $SIGNED_OUT_FOLDER


##Build dump mbn.
#wt_build_dp_mbn
