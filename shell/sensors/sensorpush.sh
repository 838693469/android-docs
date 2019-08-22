#!/usr/bin/env bash
# jar
# frameworks/base/core/java/android/hardware

# frameworks/base/core/jni

# frameworks/native/services/sensorservice

# hardware/interfaces/sensors/1.0/default

# frameworks/native/libs/sensor

# hal
# sensor1
# daemon
# adsp

function debug(){
    case $1 in
        cmd)
            echo -e "$2"
            ;;
        info) #Green
            echo -e "\033[0;32m$2\033[0m\t"
            ;;
        warn) #Yellow
            echo -e "\033[0;33m$2\033[0m\t"
            ;;
        error) #Red
            echo -e "\033[0;31mERROR: $2\033[0m\t"
            ;;
        *) WARN "debug:Don't have this choise!"
    esac
}

function cmd(){
    debug cmd "$@"
    $@
    local retVal=$?

    if [ $retVal -ne 0 ]; then
        local msg=$(perror $retVal)
        debug error "=============== : ${msg#*:}============="
    fi
    return $retVal

}
function app(){
    # app => vendor/qcom/proprietary/sensors/
    adb push $ANDROID_PRODUCT_OUT/vendor/app/QSensorTest /vendor/app/
}
function jar(){
    # jar
    # frameworks/base/core/java/android/hardware
    adb push $ANDROID_PRODUCT_OUT/system/framework/arm/boot-framework.art /system/framework/arm/
    adb push $ANDROID_PRODUCT_OUT/system/framework/arm/boot-framework.oat /system/framework/arm/
    adb push $ANDROID_PRODUCT_OUT/system/framework/arm/boot-framework.art.rel /system/framework/arm/
    adb push $ANDROID_PRODUCT_OUT/system/framework/arm64/boot-framework.art /system/framework/arm64/
    adb push $ANDROID_PRODUCT_OUT/system/framework/arm64/boot-framework.oat /system/framework/arm64/
    adb push $ANDROID_PRODUCT_OUT/system/framework/arm64/boot-framework.art.rel /system/framework/arm64/
    adb push $ANDROID_PRODUCT_OUT/system/framework/boot-framework.vdex /system/framework/
    adb push $ANDROID_PRODUCT_OUT/system/framework/framework.jar /system/framework/
}

function jni(){
    # frameworks/base/core/jni
    adb push $ANDROID_PRODUCT_OUT/system/lib64/libandroid_runtime.so /system/lib64/ #SensorManager
}

function native(){
    # frameworks/native/services/sensorservice
    adb push $ANDROID_PRODUCT_OUT/system/lib64/libsensorservicehidl.so /system/lib64/ #HidlSensorManager
    adb push $ANDROID_PRODUCT_OUT/system/lib64/libsensorservice.so /system/lib64/ #SensorService
}
function libsensors(){
    # frameworks/native/libs/sensor
    adb push $ANDROID_PRODUCT_OUT/system/lib64/libsensor.so /system/lib64/ #Sensors
}

function hidl(){
    # hardware/interfaces/sensors/1.0/default
    echo ''
}

function hal(){
    # hal => vendor/qcom/proprietary/sensors/dsps/libhalsensors
    adb push $ANDROID_PRODUCT_OUT/vendor/lib64/hw/sensors.sdm660_64.so /vendor/lib64/hw/ #qti_sensors_hal
}

function sensor1(){
    # Sensor1 library => vendor/qcom/proprietary/sensors/dsps/libsensor1
    adb push $ANDROID_PRODUCT_OUT/vendor/lib/libsensor1.so  /vendor/lib/  #libsensor1
}

function daemon(){
    # Sensors daemon => vendor/qcom/proprietary/sensors/dsps/sensordaemon
    adb push $ANDROID_PRODUCT_OUT/vendor/bin/sensors.qti /vendor/bin/ #Sensors
}

function conf(){
    adb push $ANDROID_BUILD_TOP/vendor/qcom/proprietary/sensors/dsps/reg_defaults/sensor_def_qcomdev.conf /system/vendor/etc/sensors/sensor_def_qcomdev.conf
}

function adsp(){
    # adsp
    adb shell mount -o remount,rw /vendor/firmware_mnt
    adb push $ANDROID_BUILD_TOP/amss_codes/ADSP.VT.4.1/adsp_proc/obj/qdsp6v5_ReleaseG/660.adsp.prod/signed/LA/system/etc/firmware/* /vendor/firmware_mnt/image/
    #adb push $ANDROID_BUILD_TOP/amss_codes/ADSP.VT.4.1/adsp_proc/obj/qdsp6v5_ReleaseG/660.adsp.prod/signed/LA/system/etc/firmware/* /sdcard/
}



adb root && adb wait-for-device
adb remount
adb shell rm /mnt/vendor/persist/sensors/sns.reg
debug info $@
for command in $@; do
    case $command in

        hal)
            # hal => vendor/qcom/proprietary/sensors/dsps/libhalsensors
            hal
            continue
            ;;
        sensor1)
            # Sensor1 library => vendor/qcom/proprietary/sensors/dsps/libsensor1
            sensor1
            continue
            ;;
        daemon)
            # Sensors daemon => vendor/qcom/proprietary/sensors/dsps/sensordaemon
            daemon
            continue
            ;;
        conf)
            #sensor_def_qcomdev.conf
            conf
            continue
            ;;
        adsp)
            # adsp
            adsp
            continue
            ;;
        app)
            # adsp
            app
            continue
            ;;
        all)
            hal
            sensor1
            daemon
            conf
            adsp
            break
            ;;
        help)
            echo "help world"
            continue
            ;;
    esac
done

debug info "please input y or n to reboot"
read cmd
if [ x$cmd==x'y' ] || [ x$cmd==x'Y' ] ; then

    #adb reboot
    echo "ddd"
fi

