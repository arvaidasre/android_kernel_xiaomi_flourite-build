# SPDX-License-Identifier: Apache-2.0
FLOURITE_KERNEL_BUILD := kernel/xiaomi/flourite-build
FLOURITE_KERNEL_MODULE_SOURCE := kernel/xiaomi/flourite-source-modules
FLOURITE_KERNEL_DT_SOURCE := kernel/xiaomi/sm7635-devicetrees
FLOURITE_KERNEL_CLANG := kernel/prebuilts/clang-r487747c
FLOURITE_KERNEL_BUILD_TOOLS := kernel/prebuilts/build-tools-2023
FLOURITE_SOURCE_KERNEL_OUT := $(PRODUCT_OUT)/obj/FLOURITE_KERNEL
FLOURITE_SOURCE_DIST := $(FLOURITE_SOURCE_KERNEL_OUT)/dist

# The device rule builds Image and all modules as one dependency graph.
TARGET_NO_KERNEL_OVERRIDE := true
TARGET_PREBUILT_KERNEL := $(FLOURITE_SOURCE_DIST)/Image
BOARD_PREBUILT_DTBOIMAGE := $(FLOURITE_SOURCE_DIST)/dtbo.img
BOARD_DO_NOT_STRIP_VENDOR_MODULES := true
BOARD_DO_NOT_STRIP_VENDOR_RAMDISK_MODULES := true
BOARD_SYSTEM_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_KERNEL_CMDLINE += enforcing=1
BOARD_BOOTCONFIG += androidboot.selinux=enforcing

BOARD_SYSTEM_KERNEL_MODULES := $(addprefix $(FLOURITE_SOURCE_DIST)/system_dlkm/,$(strip $(shell cat $(FLOURITE_KERNEL_BUILD)/modules.list.system_dlkm)))
BOARD_VENDOR_KERNEL_MODULES := $(addprefix $(FLOURITE_SOURCE_DIST)/vendor_dlkm/,$(strip $(shell cat $(FLOURITE_KERNEL_BUILD)/modules.list.vendor_dlkm)))
BOARD_VENDOR_RAMDISK_KERNEL_MODULES := $(addprefix $(FLOURITE_SOURCE_DIST)/vendor_ramdisk/,$(strip $(shell cat $(FLOURITE_KERNEL_BUILD)/modules.list.vendor_ramdisk)))
BOARD_SYSTEM_KERNEL_MODULES_LOAD := $(strip $(shell cat $(FLOURITE_KERNEL_BUILD)/modules.load.system_dlkm))
BOARD_VENDOR_KERNEL_MODULES_LOAD := $(strip $(shell cat $(FLOURITE_KERNEL_BUILD)/modules.load.vendor_dlkm))
BOARD_VENDOR_RAMDISK_KERNEL_MODULES_LOAD := $(strip $(shell cat $(FLOURITE_KERNEL_BUILD)/modules.load.vendor_ramdisk))
BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD := $(strip $(shell cat $(FLOURITE_KERNEL_BUILD)/modules.load.recovery))
BOARD_VENDOR_KERNEL_MODULES_BLOCKLIST_FILE := $(FLOURITE_KERNEL_BUILD)/modules.blocklist
BOARD_VENDOR_RAMDISK_KERNEL_MODULES_BLOCKLIST_FILE := $(FLOURITE_KERNEL_BUILD)/modules.blocklist
