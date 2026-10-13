#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Validate and stage a matched kernel and source-module distribution."""
import argparse
from collections import defaultdict
import hashlib
from pathlib import Path
import shutil
import struct
import subprocess
import tempfile

from elftools.elf.elffile import ELFFile


def require(ok, message):
    if not ok:
        raise ValueError(message)


def names(path):
    return [line.strip() for line in path.read_text().splitlines()
            if line.strip() and not line.lstrip().startswith('#')]


def module_info(path):
    with path.open('rb') as stream:
        elf = ELFFile(stream)
        require(elf.elfclass == 64 and elf.little_endian and
                elf['e_machine'] == 'EM_AARCH64', f'Unexpected module architecture: {path}')
        modinfo = elf.get_section_by_name('.modinfo')
        require(modinfo is not None, f'Missing module metadata: {path}')
        info = dict(item.decode().split('=', 1) for item in modinfo.data().split(b'\0')
                    if b'=' in item)
        section = elf.get_section_by_name('__versions')
        require(section is not None, f'Missing symbol versions: {path}')
        data = section.data()
        require(len(data) % 64 == 0, f'Invalid symbol versions: {path}')
        versions = {data[i + 8:i + 64].split(b'\0')[0].decode():
                    struct.unpack_from('<Q', data, i)[0] for i in range(0, len(data), 64)}
        undefined = [symbol.name for symbol in elf.get_section_by_name('.symtab').iter_symbols()
                     if symbol['st_shndx'] == 'SHN_UNDEF' and symbol['st_info']['bind'] == 'STB_GLOBAL']
        return info, versions, undefined


def validate(kernel, modules, here):
    release = (kernel / 'include/config/kernel.release').read_text().strip()
    config = set((kernel / '.config').read_text().splitlines())
    require('CONFIG_SECURITY_SELINUX=y' in config, 'SELinux must be enabled')
    require('CONFIG_MODULE_SIG=y' in config, 'Module signing must be enabled')
    require('CONFIG_MODULE_SIG_PROTECT=y' in config, 'Keep module signature protection')
    require('CONFIG_MODULE_FORCE_LOAD=y' not in config, 'Forced module loading is not allowed')
    require((kernel / 'arch/arm64/boot/Image').is_file(), 'Missing Image')
    built = defaultdict(list)
    for root in (kernel, modules):
        for path in root.rglob('*.ko'):
            built[path.name].append(path)
    groups = {group: names(here / ('modules.list.' + group))
              for group in ('system_dlkm', 'vendor_dlkm', 'vendor_ramdisk')}
    selected = {}
    for group, wanted in groups.items():
        require(len(wanted) == len(set(wanted)), f'Duplicate module in {group}')
        for name in wanted:
            require(Path(name).name == name and name.endswith('.ko'), f'Invalid name: {name}')
            require(len(built[name]) == 1, f'Missing or ambiguous source module: {name}')
            selected[name] = built[name][0]
        loads = [group, 'recovery'] if group == 'vendor_ramdisk' else [group]
        for load in loads:
            require(set(names(here / ('modules.load.' + load))) <= set(wanted),
                    f'Unpackaged module in {load} load list')
    exports = {}
    for table in [kernel / 'Module.symvers', *sorted(modules.rglob('Module.symvers'))]:
        for line in table.read_text().splitlines():
            crc, symbol, provider, *_ = line.split()
            provider = 'vmlinux' if provider == 'vmlinux' else Path(provider).name + '.ko'
            entry = (int(crc, 16), provider)
            require(symbol not in exports or exports[symbol] == entry,
                    f'Conflicting export: {symbol}')
            exports[symbol] = entry
    dependencies = {}
    for name, path in selected.items():
        info, versions, undefined = module_info(path)
        require(info['vermagic'].split()[0] == release, f'Kernel release mismatch: {name}')
        dependencies[name] = set()
        for symbol in undefined + ['module_layout']:
            require(symbol in exports, f'Missing export: {name}: {symbol}')
            crc, provider = exports[symbol]
            require(versions.get(symbol) == crc, f'Symbol CRC mismatch: {name}: {symbol}')
            require(provider == 'vmlinux' or provider in selected,
                    f'Unpackaged dependency: {name}: {provider}')
            if provider != 'vmlinux':
                dependencies[name].add(provider)
    def closure(initial):
        result = set(initial)
        while True:
            expanded = result | set().union(*(dependencies[name] for name in result))
            if expanded == result:
                return result
            result = expanded

    resident = closure(names(here / 'modules.load.vendor_ramdisk'))
    require(resident <= set(groups['vendor_ramdisk']), 'First-stage dependency is not in ramdisk')
    require(closure(names(here / 'modules.load.recovery')) <= set(groups['vendor_ramdisk']),
            'Recovery dependency is not in ramdisk')
    for group, wanted in groups.items():
        if group == 'vendor_ramdisk':
            continue  # Only the early/recovery load lists must be self-contained.
        available = set(wanted)
        available.update(resident)
        if group == 'vendor_dlkm':
            available.update(groups['system_dlkm'])
        for name in wanted:
            require(dependencies[name] <= available,
                    f'Dependency unavailable in {group}: {name}: {dependencies[name] - available}')
    print(f'Verified {len(selected)} source modules for {release}')
    return release, groups, selected


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--kernel-out', type=Path, required=True)
    parser.add_argument('--modules', type=Path, required=True)
    parser.add_argument('--clang', type=Path)
    parser.add_argument('--output', type=Path)
    parser.add_argument('--check-only', action='store_true')
    args = parser.parse_args()
    here = Path(__file__).resolve().parent
    kernel = args.kernel_out.resolve()
    release, groups, selected = validate(kernel, args.modules.resolve(), here)
    if args.check_only:
        return
    require(args.output is not None and args.clang is not None, '--output and --clang required')
    output = args.output.resolve()
    require(not output.exists(), 'Refusing to overwrite an existing distribution')
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='.flourite-dist-', dir=output.parent) as scratch:
        stage = Path(scratch) / 'dist'
        stage.mkdir()
        for group, wanted in groups.items():
            target = stage / group
            target.mkdir()
            for name in wanted:
                shutil.copyfile(selected[name], target / name)
                subprocess.run([args.clang / 'bin/llvm-strip', '--strip-debug', target / name], check=True)
                subprocess.run([kernel / 'scripts/sign-file', 'sha256',
                                kernel / 'certs/signing_key.pem', kernel / 'certs/signing_key.x509',
                                target / name], check=True)
        for path in here.glob('modules.*'):
            shutil.copyfile(path, stage / path.name)
        for source, dest in [('arch/arm64/boot/Image', 'Image'), ('System.map', 'System.map'),
                             ('.config', 'kernel.config'), ('certs/signing_key.x509', 'module-cert.x509')]:
            shutil.copyfile(kernel / source, stage / dest)
        for filename in ('BoardConfigKernel.mk', 'sources.json'):
            shutil.copyfile(here / filename, stage / filename)
        (stage / 'kernel.release').write_text(release + '\n')
        hashes = [hashlib.sha256(p.read_bytes()).hexdigest() + '  ' + str(p.relative_to(stage))
                  for p in sorted(stage.rglob('*')) if p.is_file()]
        (stage / 'SHA256SUMS').write_text('\n'.join(hashes) + '\n')
        stage.rename(output)
    print(f'Distribution ready: {output}')


if __name__ == '__main__':
    main()
