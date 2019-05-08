#!/bin/bash
#########################################################################
# File Name: grep_exclude.sh
# Author: WangSen
# Email: wangs_hs@163.com
# Created Time: 2018年01月24日 星期三 14时22分26秒
#########################################################################

echo -e "====== [$@] ====== \n"
grep -nrs \
    --exclude=*.o \
    --exclude=*.lib \
    --exclude=*.txt \
    --exclude=*.elf \
    --exclude=*.sym \
    --exclude=*.mbn \
    --exclude=*.map \
    --exclude=*.per \
    --exclude=*.pbn \
    --exclude=*.xml.pp \
    --exclude=*.xml.i \
    --exclude=*.pyc \
    --exclude=*.cmm \
    "$1" .
