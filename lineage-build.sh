#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -Eeuo pipefail
top=$(realpath "${1:?Android source root required}")
output=$(realpath -m "${2:?Kernel output directory required}")
[[ $output == */target/product/flourite/obj/FLOURITE_KERNEL ]] || {
    echo 'Unexpected Flourite kernel output path' >&2
    exit 2
}
here="$top/kernel/xiaomi/flourite-build"
export FLOURITE_KERNEL_SRC="$top/kernel/xiaomi/sm7635"
export FLOURITE_MODULES_SRC="$top/kernel/xiaomi/flourite-source-modules"
export FLOURITE_DTS_SRC="$top/kernel/xiaomi/sm7635-devicetrees"
export FLOURITE_ANDROID_TOP="$top"
export FLOURITE_CLANG="$top/kernel/prebuilts/clang-r487747c"
export FLOURITE_BUILD_TOOLS="$top/kernel/prebuilts/build-tools-2023"
export FLOURITE_MUSL_SYSROOT="$top/prebuilts/build-tools/sysroots/aarch64-unknown-linux-musl"
export FLOURITE_JOBS=24
# Use the host Python with pyelftools, not Android's build-tool interpreter.
export FLOURITE_PYTHON=/usr/bin/python3
bash "$here/build.sh" --check
if [[ ${3:-} == --check ]]; then exit 0; fi
[[ $# == 2 ]] || exit 2
mkdir -p "$output/work" "$output/dist"
exec 9>"$output/.build.lock"
flock 9
work=$(mktemp -d "$output/work/build.XXXXXX")
bash "$here/build.sh" "$work/output"
(cd "$work/output/dist" && sha256sum --status -c SHA256SUMS)
# Consumers depend on the stamp; a failed build never publishes partial modules.
cp -a "$work/output/dist/." "$output/dist/"
touch "$output/.built"
