#!/bin/bash
#########################################################################
# File Name: git_apply.sh
# Author: WangSen
# Email: wangs_hs@163.com
# Created Time: 2018年08月21日 星期二 13时09分02秒
#########################################################################


### --ignore-space-change ignore changes in whitespace when finding context
### --ignore-whitespace   ignore changes in whitespace when finding context
### --reject              leave the rejected hunks in corresponding *.rej files

echo -e "====== [$@] ====== \n"
git apply --ignore-space-change --ignore-whitespace --reject $1

sync
