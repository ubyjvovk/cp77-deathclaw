"""Build an isolated NPC prototype using the boxing android as donor."""
import copy,json,subprocess,shutil
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
DONOR=ROOT/'work/creature/donor'
OUT=ROOT/'creature/source/archive/local/deathclaw_creature'
OUT.mkdir(parents=True,exist_ok=True)
def cn(v):return {'$type':'CName','$storage':'string','$value':v}
def ref(v):return {'DepotPath':{'$type':'ResourcePath','$storage':'string','$value':v},'Flags':'Default'}
def walk(x):
    if isinstance(x,dict):
        yield x
        for v in x.values():yield from walk(v)
    elif isinstance(x,list):
        for v in x:yield from walk(v)
def save(d,name):
    d['Header']['ArchiveFileName']=str(OUT/name)
    (OUT/(name+'.json')).write_text(json.dumps(d,indent=2))

donor=json.loads(next(DONOR.rglob('ndr_02_ma__full_padded.mesh.json')).read_text())
static=json.loads((ROOT/'project/source/archive/local/deathclaw_badlands/deathclaw.mesh.json').read_text())['Data']['RootChunk']
m=donor['Data']['RootChunk']
for field in ['appearances','materialEntries','preloadLocalMaterialInstances','localMaterialBuffer','localMaterialInstances']:
    m[field]=copy.deepcopy(static[field])
# Use fresh IDs for material handles, avoiding aliases into donor metadata.
for i,x in enumerate(walk({k:m[k] for k in ['appearances','preloadLocalMaterialInstances']})):
    if 'HandleId' in x:x['HandleId']=str(900000+i)
    if x.get('$type')=='ResourcePath' and str(x.get('$value','')).startswith('local\\deathclaw_badlands\\'):
        x['$value']=x['$value'].replace('local\\deathclaw_badlands\\','local\\deathclaw_creature\\')
for name in ['deathclaw_d01.xbm','deathclaw_n01.xbm']:
    shutil.copy2(ROOT/'project/source/archive/local/deathclaw_badlands'/name,OUT/name)
m['parameters']=[]
for field in ['externalMaterials','preloadExternalMaterials','localMaterialBuffer']:
    if field in m:
        if isinstance(m[field],list):m[field]=[]
m['lodLevelInfo']=[0]
rig=json.loads(next(DONOR.rglob('man_big_deformations.rig.json')).read_text())['Data']['RootChunk']
m['boneNames']=rig['boneNames']
bind=json.loads((ROOT/'work/creature/android_bind_matrices.json').read_text())
m['boneRigMatrices']=[{'$type':'Matrix',**{axis:{'$type':'Vector4',**dict(zip('XYZW',row))} for axis,row in zip('XYZW',bind[b['$value']]['inverse'])}} for b in m['boneNames']]
m['renderResourceBlob']['Data']['header']['bonePositions']=[{'$type':'Vector4','W':1,**dict(zip('XYZ',bind[b['$value']]['position']))} for b in m['boneNames']]
m['boneVertexEpsilons']=[1.0]*len(m['boneNames'])
m['lodBoneMask']=[1]*len(m['boneNames'])
save(donor,'deathclaw_android.mesh')

subprocess.run(['dotnet','run','--project',str(ROOT/'tools/CreatureEntityBuilder'),'--',
                str(next(DONOR.rglob('gang__animals_mb.ent'))),str(OUT/'deathclaw_android.ent')],check=True)
subprocess.run([str(ROOT/'tools/wolvenkit-cli/WolvenKit.CLI.exe'),'convert','serialize',str(OUT/'deathclaw_android.ent')],check=True)
print('Built unique NPC and skinned mesh templates; no base-game replacements')
