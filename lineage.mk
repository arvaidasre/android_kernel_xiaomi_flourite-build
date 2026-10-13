# SPDX-License-Identifier: Apache-2.0
flourite_kernel_repos := $(TARGET_KERNEL_SOURCE) $(FLOURITE_KERNEL_MODULE_SOURCE) $(FLOURITE_KERNEL_DT_SOURCE) $(FLOURITE_KERNEL_BUILD) external/dtc system/libufdt
# Ignore leftover build products in source checkouts; modules use git archive.
flourite_kernel_inputs := $(foreach path,$(flourite_kernel_repos),$(addprefix $(path)/,$(shell git -C $(path) ls-files)))
flourite_kernel_inputs += vendor/lineage/build/tools/merge_dtbs.py
flourite_kernel_outputs := $(TARGET_PREBUILT_KERNEL) $(FLOURITE_SOURCE_DIST)/dtb.img $(BOARD_PREBUILT_DTBOIMAGE) $(BOARD_SYSTEM_KERNEL_MODULES) $(BOARD_VENDOR_KERNEL_MODULES) $(BOARD_VENDOR_RAMDISK_KERNEL_MODULES)
flourite_kernel_stamp := $(FLOURITE_SOURCE_KERNEL_OUT)/.built

$(flourite_kernel_stamp): .KATI_IMPLICIT_OUTPUTS := $(flourite_kernel_outputs)
$(flourite_kernel_stamp): PRIVATE_KERNEL_TOP := $(abspath .)
$(flourite_kernel_stamp): PRIVATE_KERNEL_OUT := $(abspath $(FLOURITE_SOURCE_KERNEL_OUT))
$(flourite_kernel_stamp): $(flourite_kernel_inputs) $(FLOURITE_KERNEL_CLANG)/bin/clang $(FLOURITE_KERNEL_BUILD_TOOLS)/bin/pahole
	@echo "Building Flourite source kernel and matching modules"
	$(hide) bash kernel/xiaomi/flourite-build/lineage-build.sh "$(PRIVATE_KERNEL_TOP)" "$(PRIVATE_KERNEL_OUT)"

$(PRODUCT_OUT)/kernel: $(TARGET_PREBUILT_KERNEL)
	$(call copy-file-to-target)

$(PRODUCT_OUT)/dtb.img: $(FLOURITE_SOURCE_DIST)/dtb.img
	$(call copy-file-to-target)

.PHONY: kernel
kernel: $(PRODUCT_OUT)/kernel
