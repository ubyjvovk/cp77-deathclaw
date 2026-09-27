"""Validate compiled NPC resources, stage a separate experimental mod, and install."""
import hashlib,json,shutil,struct,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
CLI=ROOT/'tools/wolvenkit-cli/WolvenKit.CLI.exe'
ARCH=ROOT/'creature/source/archive/local/deathclaw_creature'
INSPECT=ROOT/'work/creature/inspect'
ROUNDTRIP=ROOT/'work/creature/roundtrip'
for p in [INSPECT,ROUNDTRIP]:p.mkdir(parents=True,exist_ok=True)
for name in ['deathclaw_android.ent','deathclaw_android.mesh']:
    subprocess.run([str(CLI),'convert','serialize',str(ARCH/name),'-o',str(INSPECT)],check=True)
subprocess.run([str(CLI),'export',str(ARCH/'deathclaw_android.mesh'),'-o',str(ROUNDTRIP)],check=True)
def read(name):return json.loads(next(INSPECT.rglob(name+'.json')).read_text())['Data']['RootChunk']
mesh=read('deathclaw_android.mesh');ent=read('deathclaw_android.ent')
assert ent['entity']['Data']['$type']=='NPCPuppet'
body=next(c for c in ent['components'] if c.get('name',{}).get('$value')=='protectors')
assert body['mesh']['DepotPath']['$value']==r'local\deathclaw_creature\deathclaw_android.mesh'
def walk(x):
    if isinstance(x,dict):
        yield x
        for v in x.values():yield from walk(v)
    elif isinstance(x,list):
        for v in x:yield from walk(v)
binding=body['skinning']
if 'Data' not in binding:
    binding=next(x for x in walk(ent) if x.get('HandleId')==binding['HandleRefId'] and 'Data' in x)
assert binding['Data']['bindName']['$value']=='deformations'
assert any(c['$type']=='AIHumanComponent' for c in ent['components'])
rigs={c['name']['$value']:c['rig']['DepotPath']['$value'] for c in ent['components'] if c['$type']=='entAnimatedComponent'}
assert rigs['root']==r'base\characters\base_entities\man_big\man_big.rig'
assert rigs['deformations']==r'base\characters\base_entities\man_big\deformations_rigs\man_big_deformations.rig'
animation_refs={x['$value'] for x in walk(ent) if x.get('$type')=='ResourcePath' and str(x.get('$value','')).endswith('.anims')}
assert any('mb_gang_unarmed_action_combat.anims' in x for x in animation_refs)
assert not any('\\android\\' in x for x in animation_refs)
assert len(mesh['boneNames'])==len(mesh['boneRigMatrices'])==len(mesh['renderResourceBlob']['Data']['header']['bonePositions'])==181
assert mesh['materialEntries'][0]['name']['$value']=='deathclaw_skin'
assert not mesh['localMaterialBuffer']['materials']
raw=(ROUNDTRIP/'deathclaw_android.glb').read_bytes();length=struct.unpack_from('<I',raw,12)[0];g=json.loads(raw[20:20+length]);binary=raw[28+length:]
triangles=sum(g['accessors'][p['indices']]['count']//3 for m in g['meshes'] for p in m['primitives']);assert triangles==6930
assert len(g['skins'][0]['joints'])==181
def accessor(i):
    a=g['accessors'][i];v=g['bufferViews'][a['bufferView']]
    fmt={5121:'B',5123:'H',5126:'f'}[a['componentType']];width={'SCALAR':1,'VEC4':4}[a['type']]
    size=struct.calcsize(fmt)*width;offset=v.get('byteOffset',0)+a.get('byteOffset',0)
    return [struct.unpack_from('<'+fmt*width,binary,offset+j*v.get('byteStride',size)) for j in range(a['count'])]
for m in g['meshes']:
    for p in m['primitives']:
        weights=accessor(p['attributes']['WEIGHTS_0']);joints=accessor(p['attributes']['JOINTS_0'])
        assert all(abs(sum(w)-1)<.02 for w in weights)
        assert all(0<=j<181 for row in joints for j in row)
stage=ROOT/'build/deathclaw_creature/local/deathclaw_creature';stage.mkdir(parents=True,exist_ok=True)
for name in ['deathclaw_android.ent','deathclaw_android.mesh','deathclaw_d01.xbm','deathclaw_n01.xbm']:
    assert (ARCH/name).read_bytes()[:4]==b'CR2W';shutil.copy2(ARCH/name,stage/name)
dist=ROOT/'dist/Deathclaw Creature Experimental';out=dist/'archive/pc/mod';out.mkdir(parents=True,exist_ok=True)
subprocess.run([str(CLI),'pack',str(stage.parents[1]),'-o',str(out)],check=True)
shutil.copytree(ROOT/'creature/source/resources',dist,dirs_exist_ok=True)
shutil.copy2(ROOT/'creature/README.md',dist/'README.md')
shutil.make_archive(str(ROOT/'dist/deathclaw_creature_experimental'),'zip',dist)
report={'version':'brawler-v2','compiled_NPC':True,'components':len(ent['components']),'skin_bones':181,'triangles':triangles,
        'rig':'man_big','combat_record':'Character.dtn_animals_bouncer2_melee2_fists_mb',
        'weight_sums_verified':True,'animation_preview':'walk_0_Armature',
        'in_game_mesh_verified':False,'in_game_AI_verified':False,'in_game_damage_verified':False}
(ROOT/'creature/build_verification.json').write_text(json.dumps(report,indent=2))
# This is a new package, never overwrite an existing unrelated file.
manifest=ROOT/'creature/installed-files.json'
old=json.loads(manifest.read_text()) if manifest.exists() else {}
files=[(out/'deathclaw_creature.archive',Path(r'E:\Games\Cyberpunk 2077\archive\pc\mod\deathclaw_creature.archive'))]
script=dist/'bin/x64/plugins/cyber_engine_tweaks/mods/DeathclawCreature/init.lua'
for base in [Path(r'E:\Games\Cyberpunk 2077'),Path(r'E:\Modding\Cyberpunk2077\overwrite')]:
    files.append((script,base/'bin/x64/plugins/cyber_engine_tweaks/mods/DeathclawCreature/init.lua'))
new={}
for src,dst in files:
    h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    if dst.exists() and h(dst)!=h(src) and old.get(str(dst))!=h(dst):raise RuntimeError('Existing modified file: '+str(dst))
    dst.parent.mkdir(parents=True,exist_ok=True)
    if not dst.exists() or h(dst)!=h(src):shutil.copy2(src,dst)
    new[str(dst)]=h(dst)
manifest.write_text(json.dumps(new,indent=2))
print(json.dumps(report));print('Installed separate experimental package; game restart required')
