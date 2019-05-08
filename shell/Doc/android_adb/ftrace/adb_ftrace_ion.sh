#!/bin/bash
#########################################################################
# File Name: adb_ftrace_ion.sh
#########################################################################
adb wait-for-device
adb root
adb wait-for-device

adb shell "/data/run_ftrace_ion.sh" &
adb shell sync

adb shell "cat /d/ion/heaps/* > /data/ionheaps_before.txt"
echo "==================================================="
sleep 15
echo "==================================================="
adb shell "cat /d/ion/heaps/* > /data/ionheaps_after.txt"

adb shell "bugreport > /data/bugreport.log"

adb shell sync

mkdir ftrace_ion

adb pull /data/ionheaps_before.txt ftrace_ion/
adb pull /data/ionheaps_after.txt ftrace_ion/

adb pull /data/bugreport.log ftrace_ion/

adb shell sync
