#!/bin/bash
#########################################################################
# File Name: repo_sync_l.sh
# Author: WangSen
# Email: wangs_hs@163.com
# Created Time: 2018年03月07日 星期三 17时50分11秒
#########################################################################

repo init --no-repo-verify -u git://codeaurora.org/platform/manifest.git -b release -m LA.UM.6.7.r1-05500-8x09.0.xml

repo sync -c --no-repo-verify bootable/bootloader/lk

# --no-repo-verify    do not verify repo source code

# -l, --local-only      only update working tree, don't fetch
# -c, --current-branch  fetch only current branch from server

repo sync --no-repo-verify -l -c kernel/msm-3.18


git checkout -b msm8909-la-3-0-1_dev origin/msm8909-la-3-0-1_dev
git fetch origin msm8909-la-3-0-1_patch_only:msm8909-la-3-0-1_patch_only
git merge msm8909-la-3-0-1_patch_only

