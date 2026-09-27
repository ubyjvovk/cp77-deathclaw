"""Sample an actual Cyberpunk android walk and retarget its pose for visual QA."""
import bpy,json,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];WORK=ROOT/'work/creature'
bpy.ops.wm.open_mainfile(filepath=str(WORK/'deathclaw_android.blend'))
target=bpy.data.objects['Deathclaw_Android_Rig']
attack='--attack' in sys.argv
pattern='mb_gang_unarmed_action_combat.anims.glb' if attack else 'mb_animal_unarmed_locomotion_relaxed.anims.glb'
bpy.ops.import_scene.gltf(filepath=str(next((WORK/'animations').rglob(pattern))))
source=next(o for o in bpy.data.objects if o.type=='ARMATURE' and o!=target)
print('ANIMATIONS',[(a.name,list(a.frame_range)) for a in bpy.data.actions])
actions=[a for a in bpy.data.actions if 'walk' in a.name.lower() and ('forward' in a.name.lower() or '_f_' in a.name.lower())]
if not actions:actions=[a for a in bpy.data.actions if 'walk' in a.name.lower()]
action=bpy.data.actions.get('melee_combo_01_p1_Armature' if attack else 'walk_0_Armature')
assert action,'Requested brawler animation missing'
print('Preview animation:',action.name)
source.animation_data_create()
for t in source.animation_data.nla_tracks:t.mute=True
source.animation_data.action=action
scene=bpy.context.scene;scene.render.resolution_x=600;scene.render.resolution_y=600;scene.cycles.samples=8
frames=WORK/('brawler_attack_preview' if attack else 'brawler_walk_preview');frames.mkdir(exist_ok=True)
for i in range(12):
    frame=action.frame_range[0]+(action.frame_range[1]-action.frame_range[0])*i/12
    scene.frame_set(int(frame),subframe=frame-int(frame));bpy.context.view_layer.update()
    for bone in target.pose.bones:
        if bone.name in source.pose.bones:
            sb=source.pose.bones[bone.name]
            bone.matrix=source.matrix_world@sb.matrix@sb.bone.matrix_local.inverted()@bone.bone.matrix_local
            bpy.context.view_layer.update()
    scene.render.filepath=str(frames/f'{i:02}.png');bpy.ops.render.render(write_still=True)
(WORK/('attack_preview.json' if attack else 'animation_preview.json')).write_text(json.dumps({'animation':action.name,'source':'Cyberpunk man_big melee brawler','frames':12,'in_game_verified':False},indent=2))
