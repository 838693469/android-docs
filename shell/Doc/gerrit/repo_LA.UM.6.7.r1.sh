#!/bin/bash
#########################################################################
# File Name: repo_init.sh
# Author: WangSen
# Email: wangs_hs@163.com
# Created Time: 2018年04月24日 星期二 17时58分41秒
#########################################################################

https://chipmaster2.qti.qualcomm.com/home2/git/huaqin-telecom-technology-co-ltd-shanghai/msm8909-la-3-1-1_amss_standard_oem.git
repo init -u https://source.codeaurora.org/quic/la/platform/manifest.git -b release -m LA.UM.6.7.r1-06000-8x09.0.xml --repo-url=git://codeaurora.org/tools/repo.git --repo-branch=caf-stable

# repo init -u git://codeaurora.org/platform/manifest.git -b release -m [manifest] --repo-url=git://codeaurora.org/tools/repo.git --repo-branch=caf-stable
repo init --no-repo-verify -u git://codeaurora.org/platform/manifest.git -b release -m LA.UM.6.7.r1-06000-8x09.0.xml

repo sync -c --no-repo-verify bootable/bootloader/lk
repo sync -c --no-repo-verify kernel/msm-3.18

