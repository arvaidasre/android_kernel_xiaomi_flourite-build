# Flourite source kernel

Google Android 14 ACK 6.1 with Flourite drivers and device trees. The kernel,
all packaged modules, DTB and DTBO are compiled together. There is no Xiaomi
prebuilt kernel or stock module/device-tree fallback. Proprietary userspace
and device firmware are still required.

## Lineage build

Use the revisions in `sources.json` at these checkout paths:

- `kernel/xiaomi/sm7635`
- `kernel/xiaomi/flourite-source-modules`
- `kernel/xiaomi/sm7635-devicetrees`
- `kernel/xiaomi/flourite-build` (this repository)

Install Android Clang r487747c at `kernel/prebuilts/clang-r487747c` and the
matching kernel build-tools (pahole 1.23) at `kernel/prebuilts/build-tools-2023`.
The Lineage checkout supplies `external/dtc`, `system/libufdt`, the overlay
merge tool and the build-tools aarch64 musl sysroot. Host dependencies include
make, Git, tar, flex, bison, OpenSSL development headers and Python 3 with
pyelftools available to `/usr/bin/python3`.

The device tree includes `BoardConfigLineage.mk` and `lineage.mk`. Normal
`m bacon` builds the kernel bundle before consuming its outputs. `m kernel`
builds the same bundle without producing an OTA. Outputs are under
`out/target/product/flourite/obj/FLOURITE_KERNEL/dist`.

Android creates boot/recovery images and module dependency metadata using
normal init and SELinux enforcing. The build installs no diagnostic logger,
permissive policy or private signing key. Keep input repositories clean and
update `sources.json` when committing a kernel, module or device-tree change.

## Standalone build

```sh
export FLOURITE_CLANG=/path/to/clang-r487747c
export FLOURITE_BUILD_TOOLS=/path/to/kernel-build-tools
export FLOURITE_ANDROID_TOP=/path/to/lineage
export FLOURITE_MUSL_SYSROOT=$FLOURITE_ANDROID_TOP/prebuilts/build-tools/sysroots/aarch64-unknown-linux-musl
bash build.sh --check
bash build.sh /path/to/new-kernel-output
```

`FLOURITE_KERNEL_SRC`, `FLOURITE_MODULES_SRC` and `FLOURITE_DTS_SRC` override
the sibling source paths. `FLOURITE_JOBS` defaults to 24. Each invocation uses
a fresh output directory and verifies module architecture, symbol versions
and dependency coverage. Device-tree overlays are merged and applied to all
three supported base trees before packaging.

Verify `dist/SHA256SUMS` before using standalone outputs. Module signatures
use the matching build's generated key; never publish that private key.
