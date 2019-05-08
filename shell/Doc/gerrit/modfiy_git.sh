#!/bin/bash
#########################################################################
# File Name: modfiy_git.sh
# Author: WangSen
# Email: wangs_hs@163.com
# Created Time: 2018年02月02日 星期五 09时43分14秒
#########################################################################

mkdir TZ.BF.4.0.5
mv TZ.BF.4.0.5 TZ.BF.4.0.5/.git
cd TZ.BF.4.0.5
git init
git checkout BYD_N_Msm8953

git clone TZ.BF.4.0.5 --mirror mirror/TZ.BF.4.0.5

#--mirror
    #Set up a mirror of the source repository. This implies --bare. Compared to --bare, --mirror not only maps local branches of the source to local branches of the target, it maps all refs (including remote-tracking branches, notes etc.) and sets up a refspec configuration such that all these refs are overwritten by a git remote update in the target repository.

