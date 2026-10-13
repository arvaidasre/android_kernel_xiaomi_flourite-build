#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -Eeuo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
export FLOURITE_KERNEL_SRC=${FLOURITE_KERNEL_SRC:-"$here/../sm7635"}
export FLOURITE_MODULES_SRC=${FLOURITE_MODULES_SRC:-"$here/../flourite-source-modules"}
: "${FLOURITE_CLANG:?Set the clang-r487747c directory}"
: "${FLOURITE_BUILD_TOOLS:?Set the matching kernel build-tools directory}"
: "${FLOURITE_MUSL_SYSROOT:?Set the aarch64-unknown-linux-musl sysroot}"
export FLOURITE_CLANG FLOURITE_BUILD_TOOLS FLOURITE_MUSL_SYSROOT
export PATH="$FLOURITE_CLANG/bin:$FLOURITE_BUILD_TOOLS/bin:$PATH"
python3 "$here/check-inputs.py"
if [[ ${1:-} == --check ]]; then exit 0; fi
if [[ $# != 1 ]]; then
    echo "Usage: bash build.sh --check | NEW_OUTPUT_DIRECTORY" >&2
    exit 2
fi
case "$1" in *[[:space:]]*) echo 'Output path must not contain whitespace' >&2; exit 2 ;; esac
# A fresh output prevents accidental reuse of stock or differently built modules.
mkdir -- "$1"
work=$(cd -- "$1" && pwd)
export FLOURITE_KERNEL_OUT="$work/kernel"
export FLOURITE_MODULES_WORK="$work/modules/qcom/opensource"
mkdir -p "$work/modules" "$FLOURITE_KERNEL_OUT"
git -C "$FLOURITE_MODULES_SRC" archive HEAD | tar -x -C "$work/modules"
export KBUILD_BUILD_USER=lineage KBUILD_BUILD_HOST=flourite
export KBUILD_BUILD_VERSION=1
export KBUILD_BUILD_TIMESTAMP
KBUILD_BUILD_TIMESTAMP=$(git -C "$FLOURITE_KERNEL_SRC" show -s --format=%cD HEAD)
unset KBUILD_MIXED_TREE KBUILD_OUTPUT KCONFIG_CONFIG
source "$here/common.sh"
mapfile -t configs < <(python3 -c 'import json,sys; print("\n".join(json.load(open(sys.argv[1]))["config"]))' "$here/sources.json")
make "${kernel_flags[@]}" "${configs[@]}"
"$FLOURITE_KERNEL_SRC/scripts/config" --file "$FLOURITE_KERNEL_OUT/.config" \
    -e SECURITY_SELINUX_DEVELOP -e IKCONFIG -e IKCONFIG_PROC
make "${kernel_flags[@]}" olddefconfig
make "${kernel_flags[@]}" -j"${FLOURITE_JOBS:-24}" Image modules
while IFS= read -r component; do
    [[ -n $component && $component != \#* ]] || continue
    bash "$here/build-module.sh" "$component"
done < "$here/components.list"
python3 "$here/stage.py" --kernel-out "$FLOURITE_KERNEL_OUT" \
    --modules "$work/modules" --clang "$FLOURITE_CLANG" --output "$work/dist"
