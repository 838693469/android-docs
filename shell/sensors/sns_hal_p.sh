adb root
adb wait-for-device
adb shell setprop debug.sns.daemon.ftrace 1
adb shell setprop debug.sns.hal.ftrace 1
adb shell setprop debug.vendor.sns.libsensor1 1
adb shell setprop persist.vendor.debug.sensors.hal 1

adb shell stop
adb shell stop sensors
adb shell start sensors
adb shell start
