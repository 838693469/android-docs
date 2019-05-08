#! /bin/bash
echo ""
echo "Start ramdump parser.."
 
local_path=$PWD
ramdump_dir=/work/asus/versions/sku1_p/409/userdebug/Port_COM4
ramdump=$ramdump_dir/
vmlinux=$ramdump_dir/vmlinux
out=$local_path/out
 
#gnu tools would be found in source code:prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9
GNU_TOOLS=/Android_Disk2/Projects/SKU1_P_dev/prebuilts/gcc/linux-x86/aarch64
GDB_TOOL=/Android_Disk2/Projects/SKU1_P_dev/prebuilts/gdb/linux-x86/bin
gdb=${GDB_TOOL}/gdb
nm=${GNU_TOOLS}/aarch64-linux-android-4.9/bin/aarch64-linux-android-nm
objdump=${GNU_TOOLS}/aarch64-linux-android-4.9/bin/aarch64-linux-android-objdump
 
# git clone git://codeaurora.org/quic/la/platform/vendor/qcom-opensource/tools
ramparse_dir=/Android_Disk2/Projects/SKU1_P_dev/vendor/qcom/opensource/tools/linux-ramdump-parser-v2
# please refer to the README in the ramparse_dir and create local_settings.py in this directory
#---------------------------------------------------------------------------------------------#
#local_settings.py
#gdb64_path='/Android_Disk2/Projects/SKU1_P_dev/prebuilts/gdb/linux-x86/bin/gdb'
#nm64_path='/Android_Disk2/Projects/SKU1_P_dev/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-nm'
#objdump64_path='/Android_Disk2/Projects/SKU1_P_dev/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-objdump'
#---------------------------------------------------------------------------------------------#
########################################################################################
 
echo "cd $ramparse_dir"
cd $ramparse_dir
echo ""
 
echo -e "python ramparse.py -v $vmlinux -g $gdb  -n $nm  -j $objdump -a $ramdump -o $out -x"
echo ""
 
# python 2.7.5
python ramparse.py -v $vmlinux -g $gdb  -n $nm  -j $objdump -a $ramdump -o $out -x
 
#cd $local_path
echo "out: $out"
echo ""
exit 0
