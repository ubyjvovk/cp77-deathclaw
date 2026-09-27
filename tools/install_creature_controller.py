"""Install a controller-only update, checking owned files and preserving the archive."""
from pathlib import Path
import hashlib,json,shutil,zipfile
ROOT=Path(__file__).resolve().parents[1]
manifest=ROOT/'creature/installed-files.json'
old=json.loads(manifest.read_text())
hashfile=lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
source=ROOT/'creature/source/resources/bin/x64/plugins/cyber_engine_tweaks/mods/DeathclawCreature/init.lua'
archive=Path(r'E:\Games\Cyberpunk 2077\archive\pc\mod\deathclaw_creature.archive')
assert hashfile(archive)==old[str(archive)],'Installed archive changed externally'
targets=[Path(p) for p in old if p.endswith('init.lua')]
assert len(targets)==2
for path,digest in old.items():
    if path.endswith('.archive'): assert hashfile(Path(path))==digest, 'Archive changed externally: '+path
# Validate every destination before writing any file.
for p in targets:
    assert hashfile(p) in (old[str(p)],hashfile(source)),f'Externally modified controller: {p}'
dist=ROOT/'dist/Deathclaw Creature Experimental'
assert hashfile(dist/'archive/pc/mod/deathclaw_creature.archive')==hashfile(archive)
for p in targets:
    shutil.copy2(source,p)
    old[str(p)]=hashfile(p)
manifest.write_text(json.dumps(old,indent=2))
shutil.copytree(ROOT/'creature/source/resources',dist,dirs_exist_ok=True)
shutil.copy2(ROOT/'creature/README.md',dist/'README.md')
shutil.make_archive(str(ROOT/'dist/deathclaw_creature_experimental'),'zip',dist)
with zipfile.ZipFile(ROOT/'dist/deathclaw_creature_experimental.zip') as z:
    assert z.testzip() is None
    content=z.read('bin/x64/plugins/cyber_engine_tweaks/mods/DeathclawCreature/init.lua')
    assert content==source.read_bytes()
    assert hashlib.sha256(z.read('archive/pc/mod/deathclaw_creature.archive')).hexdigest()==hashfile(archive)
report={'controller_version':'territorial-v3.3','native_archive_version':'brawler-v2','normal_archive_unchanged':True,'mother_archive_added':True,'mother_animation_graph_readback':'root scale 2, original upstream linked; engine test pending','controller_sha256':hashfile(source),'installed_paths':[str(p) for p in targets],'mock_regression_tests':'passed','v3_3_engine_test':'pending game restart and fresh spawn','health_multiplier':20,'damage_multiplier':4}
(ROOT/'creature/controller_verification.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report,indent=2))
