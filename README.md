# Flourite source kernel

Pinned Xiaomi 6.1 kernel and external modules for the unified LineageOS device.
The kernel and all packaged `.ko` files are built together; there is no stock
module fallback. DTB/DTBO remain the tested OS3.0.306 firmware versions.
Proprietary userspace and device firmware are still required.

## Build

Use the revisions in `sources.json`. The module branch is currently local;
it must be published separately before a fresh remote checkout can reproduce it.
Dependencies: make, Python 3 with pyelftools, Git, tar, flex, bison, OpenSSL
development headers, Android Clang r487747c, kernel build-tools (pahole 1.23),
and the Lineage build-tools aarch64 musl sysroot.

```sh
export FLOURITE_CLANG=/path/to/clang-r487747c
export FLOURITE_BUILD_TOOLS=/path/to/kernel-build-tools
export FLOURITE_MUSL_SYSROOT=/path/to/lineage/prebuilts/build-tools/sysroots/aarch64-unknown-linux-musl
bash build.sh --check
bash build.sh /path/to/new-kernel-output
```

`FLOURITE_KERNEL_SRC`, `FLOURITE_MODULES_SRC` override the sibling source paths;
`FLOURITE_JOBS` defaults to 24. Use a new output directory for each build.
Module signatures use the matching build's generated key. Never publish that key.

## Lineage integration

After building, verify `dist/SHA256SUMS` and set
`FLOURITE_SOURCE_KERNEL_DIST := /path/to/new-kernel-output/dist` in a local
BoardConfig override. The device tree's opt-in include consumes the whole bundle.
The stock kernel remains the default until an integrated ROM has been tested.

This preparation does not yet compile the kernel automatically during `m bacon`.
Android creates its own boot/recovery images and dependency metadata from the
distribution, retaining normal init and SELinux enforcing. No diagnostic init,
logger, permissive policy, flash script or private signing key is installed.
