# SPDX-License-Identifier: Apache-2.0
FLOURITE_SOURCE_DIST := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))

ifeq ($(wildcard $(FLOURITE_SOURCE_DIST)/Image),)
$(error Build the complete Flourite source distribution first)
endif
TARGET_FORCE_PREBUILT_KERNEL := true
TARGET_PREBUILT_KERNEL := $(FLOURITE_SOURCE_DIST)/Image

# Retain the tested firmware DTB/DTBO until the source DT is validated.
BOARD_PREBUILT_DTBIMAGE_DIR := device/xiaomi/flourite-kernel/dtb
BOARD_PREBUILT_DTBOIMAGE := device/xiaomi/flourite-kernel/dtbo.img
BOARD_DO_NOT_STRIP_VENDOR_MODULES := true
BOARD_DO_NOT_STRIP_VENDOR_RAMDISK_MODULES := true
BOARD_SYSTEM_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_KERNEL_CMDLINE += enforcing=1
BOARD_BOOTCONFIG += androidboot.selinux=enforcing

BOARD_SYSTEM_KERNEL_MODULES := $(addprefix $(FLOURITE_SOURCE_DIST)/system_dlkm/,$(strip $(shell cat $(FLOURITE_SOURCE_DIST)/modules.list.system_dlkm)))
BOARD_VENDOR_KERNEL_MODULES := $(addprefix $(FLOURITE_SOURCE_DIST)/vendor_dlkm/,$(strip $(shell cat $(FLOURITE_SOURCE_DIST)/modules.list.vendor_dlkm)))
BOARD_VENDOR_RAMDISK_KERNEL_MODULES := $(addprefix $(FLOURITE_SOURCE_DIST)/vendor_ramdisk/,$(strip $(shell cat $(FLOURITE_SOURCE_DIST)/modules.list.vendor_ramdisk)))
BOARD_SYSTEM_KERNEL_MODULES_LOAD := $(strip $(shell cat $(FLOURITE_SOURCE_DIST)/modules.load.system_dlkm))
BOARD_VENDOR_KERNEL_MODULES_LOAD := $(strip $(shell cat $(FLOURITE_SOURCE_DIST)/modules.load.vendor_dlkm))
BOARD_VENDOR_RAMDISK_KERNEL_MODULES_LOAD := $(strip $(shell cat $(FLOURITE_SOURCE_DIST)/modules.load.vendor_ramdisk))
BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD := $(strip $(shell cat $(FLOURITE_SOURCE_DIST)/modules.load.recovery))
BOARD_VENDOR_KERNEL_MODULES_BLOCKLIST_FILE := $(FLOURITE_SOURCE_DIST)/modules.blocklist
BOARD_VENDOR_RAMDISK_KERNEL_MODULES_BLOCKLIST_FILE := $(FLOURITE_SOURCE_DIST)/modules.blocklist
