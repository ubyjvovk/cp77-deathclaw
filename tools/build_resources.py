import copy
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'project/source/archive/local/deathclaw_badlands'
OUT.mkdir(parents=True, exist_ok=True)
def cname(value):
    return {'$type':'CName', '$storage':'string', '$value':value}
def ref(value):
    return {'DepotPath':{'$type':'ResourcePath','$storage':'string','$value':value},'Flags':'Default'}
def save(data, name):
    data['Header']['ArchiveFileName'] = str(OUT / name)
    (OUT / (name+'.json')).write_text(json.dumps(data, indent=2))

mesh = json.loads(next((ROOT/'template').rglob('*.mesh.json')).read_text())
m = mesh['Data']['RootChunk']
m['appearances'] = [{'HandleId':'0','Data':{'$type':'meshMeshAppearance','name':cname('default'),'chunkMaterials':[cname('deathclaw_skin')],'tags':[]}}]
m['materialEntries'] = [{'$type':'CMeshMaterialEntry','index':0,'isLocalInstance':1,'name':cname('deathclaw_skin')}]
m['preloadLocalMaterialInstances'] = [{'HandleId':'6','Data':{
    '$type':'CMaterialInstance','baseMaterial':ref(r'engine\materials\metal_base.remt'),
    'enableMask':0,'resourceVersion':4,
    'values':[{'$type':'rRef:ITexture','BaseColor':ref(r'local\deathclaw_badlands\deathclaw_d01.xbm')},
              {'$type':'rRef:ITexture','Normal':ref(r'local\deathclaw_badlands\deathclaw_n01.xbm')},
              {'$type':'Float','RoughnessScale':0.85},
              {'$type':'Float','MetalnessScale':0.0}]}}]
body = m['parameters'][0]['Data']['physicsData']['Data']['bodies'][0]['Data']
template_shape = copy.deepcopy(body['collisionShapes'][0]['Data'])
body['collisionShapes'] = []
for i, (center, half) in enumerate([
    ((-0.55,0.4,1.9), (0.50,0.43,0.60)),
    ((-0.55,0.12,0.65), (0.22,0.30,0.65)),
    ((0.06,0.77,0.65), (0.22,0.30,0.65)),
    ((-1.40,0.12,2.4), (0.42,0.26,0.26)),
]):
    shape = copy.deepcopy(template_shape)
    shape['$type'] = 'physicsColliderBox'
    for key in ['compiledGeometryBuffer','faceMaterials','isImported','unk1','unk2']:
        shape.pop(key, None)
    shape['halfExtents'] = dict(zip(['$type','X','Y','Z'], ['Vector3',*half]))
    shape['localToBody']['position'] = dict(zip(['$type','W','X','Y','Z'], ['Vector4',0,*center]))
    shape['localToBody']['orientation'] = {'$type':'Quaternion','i':0,'j':0,'k':0,'r':1}
    shape['filterData']['HandleId'] = str(101+i*2)
    body['collisionShapes'].append({'HandleId':str(100+i*2),'Data':shape})
body['localToModel']['position'] = {'$type':'Vector4','W':0,'X':0,'Y':0,'Z':0}
m['lodLevelInfo'] = [0]
save(mesh, 'deathclaw.mesh')

with (ROOT/'work/entity-build.log').open('w') as log:
    subprocess.run(['dotnet','run','--project',str(ROOT/'tools/EntityBuilder'),'--',str(OUT/'deathclaw.ent')],
                   stdout=log,stderr=subprocess.STDOUT,check=True)
subprocess.run([str(ROOT/'tools/wolvenkit-cli/WolvenKit.CLI.exe'),'convert','serialize',str(OUT/'deathclaw.ent')],check=True)
print('Wrote Deathclaw mesh material and static entity templates')
