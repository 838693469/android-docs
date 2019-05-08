#!/bin/bash
#########################################################################
# File Name: git_init.sh
# Author: WangSen
# Email: wangs_hs@163.com
# Created Time: 2018年01月26日 星期五 11时19分07秒
#########################################################################

if [ ! -d ".git" ]; then
    git init
    git add .
    git commit -m "[INIT] initial code base for Snapdragon_High_Med_2016.SPF.2.0"
fi
sync
