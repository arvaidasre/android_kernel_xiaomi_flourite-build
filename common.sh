# SPDX-License-Identifier: Apache-2.0
kernel_flags=(
    -C "$FLOURITE_KERNEL_SRC" "O=$FLOURITE_KERNEL_OUT"
    ARCH=arm64 LLVM=1 LLVM_IAS=1 CROSS_COMPILE=aarch64-linux-gnu-
    TARGET_PRODUCT=flourite BOARD_PLATFORM=volcano
    LOCALVERSION=-flourite KCFLAGS=-D__ANDROID_COMMON_KERNEL__
    'HOSTCFLAGS=-O2 -Wno-error=incompatible-pointer-types-discards-qualifiers'
    "USERCFLAGS=--target=aarch64-linux-musl --sysroot=$FLOURITE_MUSL_SYSROOT"
    "USERLDFLAGS=--target=aarch64-linux-musl --sysroot=$FLOURITE_MUSL_SYSROOT -fuse-ld=lld --rtlib=compiler-rt"
)
