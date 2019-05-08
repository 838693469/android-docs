#!/bin/bash
#########################################################################
# File Name: huaqin_qualcomm.sh
# Author: WangSen
# Email: wangs_hs@163.com
# Created Time: 2017年03月03日 星期五 14时55分34秒
#########################################################################

repo init --no-repo-verify -u ssh://WB20174643@61.152.125.66:29418/manifest -m A6000_LENOVO_master.xml --reference=/HQProjectMirror/A6000
#--mirror

A6000_LENOVO_master.xml #8917平台
A6090_LENOVO.xml #8953平台
A600x_LENOVO_SMT.xml #factory
A6096N_LENOVO_ATT.xml #A6096
A6090_LENOVO_NEC.xml #nec

#driver only
A600x_driveronly.xml
A609x_driveronly.xml


sudo apt-get install sshfs
sshfs ubuntu@10.20.32.69:/work/HQProjectMirror /HQProjectMirror

