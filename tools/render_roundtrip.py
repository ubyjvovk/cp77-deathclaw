"""Render the mesh exported back out of the compiled Cyberpunk resource."""
import bpy
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'work/deathclaw.blend'))
original=bpy.data.objects['submesh_00_LOD_1']
material=original.data.materials[0]
bpy.data.objects.remove(original,do_unlink=True)
bpy.ops.import_scene.gltf(filepath=str(ROOT/'work/roundtrip/deathclaw.glb'))
for obj in bpy.context.selected_objects:
    if obj.type=='MESH':
        obj.data.materials.clear()
        obj.data.materials.append(material)
        print('Compiled mesh:',obj.name,len(obj.data.vertices),len(obj.data.polygons),list(obj.dimensions))
bpy.context.scene.render.filepath=str(ROOT/'work/deathclaw_compiled_preview.png')
bpy.ops.render.render(write_still=True)
