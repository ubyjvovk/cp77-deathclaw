"""Inspect compiled resource read-back and GLB roundtrip, not in-game behaviour."""
import hashlib
import json
from pathlib import Path
import struct

ROOT=Path(__file__).resolve().parents[1]
INSPECT=ROOT/'work/inspect'
def read(name):
    return json.loads((INSPECT/name).read_text())['Data']['RootChunk']
mesh=read('deathclaw.mesh.json')
entity=read('deathclaw.ent.json')
assert len(mesh['renderResourceBlob']['Data']['header']['renderChunkInfos']) == 1
assert mesh['materialEntries'][0]['name']['$value'] == 'deathclaw_skin'
assert mesh['boundingBox']['Min']['Z'] == 0
assert abs(mesh['boundingBox']['Max']['Z']-3.2)<0.001
shapes=mesh['parameters'][0]['Data']['physicsData']['Data']['bodies'][0]['Data']['collisionShapes']
assert len(shapes)==4 and all(s['Data']['$type']=='physicsColliderBox' for s in shapes)
assert len(entity['components'])==2
assert entity['entity']['Data']['$type']=='gameItemObject'
assert entity['components'][0]['mesh']['DepotPath']['$value']==r'local\deathclaw_badlands\deathclaw.mesh'
assert entity['components'][0]['$type']=='entPhysicalMeshComponent'
for suffix, compression, gamma in [('d01','TCM_DXTNoAlpha',1),('n01','TCM_Normalmap',0)]:
    texture=read('deathclaw_'+suffix+'.xbm.json')
    assert (texture['width'],texture['height']) == (1024,1024)
    assert texture['setup']['compression']==compression
    assert texture['setup']['isGamma']==gamma
blob=(ROOT/'work/roundtrip/deathclaw.glb').read_bytes()
magic,version,length=struct.unpack_from('<4sII',blob)
assert magic==b'glTF' and version==2 and length==len(blob)
json_length,kind=struct.unpack_from('<II',blob,12)
assert kind==0x4e4f534a
gltf=json.loads(blob[20:20+json_length])
triangle_count=sum(gltf['accessors'][p['indices']]['count']//3 for m in gltf['meshes'] for p in m['primitives'])
assert triangle_count==6930
files=[]
for file in (ROOT/'dist/Deathclaw Badlands').rglob('*'):
    if file.is_file():
        files.append({'path':str(file.relative_to(ROOT/'dist/Deathclaw Badlands')),'bytes':file.stat().st_size,'sha256':hashlib.sha256(file.read_bytes()).hexdigest()})
result={'compiled_resources_verified':True,'triangles_after_roundtrip':triangle_count,
        'height_metres':3.2,'collision_boxes':4,'texture_resolution':[1024,1024],
        'in_game_appearance_verified':False,'in_game_placement_verified':False,
        'in_game_collision_verified':False,'reload_behaviour_verified':False,'files':files}
(ROOT/'build_verification.json').write_text(json.dumps(result,indent=2))
print(json.dumps({k:v for k,v in result.items() if k!='files'},indent=2))
