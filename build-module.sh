#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -Eeuo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$here/common.sh"
modules=$FLOURITE_MODULES_WORK
component=${1:?module component required}
grep -Fxq "$component" "$here/components.list"
module_dir="$modules/$component"
test -d "$module_dir"
extra_symbols=()
while IFS= read -r symbols; do
    case "$symbols" in "$module_dir"/*) continue ;; esac
    extra_symbols+=("$symbols")
done < <(find "$modules" -name Module.symvers -type f | LC_ALL=C sort)
flags=("${kernel_flags[@]}" "M=$module_dir"
    "KERNEL_SRC=$FLOURITE_KERNEL_SRC" "KERNEL_ROOT=$FLOURITE_KERNEL_SRC"
    "KBUILD_EXTRA_SYMBOLS=${extra_symbols[*]}")
case "$component" in
    datarmnet-ext/*) flags+=("RMNET_CORE_INC_DIR=$modules/datarmnet/core"
        "DATARMNET_CORE_PATH=$modules/datarmnet/core") ;;
    securemsm-kernel) flags+=("SSG_MODULE_ROOT=$module_dir") ;;
    mmrm-driver) flags+=("MMRM_ROOT=$module_dir") ;;
    mm-drivers/msm_ext_display) flags+=("MSM_EXT_DISPLAY_ROOT=$modules/mm-drivers") ;;
    mm-drivers/hw_fence) flags+=("MSM_HW_FENCE_ROOT=$modules/mm-drivers/") ;;
    mm-drivers/sync_fence) flags+=("SYNC_FENCE_ROOT=$modules/mm-drivers/") ;;
    synx-kernel) flags+=("SYNX_ROOT=$module_dir" "SYNX_DIR=$module_dir") ;;
    display-drivers) flags+=("DISPLAY_ROOT=$module_dir" CONFIG_DRM_MSM=m) ;;
    audio-kernel) flags+=("AUDIO_ROOT=$module_dir" MODNAME=audio_dlkm) ;;
    camera-kernel)
        make -C "$module_dir" cam_generated_h
        flags+=("CAMERA_KERNEL_ROOT=$module_dir") ;;
    dsp-kernel) flags+=("DSP_ROOT=$module_dir") ;;
    touch-drivers) flags+=("TOUCH_ROOT=$module_dir" CONFIG_MSM_TOUCH=m) ;;
    graphics-kernel) flags+=("KGSL_PATH=$module_dir" CONFIG_QCOM_KGSL=m) ;;
    video-driver) flags+=("VIDEO_ROOT=$module_dir") ;;
    bt-kernel) flags+=("BT_ROOT=$module_dir" CONFIG_MSM_BT_POWER=m CONFIG_BT_HW_SECURE_DISABLE=y
        CONFIG_BTFM_SLIM=m CONFIG_I2C_RTC6226_QCA=m) ;;
    wlan/platform)
        flags+=("WLAN_PLATFORM_ROOT=$module_dir" CONFIG_CNSS_OUT_OF_TREE=y
            CONFIG_ICNSS2=m CONFIG_ICNSS2_QMI=y CONFIG_ICNSS2_DEBUG=y
            CONFIG_CNSS_QMI_SVC=m CONFIG_WCNSS_MEM_PRE_ALLOC=m
            CONFIG_CNSS_UTILS=m CONFIG_CNSS_GENL=m) ;;
    wlan/qcacld-3.0)
        flags+=("WLAN_ROOT=$module_dir" MODNAME=qca_cld3_qca6750 CONFIG_QCA_CLD_WLAN=m
            WLAN_PROFILE=volcano_gki_qca6750 DYNAMIC_SINGLE_CHIP=qca6750 WLAN_CTRL_NAME=wlan
            CONFIG_CNSS_OUT_OF_TREE=y CONFIG_QCA_WIFI_ISOC=0 CONFIG_QCA_WIFI_2_0=1
            "WLAN_COMMON_INC=$modules/wlan/qca-wifi-host-cmn"
            WLAN_COMMON_ROOT=../qca-wifi-host-cmn "WLAN_FW_API=$modules/wlan/fw-api"
            "WLAN_PLATFORM_INC=$modules/wlan/platform/inc"
            "DATA_IPA_INC=$modules/dataipa/drivers/platform/msm/include"
            "DATA_IPA_UAPI_INC=$modules/dataipa/drivers/platform/msm/include/uapi") ;;
esac
make "${flags[@]}" -j"${FLOURITE_JOBS:-24}" modules
