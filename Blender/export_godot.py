import bpy, os, json
out=r'F:\CompHw\man_cart_godot.fbx'
rigs=[o for o in bpy.context.scene.objects if o.type=='ARMATURE']
assert len(rigs)==1, 'Expected one character rig'
rig=rigs[0]
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH' and (o.parent==rig or any(m.type=='ARMATURE' and m.object==rig for m in o.modifiers))]
assert meshes, 'No rigged meshes found'
report={'source':bpy.data.filepath,'meshes':len(meshes),'bones':len(rig.data.bones),'actions':[{'name':a.name,'frames':list(a.frame_range)} for a in bpy.data.actions], 'nla_tracks':[]}
if rig.animation_data:
    report['active_action']=rig.animation_data.action.name if rig.animation_data.action else None
    report['nla_tracks']=[{'name':t.name,'mute':t.mute,'strips':[{'name':s.name,'action':s.action.name if s.action else None,'start':s.frame_start,'end':s.frame_end} for s in t.strips]} for t in rig.animation_data.nla_tracks]
print('SOURCE_REPORT',json.dumps(report))
if bpy.context.object and bpy.context.object.mode!='OBJECT':bpy.ops.object.mode_set(mode='OBJECT')
bpy.ops.object.select_all(action='DESELECT')
for o in [rig]+meshes:o.hide_set(False);o.hide_select=False;o.select_set(True)
bpy.context.view_layer.objects.active=rig
bpy.ops.export_scene.fbx(filepath=out,use_selection=True,object_types={'ARMATURE','MESH'},use_mesh_modifiers=True,add_leaf_bones=False,axis_forward='-Z',axis_up='Y',apply_unit_scale=True,bake_anim=True,bake_anim_use_all_bones=True,bake_anim_use_nla_strips=True,bake_anim_use_all_actions=True,bake_anim_force_startend_keying=True,bake_anim_step=1.0,bake_anim_simplify_factor=0.0)
report['output']=out;report['bytes']=os.path.getsize(out)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
for a in list(bpy.data.actions):bpy.data.actions.remove(a)
bpy.ops.import_scene.fbx(filepath=out)
report['reimport']={'meshes':sum(o.type=='MESH' for o in bpy.context.scene.objects),'armatures':sum(o.type=='ARMATURE' for o in bpy.context.scene.objects),'cameras':sum(o.type=='CAMERA' for o in bpy.context.scene.objects),'lights':sum(o.type=='LIGHT' for o in bpy.context.scene.objects),'actions':[{'name':a.name,'frames':list(a.frame_range)} for a in bpy.data.actions]}
assert report['reimport']['meshes']==len(meshes)
assert report['reimport']['armatures']==1
assert report['reimport']['cameras']==0 and report['reimport']['lights']==0
if report['actions']:assert report['reimport']['actions'], 'Animation export missing'
open(r'F:\CompHw\godot_export_report.json','w').write(json.dumps(report,indent=2))
print('EXPORT_VERIFIED',json.dumps(report))
