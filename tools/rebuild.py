"""Rebuild the local prototype from the already-extracted original assets."""
import json
from pathlib import Path
import shutil
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
WK=ROOT/'tools/wolvenkit-cli/WolvenKit.CLI.exe'
ARCHIVE=ROOT/'project/source/archive'
RAW=ROOT/'project/source/raw'
RES=ARCHIVE/'local/deathclaw_badlands'
INSPECT=ROOT/'work/inspect'
INSPECT.mkdir(parents=True,exist_ok=True)
logdir=ROOT/'work/build-logs'
logdir.mkdir(parents=True,exist_ok=True)
step=0
def run(args, expected=None):
    global step
    step+=1
    result=subprocess.run([str(a) for a in args],cwd=ROOT,text=True,encoding='utf-8',errors='replace',capture_output=True)
    output=result.stdout+'\n'+result.stderr
    (logdir/f'{step:02}.log').write_text(output,encoding='utf-8')
    if expected:
        if expected not in output or '[ 0: Error' in output:
            raise RuntimeError(f'Build step {step} failed; see {logdir}')
    elif result.returncode:
        raise RuntimeError(f'Build step {step} failed; see {logdir}')
    print(f'Completed build step {step}')
def py(name): run([sys.executable,ROOT/'tools'/name])

py('convert_nif.py')
run([r'C:\Program Files\Blender Foundation\Blender 4.3\blender.exe','--background','--python',ROOT/'tools/build_blender.py'],expected='Saved "deathclaw.blend"')
py('build_resources.py')
run([WK,'convert','deserialize',RES/'deathclaw.mesh.json'],expected='to CR2W')
run([WK,'import',RAW,'-o',ARCHIVE],expected='Imported 2/3')
run([WK,'convert','serialize',RES/'deathclaw_d01.xbm',RES/'deathclaw_n01.xbm','-o',INSPECT],expected='to json')
py('fix_texture_settings.py')
run([WK,'convert','deserialize',RES/'deathclaw_d01.xbm.json',RES/'deathclaw_n01.xbm.json'],expected='to CR2W')
run([WK,'import',RAW,'-o',ARCHIVE,'-k'],expected='Imported 3/3')
run([WK,'convert','serialize',*[RES/n for n in ['deathclaw.mesh','deathclaw.ent','deathclaw_d01.xbm','deathclaw_n01.xbm']],'-o',INSPECT],expected='to json')
run([WK,'export',RES/'deathclaw.mesh','-o',ROOT/'work/roundtrip'],expected='Successfully exported')
run([r'C:\Program Files\Blender Foundation\Blender 4.3\blender.exe','--background','--python',ROOT/'tools/render_roundtrip.py'],expected='Compiled mesh:')
py('test_lifecycle.py')
py('package_mod.py')
shutil.copy2(ROOT/'README.md',ROOT/'dist/Deathclaw Badlands/README.md')
py('verify_build.py')
shutil.make_archive(str(ROOT/'dist/deathclaw_badlands_local_dev'),'zip',ROOT/'dist/Deathclaw Badlands')
print('Build complete. Use install_local.py with the game closed to update the local installation.')
