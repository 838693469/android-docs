LOCAL_PATH:= $(call my-dir)

include $(CLEAR_VARS)
LOCAL_SRC_FILES:= i2c_test.c

LOCAL_MODULE:= pn544_i2c_test

LOCAL_MODULE_TAGS := optional


include $(BUILD_EXECUTABLE)

