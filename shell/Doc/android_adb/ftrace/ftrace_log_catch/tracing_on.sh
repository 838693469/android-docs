#!/system/bin/sh
#########################################################################
# File Name: tracing_on.sh
#########################################################################

echo "====== $0: PID of this script: $$ ======\n"

sleep 10
echo 1 > /d/tracing/tracing_on
sleep 30
echo 0 > /d/tracing/tracing_on
sync
