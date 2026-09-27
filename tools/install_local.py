"""Install only this project's owned files, with a MO2 CET runtime copy."""
import hashlib
import json
from pathlib import Path
import shutil

ROOT=Path(__file__).resolve().parents[1]
GAME=Path(r'E:\Games\Cyberpunk 2077')
MO=Path(r'E:\Modding\Cyberpunk2077')
DIST=ROOT/'dist/Deathclaw Badlands'
manifest=ROOT/'installed-files.json'
old=json.loads(manifest.read_text(encoding='utf-8-sig')) if manifest.exists() else []
owned={str(Path(e['target'])).lower():e['sha256'].lower() for e in old}
sources=[p for p in DIST.rglob('*') if p.is_file() and p.name!='README.md']
operations=[(p,GAME/p.relative_to(DIST)) for p in sources]
cet=Path('bin/x64/plugins/cyber_engine_tweaks/mods/DeathclawBadlands/init.lua')
operations.append((DIST/cet,MO/'overwrite'/cet))
entries=[]
for source,target in operations:
    wanted=hashlib.sha256(source.read_bytes()).hexdigest()
    if target.exists():
        current=hashlib.sha256(target.read_bytes()).hexdigest()
        if current!=wanted and owned.get(str(target).lower())!=current:
            raise RuntimeError(f'Unowned or externally changed file: {target}')
    entries.append(dict(source=str(source),target=str(target),sha256=wanted))
for e in entries:
    target=Path(e['target'])
    target.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(e['source'],target)
manifest.write_text(json.dumps(entries,indent=2))
print(f'Installed {len(entries)} project-owned files; recorded in {manifest}')
