#!/bin/bash
#########################################################################
# File Name: build_splash.sh
# Author: WangSen
# Email: wangs_hs@163.com
# Created Time: 2017年06月01日 星期四 16时43分45秒
#########################################################################

python ./logo_gen.py asus_720x1280_phone_android_1.png
mv splash.img asus_720x1280_phone_android_1.img
python ./logo_gen.py asus_720x1280_phone_android_2.png
mv splash.img asus_720x1280_phone_android_2.img
sync

dd if=asus_720x1280_phone_android_1.img of=splash.img bs=1k seek=1
dd if=asus_720x1280_phone_android_2.img of=splash.img bs=1k seek=100
sync

rm -rf asus_720x1280_phone_android_1.img
rm -rf asus_720x1280_phone_android_2.img
sync
