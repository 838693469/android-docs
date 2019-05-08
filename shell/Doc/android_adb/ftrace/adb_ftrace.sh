#!/bin/bash
#########################################################################
# File Name: adb_ftrace.sh
#########################################################################

LOG_PATH=~/Downloads

adb wait-for-device
adb shell "cat /d/tracing/tracing_on"
adb shell "echo 0 > /d/tracing/tracing_on"
adb shell "cat /d/tracing/tracing_on"
adb shell "cat /d/tracing/trace > /data/local/tmp/trace_wakeup.txt"
adb pull /data/local/tmp/trace_wakeup.txt ${LOG_PATH}
adb shell sync
sync

adb shell "rm -rf /data/local/tmp/trace*"
sync
