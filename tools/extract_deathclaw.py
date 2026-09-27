"""Extract only Deathclaw assets from the user's local New Vegas BSAs."""
import hashlib
import json
from pathlib import Path
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
DATA = Path(r'E:\SteamLibrary\steamapps\common\Fallout New Vegas enplczru\Data')

def extract(archive):
    records = []
    with archive.open('rb') as f:
        magic, version, offset, flags, folders, files, folder_len, name_len, types = struct.unpack('<4s8I', f.read(36))
        assert magic == b'BSA\x00' and version == 104, (magic, version)
        f.seek(offset)
        folder_records = [struct.unpack('<QII', f.read(16)) for _ in range(folders)]
        for _, count, _ in folder_records:
            length = f.read(1)[0]
            folder = f.read(length).rstrip(b'\x00').decode('cp1252')
            for _ in range(count):
                _, size, pos = struct.unpack('<QII', f.read(16))
                records.append((folder, size, pos))
        names = f.read(name_len).split(b'\x00')
        assert len(records) == files
        results = []
        for (folder, size, pos), name in zip(records, names):
            relative = folder + '/' + name.decode('cp1252')
            if 'deathclaw' not in relative.lower():
                continue
            target = ROOT / 'source' / relative.replace('\\', '/')
            assert target.resolve().is_relative_to((ROOT / 'source').resolve())
            f.seek(pos)
            payload = f.read(size & 0x3fffffff)
            if flags & 0x100:
                payload = payload[1 + payload[0]:]
            if bool(flags & 4) != bool(size & 0x40000000):
                expected = struct.unpack('<I', payload[:4])[0]
                payload = zlib.decompress(payload[4:])
                assert len(payload) == expected
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(payload)
            results.append(dict(archive=archive.name, path=relative, bytes=len(payload), sha256=hashlib.sha256(payload).hexdigest()))
            print(relative, len(payload))
        return results

if __name__ == '__main__':
    records = []
    for name in ['Fallout - Meshes.bsa', 'Fallout - Textures.bsa', 'Fallout - Textures2.bsa']:
        records.extend(extract(DATA / name))
    (ROOT / 'source_manifest.json').write_text(json.dumps(records, indent=2))
