#!/bin/bash
#########################################################################
# File Name: archermind_qualcomm.sh
# Author: WangSen
# Email: wangs_hs@163.com
# Created Time: 2018年12月19日 星期三 11时13分13秒
#########################################################################

# SKU1_ZC600KL:
repo init --no-repo-verify -u ssh://n008586@gerritnj01.archermind.com:29418/HQ_BD1SW_ASUS/platform/manifest -m pie_sku1_ZC600KL_dev.xml

repo init --no-repo-verify -u ssh://n008586@gerritnj01.archermind.com:29418/HQ_BD1SW_ASUS/platform/manifest -b tmp_600_new


# ZB555KL:
repo init --no-repo-verify -u ssh://n008586@gerritnj01.archermind.com:29418/HQ_BD1SW_ASUS/platform/manifest -b pie_ZB555KL_dev

# pie_ZA550KL_dev



# repo sync -c -j8 --no-tags
