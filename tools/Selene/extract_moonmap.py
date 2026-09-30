"""Pulls the menu's moon map out of bin/sprites/ui.mset into moonmap.png,
the input of paint_selene.py. The .mset layout is in docs/MSET-FORMAT.md.

  python extract_moonmap.py [path/to/ui.mset]
"""
import json
import struct
import sys
from pathlib import Path

HeaderSize = 10 # 'MSET', version: word, manifest size: cardinal
SpriteName = 'moonmap'


def extract(mset_path, out_path):
    data = Path(mset_path).read_bytes()
    magic, _version, manifest_size = struct.unpack('<4sHI', data[:HeaderSize])
    if magic != b'MSET':
        raise SystemExit(f'{mset_path}: not a sprite set')
    manifest = json.loads(data[HeaderSize:HeaderSize + manifest_size].decode('utf-8-sig'))
    blob_base = HeaderSize + manifest_size
    for sprite in manifest['sprites']:
        if sprite['name'] == SpriteName:
            start = blob_base + sprite['offset']
            Path(out_path).write_bytes(data[start:start + sprite['size']])
            return
    raise SystemExit(f'{mset_path}: no sprite named {SpriteName}')


if __name__ == '__main__':
    default = Path(__file__).parents[2] / 'bin' / 'sprites' / 'ui.mset'
    extract(sys.argv[1] if len(sys.argv) > 1 else default, 'moonmap.png')
