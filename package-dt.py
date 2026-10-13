#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Package and validate the Flourite source device trees."""
from pathlib import Path
import struct
import subprocess
import sys


def cells(path, prop):
    result = subprocess.check_output(['fdtget', '-t', 'u', str(path), '/', prop], text=True)
    return tuple(int(v) for v in result.split())


def package(merged, output, mkdtbo):
    bases = sorted(merged.glob('*.dtb'))
    overlays = sorted(merged.glob('*.dtbo'))
    expected = {(636, 65536), (640, 65536), (641, 65536)}
    if {cells(p, 'qcom,msm-id') for p in bases} != expected or len(bases) != 3:
        raise ValueError('Unexpected Flourite base DT selection')
    used = set()
    for base in bases:
        key = cells(base, 'qcom,msm-id')
        matches = []
        for overlay in overlays:
            ids = cells(overlay, 'qcom,msm-id')
            if key in list(zip(ids[::2], ids[1::2])):
                matches.append(overlay)
        if len(matches) != 1:
            raise ValueError(f'Ambiguous or missing overlay for {base.name}')
        overlay = matches[0]
        if cells(overlay, 'qcom,board-id') != (8, 0) or cells(overlay, 'xiaomi,miboard-id') != (14, 0):
            raise ValueError('Unexpected board selector')
        subprocess.run(['fdtoverlay', '-i', str(base), '-o', '/dev/null', str(overlay)], check=True)
        used.add(overlay)
    (output / 'dtb.img').write_bytes(b''.join(p.read_bytes() for p in bases))
    # Entries that have no matching base are intentionally excluded.
    subprocess.run([sys.executable, str(mkdtbo), 'create', str(output / 'dtbo.img'),
                    '--page_size=4096', '--version=0', *map(str, sorted(used))], check=True)
    header = struct.unpack('>8I', (output / 'dtbo.img').read_bytes()[:32])
    if header[0] != 0xd7b7ab1e or header[4] != len(used) or header[6:] != (4096, 0):
        raise ValueError('Invalid DTBO header')
    print(f'Validated {len(bases)} base trees and {len(used)} Flourite overlays')


if __name__ == '__main__':
    package(*(Path(p).resolve() for p in sys.argv[1:]))
