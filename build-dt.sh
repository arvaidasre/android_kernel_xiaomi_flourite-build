#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -Eeuo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
work=${1:?New DT output directory required}
top=${FLOURITE_ANDROID_TOP:?Set the Lineage source root}
mkdir "$work"
mkdir "$work/tools" "$work/base" "$work/techpack" "$work/merged"
# Build host overlay tools with LLVM and the checkout's libfdt archive.
tar -C "$top/external/dtc" --exclude=.git -cf - . | tar -x -C "$work/tools"
make -C "$work/tools" -j"${FLOURITE_JOBS:-24}" \
    PKG_CONFIG=false NO_PYTHON=1 NO_YAML=1 NO_VALGRIND=1 \
    CC="$FLOURITE_CLANG/bin/clang" AR="$FLOURITE_CLANG/bin/llvm-ar" \
    LDFLAGS=-fuse-ld=lld LIBFDT_dep=libfdt/libfdt.a EXTRA_CFLAGS=-Wno-error=sign-compare \
    fdtget fdtput fdtoverlay fdtoverlaymerge
ufdt="$top/system/libufdt"
"$FLOURITE_CLANG/bin/clang" -O2 -fuse-ld=lld -I"$ufdt/include" -I"$ufdt/sysdeps/include" \
    -I"$work/tools/libfdt" "$ufdt/ufdt_overlay.c" "$ufdt/ufdt_convert.c" \
    "$ufdt/ufdt_node.c" "$ufdt/ufdt_node_pool.c" "$ufdt/ufdt_prop_dict.c" \
    "$ufdt/sysdeps/libufdt_sysdeps_posix.c" "$ufdt/tests/src/ufdt_overlay_test_app.c" \
    "$ufdt/tests/src/util.c" "$work/tools/libfdt/libfdt.a" -o "$work/tools/ufdt_apply_overlay"
export PATH="$work/tools:$PATH" PYTHONHASHSEED=0
source "$here/common.sh"
mapfile -t trees < "$here/dt-sources.list"
targets=()
for tree in "${trees[@]}"; do targets+=("vendor/qcom/$tree"); done
includes="$FLOURITE_KERNEL_SRC/scripts/dtc/include-prefixes"
includes+=" $FLOURITE_MODULES_SRC/qcom/opensource/audio-kernel/include"
includes+=" $FLOURITE_MODULES_SRC/qcom/opensource/camera-kernel"
make "${kernel_flags[@]}" -j"${FLOURITE_JOBS:-24}" DTC_FLAGS=-@ \
    "DTC_INCLUDE=$includes" "${targets[@]}"
for tree in "${trees[@]}"; do
    case "$tree" in */*) target=techpack ;; *) target=base ;; esac
    cp "$FLOURITE_KERNEL_OUT/arch/arm64/boot/dts/vendor/qcom/$tree" "$work/$target/"
done
"${FLOURITE_PYTHON:-python3}" "$top/vendor/lineage/build/tools/merge_dtbs.py" \
    --base "$work/base" --techpack "$work/techpack" --out "$work/merged"
# Verify the final overlay for each supported base using libfdt too.
"${FLOURITE_PYTHON:-python3}" "$here/package-dt.py" "$work/merged" "$work" \
    "$top/system/libufdt/utils/src/mkdtboimg.py"
