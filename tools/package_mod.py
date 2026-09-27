"""Stage compiled resources; no source JSON or Bethesda originals in the archive."""
from pathlib import Path
import shutil
import subprocess

ROOT=Path(__file__).resolve().parents[1]
stage=ROOT/'build/deathclaw_badlands/local/deathclaw_badlands'
stage.mkdir(parents=True,exist_ok=True)
for name in ['deathclaw.ent','deathclaw.mesh','deathclaw_d01.xbm','deathclaw_n01.xbm']:
    source=ROOT/'project/source/archive/local/deathclaw_badlands'/name
    assert source.read_bytes()[:4] == b'CR2W', name
    shutil.copy2(source,stage/name)
out=ROOT/'dist/Deathclaw Badlands/archive/pc/mod'
out.mkdir(parents=True,exist_ok=True)
subprocess.run([str(ROOT/'tools/wolvenkit-cli/WolvenKit.CLI.exe'),'pack',str(stage.parents[1]),'-o',str(out)],check=True)
shutil.copytree(ROOT/'project/source/resources',ROOT/'dist/Deathclaw Badlands',dirs_exist_ok=True)
print('Packaged local mod:',ROOT/'dist/Deathclaw Badlands')
