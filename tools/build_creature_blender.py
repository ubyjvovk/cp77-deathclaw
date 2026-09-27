"""Map original Fallout skin weights to the boxing android's deformation rig."""
import bpy, json, math
from pathlib import Path
from mathutils import Matrix, Vector, Quaternion

ROOT=Path(__file__).resolve().parents[1]
WORK=ROOT/'work/creature'
RAW=ROOT/'creature/source/raw/local/deathclaw_creature'
RAW.mkdir(parents=True,exist_ok=True)
g=json.loads((WORK/'fallout_rig.json').read_text())
r=json.loads(next((WORK/'donor').rglob('man_big_deformations.rig.json')).read_text())['Data']['RootChunk']
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
names=[b['$value'] for b in r['boneNames']]
world={}
for i,(name,t) in enumerate(zip(names,r['boneTransforms'])):
    q=t['Rotation']; p=t['Translation']; s=t['Scale']
    local=Matrix.LocRotScale(Vector((p['X'],p['Y'],p['Z'])),Quaternion((q['r'],q['i'],q['j'],q['k'])),Vector((s['X'],s['Y'],s['Z'])))
    parent=r['boneParentIndexes'][i]
    world[name]=world[names[parent]]@local if parent>=0 else local
print('Donor landmarks', {n:list(world[n].translation) for n in ['Hips','Head','LeftArm','LeftHand','LeftFoot']})
(WORK/'android_bind_matrices.json').write_text(json.dumps({n:{'inverse':[list(row) for row in m.inverted().transposed()], 'position':list(m.translation)} for n,m in world.items()}))

def armature(name, matrices, parents):
    data=bpy.data.armatures.new(name)
    obj=bpy.data.objects.new(name,data); bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.objects.active=obj; obj.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    for n,m in matrices.items():
        b=data.edit_bones.new(n); b.length=.08; b.matrix=m
    for n,p in parents.items():
        if p in data.edit_bones: data.edit_bones[n].parent=data.edit_bones[p]
    bpy.ops.object.mode_set(mode='OBJECT'); obj.select_set(False)
    return obj

rig=armature('Deathclaw_Android_Rig',world,{n:names[r['boneParentIndexes'][i]] for i,n in enumerate(names) if r['boneParentIndexes'][i]>=0})
source={b['name']:Matrix(b['bind']).transposed().translation for b in g['skin']}
# Both source and donor have anatomical left on -X and forward on +Y.
axis=Matrix.Identity(3)
factor=.009
origin=Vector((0,source['Bip01 Pelvis'].y,0))
source={n:axis@(p-origin)*factor for n,p in source.items()}
verts=[axis@(Vector(v)-origin)*factor for v in g['vertices']]
mapping={'Bip01 Pelvis':'Hips','Bip01 Spine':'Spine','Bip01 Spine1':'Spine1','Bip01 Spine2':'Spine3','Bip01 Neck':'Neck','Bip01 Neck1':'Neck1','Bip01 Head':'Head'}
for side,dest in [('L','Left'),('R','Right')]:
    for src,tgt in [('Clavicle','Shoulder'),('UpperArm','Arm'),('UpTwist','Arm'),('Forearm','ForeArm'),('ForeTwist','ForeArm'),('Hand','Hand'),('Thigh','UpLeg'),('Calf','Leg'),('Foot','Foot')]:
        mapping[f'Bip01 {side} {src}']=dest+tgt
    for n in source:
        if n.startswith(f'Bip01 {side} Finger'): mapping[n]=dest+'Hand'
        if n.startswith(f'Bip01 {side} Toe'): mapping[n]=dest+'ToeBase'
for n in source:
    if 'Tail' in n: mapping[n]='Hips'
    if 'Ponytail' in n: mapping[n]='Head'
assert set(mapping)==set(source),(set(source)-set(mapping),set(mapping)-set(source))

# Rotate limb segments into the android's rest pose before rebinding. Fingers,
# jaw and tail keep their shapes and inherit their nearest supported parent.
transforms={}
for n,dst in mapping.items():
    anchor=n
    if 'Tail' in n: anchor='Bip01 Pelvis'
    elif 'Ponytail' in n: anchor='Bip01 Head'
    elif 'Finger' in n: anchor=n[:7]+' Hand'
    elif 'Toe' in n: anchor=n[:7]+' Toe1'
    elif 'ForeTwist' in n: anchor=n.replace('ForeTwist','Forearm')
    elif 'UpTwist' in n: anchor=n.replace('UpTwist','UpperArm')
    rot=Matrix.Identity(3); stretch=Matrix.Identity(3)
    nextbone=None; targetnext=None
    for suffix,child,targetchild in [('UpperArm','Forearm','ForeArm'),('Forearm','Hand','Hand'),('Thigh','Calf','Leg'),('Calf','Foot','Foot'),('Foot','Toe1','ToeBase')]:
        if anchor.endswith(' '+suffix):
            nextbone=anchor.rsplit(' ',1)[0]+' '+child
            targetnext=('Left' if ' L ' in anchor else 'Right')+targetchild
    if anchor.endswith(' Hand'):
        prev=anchor.replace(' Hand',' Forearm')
        targetprev=('Left' if ' L ' in anchor else 'Right')+'ForeArm'
        rot=(source[anchor]-source[prev]).rotation_difference(world[dst].translation-world[targetprev].translation).to_matrix()
    if nextbone:
        a=source[nextbone]-source[anchor]; b=world[targetnext].translation-world[dst].translation
        rot=a.rotation_difference(b).to_matrix()
        # Scale along the segment, retain the creature's thickness across it.
        u=a.normalized(); ratio=b.length/a.length
        stretch=Matrix.Identity(3)+Matrix([[u[i]*u[j]*(ratio-1) for j in range(3)] for i in range(3)])
    transforms[n]=(world[dst].translation,rot@stretch,source[anchor])
out=[Vector((0,0,0)) for _ in verts]
weights={n:{} for n in set(mapping.values())}
for b in g['skin']:
    n=b['name']; dst=mapping[n]; target,rs,base=transforms[n]
    for i,w in b['weights']:
        out[i]+=(target+rs@(verts[i]-base))*w
        weights[dst][i]=weights[dst].get(i,0)+w

mesh=bpy.data.meshes.new('submesh_00_LOD_1');mesh.from_pydata(out,[],g['triangles']);mesh.update()
obj=bpy.data.objects.new(mesh.name,mesh);bpy.context.collection.objects.link(obj)
for poly in mesh.polygons:poly.use_smooth=True
for name in ['UVMap','UVMap.001']:
    uv=mesh.uv_layers.new(name=name)
    for loop in mesh.loops:
        u,v=g['uv'][loop.vertex_index];uv.data[loop.index].uv=(u,1-v)
for name in ['Color','Color.001']:
    col=mesh.color_attributes.new(name=name,type='BYTE_COLOR',domain='CORNER')
    for c in col.data:c.color=(1,1,1,1)
for name,ws in weights.items():
    group=obj.vertex_groups.new(name=name)
    for i,w in ws.items():group.add([i],w,'REPLACE')
mod=obj.modifiers.new('Android skin','ARMATURE');mod.object=rig;obj.parent=rig
mat=bpy.data.materials.new('deathclaw_skin');mat.use_nodes=True
bsdf=mat.node_tree.nodes.get('Principled BSDF');bsdf.inputs['Roughness'].default_value=.8
tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(ROOT/'work/deathclaw.png'))
mat.node_tree.links.new(tex.outputs['Color'],bsdf.inputs['Base Color']);mesh.materials.append(mat)
bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);rig.select_set(True);bpy.context.view_layer.objects.active=rig
bpy.ops.export_scene.gltf(filepath=str(RAW/'deathclaw_android.glb'),export_format='GLB',use_selection=True,export_materials='NONE',export_animations=False,export_skins=True,export_yup=True,export_tangents=True,export_normals=True,export_all_vertex_colors=True)
(WORK/'retarget_report.json').write_text(json.dumps({'source_nodes':len(g['skeleton']),'source_weighted_bones':len(g['skin']),'target_bones':len(world),'weighted_target_bones':len(weights),'mapping':mapping,'dimensions':list(obj.dimensions),'tail':'Rigid, follows pelvis','fingers':'Rigid, follow hands','in_game_verified':False},indent=2))

def aim(o,p):o.rotation_euler=(Vector(p)-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(4,6,3));cam=bpy.context.object;cam.data.type='ORTHO';cam.data.ortho_scale=3.6;aim(cam,(0,0,1));bpy.context.scene.camera=cam
for loc,power in [((2,-3,6),1000),((-3,-2,3),700),((0,4,5),1400)]:
    bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.data.energy=power;o.data.shape='DISK';o.data.size=4;aim(o,(0,0,1))
bpy.ops.mesh.primitive_plane_add(size=100);ground=bpy.context.object;ground.location.z=-.12
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.render.resolution_x=1000;scene.render.resolution_y=1000;scene.render.resolution_percentage=100;scene.world.color=(.2,.2,.2)
scene.render.filepath=str(WORK/'android_bind_preview.png');bpy.ops.wm.save_as_mainfile(filepath=str(WORK/'deathclaw_android.blend'));bpy.ops.render.render(write_still=True)
