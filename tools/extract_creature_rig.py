"""Preserve the original Deathclaw bind pose, skeleton and per-vertex weights."""
import json
import time
from pathlib import Path

time.clock = time.perf_counter
from pyffi.formats.nif import NifFormat

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'source/meshes/creatures/deathclaw'
OUT = ROOT / 'work/creature'
OUT.mkdir(parents=True, exist_ok=True)

def read(name):
    data = NifFormat.Data()
    with (SOURCE / name).open('rb') as stream:
        data.read(stream)
    return data

model, skeleton = read('deathclaw.nif'), read('skeleton.nif')
mesh = next(b for b in model.blocks if isinstance(b, NifFormat.NiTriShape) and b.name == b'Deathclaw')
parents = {}
for node in skeleton.blocks:
    if isinstance(node, NifFormat.NiNode):
        for child in node.children:
            if child is not None:
                parents[child.name] = node.name
bones = []
for bone in skeleton.blocks:
    if isinstance(bone, NifFormat.NiNode):
        bones.append(dict(name=bone.name.decode(), parent=parents.get(bone.name,b'').decode(),
                          local=bone.get_transform().as_list(),
                          world=bone.get_transform(skeleton.roots[0]).as_list()))
skin = []
totals = [0.0] * mesh.data.num_vertices
for bone, data in zip(mesh.skin_instance.bones, mesh.skin_instance.data.bone_list):
    weights = [[int(w.index),float(w.weight)] for w in data.vertex_weights]
    for index, weight in weights:
        totals[index] += weight
    skin.append(dict(name=bone.name.decode(), inverse_bind=data.get_transform().as_list(),
                     bind=data.get_transform().get_inverse().as_list(), weights=weights))
assert all(abs(w-1)<0.002 for w in totals), 'Invalid source skin weights'
out = dict(vertices=[v.as_list() for v in mesh.data.vertices],
           triangles=list(mesh.data.get_triangles()),
           uv=[[v.u,v.v] for v in mesh.data.uv_sets[0]],
           mesh_transform=mesh.get_transform().as_list(),
           skin_transform=mesh.skin_instance.data.get_transform().as_list(),
           skeleton=bones, skin=skin,
           animations=[p.name for p in sorted(SOURCE.glob('*.kf'))])
(OUT/'fallout_rig.json').write_text(json.dumps(out))
print(f'Extracted {len(bones)} skeleton nodes, {len(skin)} weighted bones, '
      f'{len(totals)} vertices, {len(out["animations"])} animation files')
print('Weight sums:',min(totals),max(totals))
