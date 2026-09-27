import bpy
import json
import math
import shutil
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / 'project/source/raw/local/deathclaw_badlands'
RAW.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
g = json.loads((ROOT / 'work/deathclaw_geometry.json').read_text())
v = [Vector(p) for p in g['vertices']]
minimum = min(p.z for p in v)
height = max(p.z for p in v) - minimum
scale = 3.2 / height
cx = (min(p.x for p in v) + max(p.x for p in v)) / 2
cy = (min(p.y for p in v) + max(p.y for p in v)) / 2
vertices = [((p.x-cx)*scale, (p.y-cy)*scale, (p.z-minimum)*scale) for p in v]
mesh = bpy.data.meshes.new('submesh_00_LOD_1')
mesh.from_pydata(vertices, [], g['triangles'])
mesh.update()
obj = bpy.data.objects.new(mesh.name, mesh)
bpy.context.collection.objects.link(obj)
bpy.context.view_layer.objects.active = obj
obj.select_set(True)
for poly in mesh.polygons:
    poly.use_smooth = True
for name in ['UVMap', 'UVMap.001']:
    uv = mesh.uv_layers.new(name=name)
    for loop in mesh.loops:
        u, v = g['uv'][loop.vertex_index]
        uv.data[loop.index].uv = (u, 1-v)
for name in ['Color', 'Color.001']:
    col = mesh.color_attributes.new(name=name, type='BYTE_COLOR', domain='CORNER')
    for c in col.data:
        c.color = (1, 1, 1, 1)
mat = bpy.data.materials.new('deathclaw_skin')
mat.use_nodes = True
nodes, links = mat.node_tree.nodes, mat.node_tree.links
bsdf = nodes.get('Principled BSDF')
bsdf.inputs['Roughness'].default_value = 0.78
for suffix, filename in [('d01', 'deathclaw.png'), ('n01', 'deathclaw_n.png')]:
    texture_path = RAW / f'deathclaw_{suffix}.png'
    shutil.copy2(ROOT / 'work' / filename, texture_path)
    img = bpy.data.images.load(str(texture_path))
    if suffix == 'n01':
        img.colorspace_settings.name = 'Non-Color'
    tex = nodes.new('ShaderNodeTexImage')
    tex.image = img
    if suffix == 'd01':
        links.new(tex.outputs['Color'], bsdf.inputs['Base Color'])
    else:
        normal = nodes.new('ShaderNodeNormalMap')
        links.new(tex.outputs['Color'], normal.inputs['Color'])
        links.new(normal.outputs['Normal'], bsdf.inputs['Normal'])
mesh.materials.append(mat)
bpy.ops.export_scene.gltf(filepath=str(RAW / 'deathclaw.glb'), export_format='GLB', use_selection=True,
    export_yup=True, export_materials='NONE', export_animations=False, export_skins=False,
    export_tangents=True, export_normals=True, export_attributes=True,
    export_all_vertex_colors=True, export_active_vertex_color_when_no_material=True,
    export_extras=True)
print('Dimensions (m):', list(obj.dimensions))

def aim(o, target):
    o.rotation_euler = (Vector(target)-o.location).to_track_quat('-Z', 'Y').to_euler()
bpy.ops.object.camera_add(location=(-7, -9, 4.3))
camera = bpy.context.object
camera.data.type = 'ORTHO'
camera.data.ortho_scale = 6.5
aim(camera, (0, 0, 1.55))
bpy.context.scene.camera = camera
for location, power, size in [((2,-4,7),1800,5),((-4,-1,4),1300,4),((0,5,5),2100,3)]:
    bpy.ops.object.light_add(type='AREA', location=location)
    light = bpy.context.object
    light.data.energy, light.data.shape, light.data.size = power, 'DISK', size
    aim(light, (0,0,1.6))
bpy.ops.mesh.primitive_plane_add(size=200, location=(0,0,-0.01))
ground = bpy.context.object
ground.name = 'Preview ground (not exported)'
groundmat = bpy.data.materials.new('Sand')
groundmat.diffuse_color=(0.18,0.135,0.085,1)
ground.data.materials.append(groundmat)
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.samples = 24
scene.render.resolution_x = 1000
scene.render.resolution_y = 1000
scene.render.resolution_percentage = 100
scene.world.color = (0.25,0.25,0.25)
scene.render.filepath = str(ROOT / 'work/deathclaw_preview.png')
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / 'work/deathclaw.blend'))
bpy.ops.render.render(write_still=True)
