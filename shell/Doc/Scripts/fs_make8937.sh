#!/bin/bash
curPWD=`pwd`
OUT_PATH=fs_image
curUser=`whoami`

mkdir -p $OUT_PATH/

# 将当前目录下的 fs_image.tar.gz 生成对应 img
cp ./fs_image.tar.gz ../../../MPSS.JO.3.0/modem_proc/core/storage/tools/
python sectools.py mbngen -i ../../../MPSS.JO.3.0/modem_proc/core/storage/tools/fs_image.tar.gz -t efs_tar_40 -o ../../../MPSS.JO.3.0/modem_proc/core/storage/tools/ -g

python sectools.py secimage -i ../../../MPSS.JO.3.0/modem_proc/core/storage/tools/fs_image.tar.gz.mbn -c config/8937/8937_secimage.xml -o $OUT_PATH -sa

cp ./$OUT_PATH/8937/efs_tar/fs_image.tar.gz.mbn ../../../MPSS.JO.3.0/modem_proc/core/bsp/efs_image_header/tools
cp ../../../MPSS.JO.3.0/modem_proc/build/ms/bin/8937.genns.prod/efs_image_meta.bin ../../../MPSS.JO.3.0/modem_proc/core/bsp/efs_image_header/tools
python ../../../MPSS.JO.3.0/modem_proc/core/bsp/efs_image_header/tools/efs_image_create.py  ../../../MPSS.JO.3.0/modem_proc/core/bsp/efs_image_header/tools/efs_image_meta.bin  ../../../MPSS.JO.3.0/modem_proc/core/bsp/efs_image_header/tools/fs_image.tar.gz.mbn
cp ../../../MPSS.JO.3.0/modem_proc/core/bsp/efs_image_header/tools/fs_image.tar.gz.mbn.img  $curPWD/$OUT_PATH/

# 替换掉 wind 下并释放出去

cp $curPWD/$OUT_PATH/fs_image.tar.gz.mbn.img ../../../../vendor/wind/qcn_partition_img/fs_image.tar.gz.mbn.E300L.8937.full.band.img
cp $curPWD/$OUT_PATH/fs_image.tar.gz.mbn.img /data/mine/test/MT6572/$curUser/
