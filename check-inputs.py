#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
import json
import os
from pathlib import Path
import subprocess

from elftools.elf.elffile import ELFFile  # Required by the distribution builder.

here = Path(__file__).resolve().parent
lock = json.loads((here / 'sources.json').read_text())
for name, env in (('kernel', 'FLOURITE_KERNEL_SRC'), ('modules', 'FLOURITE_MODULES_SRC'),
                  ('devicetrees', 'FLOURITE_DTS_SRC')):
    path = Path(os.environ[env]).resolve()
    if any(c.isspace() for c in str(path)):
        raise SystemExit('Kernel build paths must not contain whitespace')
    def git(*args):
        return subprocess.check_output(['git', '-C', str(path), *args], text=True).strip()
    if git('rev-parse', 'HEAD') != git('rev-parse', lock[name]['revision']):
        raise SystemExit(f'{name}: revision differs from sources.json')
    if git('status', '--porcelain', '--untracked-files=normal'):
        raise SystemExit(f'{name}: commit or preserve local changes before building')
    print(f'{name}: {git("rev-parse", "HEAD")}')
clang = Path(os.environ['FLOURITE_CLANG'])
if f'based on {lock["clang"]}' not in (clang / 'AndroidVersion.txt').read_text():
    raise SystemExit('Unexpected Clang version')
for tool in ('clang', 'ld.lld', 'llvm-strip'):
    if not os.access(clang / 'bin' / tool, os.X_OK):
        raise SystemExit(f'Missing compiler tool: {tool}')
for tool in ('pahole', 'depmod'):
    if not os.access(Path(os.environ['FLOURITE_BUILD_TOOLS']) / 'bin' / tool, os.X_OK):
        raise SystemExit(f'Missing build tool: {tool}')
if not (Path(os.environ['FLOURITE_MUSL_SYSROOT']) / 'include').is_dir():
    raise SystemExit('Missing musl sysroot')
top = Path(os.environ['FLOURITE_ANDROID_TOP'])
for relative in ('external/dtc/Makefile', 'system/libufdt/ufdt_overlay.c',
                 'system/libufdt/utils/src/mkdtboimg.py',
                 'vendor/lineage/build/tools/merge_dtbs.py'):
    if not (top / relative).is_file():
        raise SystemExit(f'Missing Lineage DT build input: {relative}')
module_root = Path(os.environ['FLOURITE_MODULES_SRC']) / 'qcom/opensource'
for component in (here / 'components.list').read_text().splitlines():
    if not (module_root / component).is_dir():
        raise SystemExit(f'Missing component: {component}')
print('Inputs verified; no compilation performed')
