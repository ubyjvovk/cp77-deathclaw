"""Read New Vegas geometry and bake its original combat-ready animation pose."""
import json
import math
from pathlib import Path
import time
time.clock = time.perf_counter  # PyFFI's legacy timing API
from pyffi.formats.nif import NifFormat
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'source/meshes/creatures/deathclaw'

def read(name):
    data = NifFormat.Data()
    with (SOURCE / name).open('rb') as stream:
        data.read(stream)
    return data

model = read('deathclaw.nif')
skeleton = read('skeleton.nif')
animation = read('h2haim.kf')
bones = {b.name: b for b in skeleton.blocks if isinstance(b, NifFormat.NiNode)}
for link in animation.roots[0].controlled_blocks:
    bone = bones.get(link.node_name)
    ip = link.interpolator
    if bone is None or ip is None or not hasattr(ip, 'translation'):
        continue
    translations = list(ip.get_translations()) if hasattr(ip, 'get_translations') else []
    rotations = list(ip.get_rotations()) if hasattr(ip, 'get_rotations') else []
    scales = list(ip.get_scales()) if hasattr(ip, 'get_scales') else []
    t = translations[0] if translations else ip.translation.as_tuple()
    r = rotations[0] if rotations else (ip.rotation.w, ip.rotation.x, ip.rotation.y, ip.rotation.z)
    s = scales[0] if scales else ip.scale
    if all(abs(v) < 1e10 for v in t):
        bone.translation.x, bone.translation.y, bone.translation.z = t
    if all(abs(v) < 1e10 for v in r):
        norm = math.sqrt(sum(v*v for v in r))
        w, x, y, z = [v / norm for v in r]
        matrix = [[1-2*(y*y+z*z), 2*(x*y+z*w), 2*(x*z-y*w)],
                  [2*(x*y-z*w), 1-2*(x*x+z*z), 2*(y*z+x*w)],
                  [2*(x*z+y*w), 2*(y*z-x*w), 1-2*(x*x+y*y)]]
        for row, values in enumerate(matrix, 1):
            for col, value in enumerate(values, 1):
                setattr(bone.rotation, f'm_{row}{col}', value)
    if abs(s) < 1e10:
        bone.scale = s

mesh = next(b for b in model.blocks if isinstance(b, NifFormat.NiTriShape) and b.name == b'Deathclaw')
for bone in mesh.skin_instance.bones:
    bone.set_transform(bones[bone.name].get_transform(skeleton.roots[0]))
vertices, normals = mesh.get_skin_deformation()
geometry = {
    'name': 'deathclaw', 'pose': 'h2haim.kf first frame',
    'vertices': [v.as_list() for v in vertices],
    'normals': [v.as_list() for v in normals],
    'triangles': list(mesh.data.get_triangles()),
    'uv': [[uv.u, uv.v] for uv in mesh.data.uv_sets[0]],
    'bones': {name.decode(): (bone.get_transform(skeleton.roots[0]).get_translation() * mesh.skin_instance.data.get_transform()).as_list()
              for name, bone in bones.items() if name in [b'Bip01 Pelvis', b'Bip01 Spine2', b'Bip01 Head', b'Bip01 L Foot', b'Bip01 R Foot']},
}
(ROOT / 'work').mkdir(exist_ok=True)
(ROOT / 'work/deathclaw_geometry.json').write_text(json.dumps(geometry))
print(f'Baked {len(vertices)} vertices and {len(geometry["triangles"])} triangles')
for filename in ['deathclaw', 'deathclaw_n']:
    im = Image.open(ROOT / f'source/textures/creatures/deathclaw/{filename}.dds')
    im.convert('RGB').save(ROOT / f'work/{filename}.png')
    print(filename, im.size)
