#########################################################################
# File Name: repo_sync.sh
# Author: WangSen
# Email: wangs_hs@163.com
# Created Time: 2016年06月24日 星期五 14时35分31秒
#########################################################################
#!/bin/bash

# git clone https://android.googlesource.com/tools/repo
# git clone https://gerrit.googlesource.com/git-repo

Source_PATH=`pwd`
NOW_DATE=`date +%Y%m%d_%H-%M-%S`
Manifest_XML_PATH=${Source_PATH}/manifest

#****************************************#
QFIL_WHITE="\\033[0m"
QFIL_GREEN="\\033[40;32m"
QFIL_YELLOW="\\033[40;33m"
QFIL_RED="\\033[40;31m"
#****************************************#

SYNC_CLEAN=false
SYNC_Manifest=false
SYNC_FORCE=false
SYNC_MODE=current

function usage()
{
cat << EOF

Usage: $0 [-h] [-c] [-q] [-m MODE]

Optional arguments:
-h, --help              show this help message and exit
-c, --clean             clear all changes and exceptions
-q, --manifest          save generate manifest.xml
-m, --mode=MODE
			object option, default is "current".
			all		fetch all branch from server
			current		fetch only current branch from server

Example:
default: $0 -m current
long: $0 -c -q -m all

EOF
}

# parse parameters
ARGS=`getopt -o cqhm: --long clean,manifest,help,mode: -n '* ERROR' -- "$@"`
if [ $? != 0 ] ; then
    echo error "$0 exited with doing nothing." >&2
    exit 1
fi
# Note the quotes around $TEMP: they are essential!  
eval set -- "${ARGS}"

# set option values  
while [ -n "$1" ]
do
    case "$1" in
	-h | --help)
	    usage
	    exit 1 ;;
	-c | --clean)
	    echo "====== parameter [$#] : $1 ======"
	    SYNC_CLEAN=true
	    shift 1 ;;
	-q | --manifest)
	    echo "====== parameter [$#] : $1 ======"
	    SYNC_Manifest=true
	    shift 1 ;;
	-m | --mode)
	    echo "====== parameter [$#] : $1 ======"
	    SYNC_MODE=$2
	    shift 2 ;;
	--)
	    if [ $# -eq 1 ]; then
		break
	    fi
	    echo "====== Invalid parameter [$#] : $@ ======"
	    shift $# ;;
	*)
	    echo error "====== ERROR ======"
	    usage
	    exit 1 ;;
    esac
done


#****************************************#
CPU_Processor=`cat /proc/cpuinfo |grep processor | wc -l`
thread_jobs=$[${CPU_Processor} + 8]
echo -e "\n====== thread_jobs=${thread_jobs} ======\n"
#****************************************#

function get_args()
{
    if [ -z "${argv[0]}" ] || [ ${argv[0]} -lt 0 ] || [ ${argv[0]} -gt 1 ]; then
	echo -e "Build:"
	echo -e "0. ${QFIL_GREEN}Not Clean 'out', Incremental SYNC.${QFIL_WHITE}"
	echo -e "1. ${QFIL_GREEN}Clear All 'out', Full SYNC.${QFIL_WHITE}"
	echo -e "Your choice:\c"
	read need_clean
    else
	need_clean=${argv[0]}
	argv[0]=""
    fi

    if [ -z "${need_clean}" ] || [ ${need_clean} -lt 0 ] || [ ${need_clean} -gt 1 ]; then
	get_args
    fi
}

function repo_clean()
{
    echo -e "\n${QFIL_GREEN}====== <Clear> all changes and exceptions ======${QFIL_WHITE}\n"

    repo forall -v -c '
	if [ -e ".git/index.lock" ]; then
	    rm -vf .git/index.lock
	fi
	if [ ! -s ".git/ORIG_HEAD" ]; then
	    rm -vf .git/ORIG_HEAD
	fi
    ' -j${thread_jobs}

    #repo forall -v -c 'git reset -q --hard HEAD; git clean -q -df; git rebase --abort' -j${thread_jobs}
    repo forall -v -c 'git rebase --abort' -j${thread_jobs}
    repo forall -v -c 'git reset --hard' -j${thread_jobs}
    repo forall -v -c 'git clean -df' -j${thread_jobs}
    if [ $? -ne 0 ]; then
	echo -e "[repo] forall result is:     ${QFIL_RED}Failure${QFIL_WHITE}\n"
	exit -1
    fi
    sync
}

function repo_sync()
{
    if [ "$SYNC_MODE" = "all" ]; then
	echo -e "\n${QFIL_GREEN}====== fetch <All> branch from server ======${QFIL_WHITE}\n"
	sync_cmds="--no-repo-verify -j${thread_jobs}"
    else
	echo -e "\n${QFIL_GREEN}====== fetch <Only Current> branch from server ======${QFIL_WHITE}\n"
	sync_cmds="--no-repo-verify -c -j${thread_jobs}"
    fi

    if [ "$SYNC_FORCE" = "true" ]; then
	echo -e "\n${QFIL_GREEN}====== Force sync from server ======${QFIL_WHITE}\n"
	sync_cmds="--force-sync "${sync_cmds}
    fi

    local count=1

    repo sync ${sync_cmds}
    while [ $? -ne 0 ] 
    do
	if [ ${count} -lt 1 ]; then
	    count=$[${count} - 1]
	    break;
	fi
	count=$[${count} - 1]

	echo -e "\n[`date +"%Y-%m-%d %H:%M:%S"`] ${QFIL_RED}====== repo sync Failed -> ${sync_cmds} ======${QFIL_WHITE}\n"
	sleep 1
	repo sync ${sync_cmds}
    done

    if [ $count -lt 0 ]; then
	echo -e "[repo] sync result is:     ${QFIL_RED}Failure${QFIL_WHITE}\n"
	exit -1
    fi
    sync
}

###### MAIN ######
function start_main()
{
    # Clean the Build
    if [ "$SYNC_CLEAN" = "true" ]; then
	get_args
	if [ $need_clean -eq 1 ] && [ -d "out" ]; then
	    echo -e "====== Clean out dir ======\n"
	    #选项说明：
	    #--delete-before 接收者在传输之前进行删除操作
	    #--progress 在传输时显示传输过程
	    #-a 归档模式，表示以递归方式传输文件，并保持所有文件属性, -rlptgoD (no -H,-A,-X)
	    #-H 保持硬连接的文件
	    #-v 详细输出模式
	    #--stats 给出某些文件的传输状态
	    mkdir rsync_empty
	    rsync --delete-before -a -H -v --progress --stats  rsync_empty/ out/
	    rm -vrf  rsync_empty/ out/
	fi
	rm -vrf log*
	sync

	repo_clean
    fi
    sync

    # repo sync
    echo -e "====== repo sync source ======\n"
    repo_sync
    echo -e "\n[`date +"%Y-%m-%d %H:%M:%S"`] ====== sync result is:     Successfully ======\n"

    # repo manifest
    if [ "$SYNC_Manifest" = "true" ]; then
	echo -e "====== repo Manifest ======\n"
	if [ ! -d ${Manifest_XML_PATH} ]; then
	    mkdir -p ${Manifest_XML_PATH}
	fi
	repo manifest -r -o ${Manifest_XML_PATH}/manifest_${NOW_DATE}.xml
    fi
    sync
}

start_main

sync
echo -e "\n[`date +"%Y-%m-%d %H:%M:%S"`] ${QFIL_GREEN}######## make completed successfully  ########${QFIL_WHITE}\n"
