import bpy, json
from mathutils import Vector
rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
bpy.context.view_layer.update()
def error(end,target):
    return (rig.pose.bones[end].tail-rig.pose.bones[target].head).length
results={'bones':len(rig.data.bones),'connected_bones':sum(b.use_connect for b in rig.data.bones),'checks':[]}
for side in ['L','R']:
    for end,target in [('forearm','hand'),('shin','foot')]:
        e=error(end+'.'+side,'CTRL_'+target+'.'+side)
        assert e<.003,(end,side,e)
        results['checks'].append([end+'.'+side+' resting IK',e])
cart=rig.pose.bones['CART'];cart.location.x=.025
bpy.context.view_layer.update()
for side in ['L','R']:
    e=error('forearm.'+side,'CTRL_hand.'+side);assert e<.003,e
    results['checks'].append(['Hand follows cart '+side,e])
cart.location.x=0
foot=rig.pose.bones['CTRL_foot.L'];foot.location.z=.075
bpy.context.view_layer.update()
e=error('shin.L','CTRL_foot.L');assert e<.003,e
results['checks'].append(['Foot step IK',e]);foot.location.z=0
for o in bpy.data.objects:
    mods=[m for m in o.modifiers if m.type=='ARMATURE'] if o.type=='MESH' else []
    if mods:
        assert mods[0].object==rig
        assert all(len(v.groups)>0 for v in o.data.vertices),o.name
results['checks'].append('All character and cart mesh vertices weighted')
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.fbx(filepath=r'F:\CompHw\man_shopping_cart.fbx')
rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
assert len(rig.data.bones)==51
meshes=[o for o in bpy.data.objects if o.type=='MESH'];assert len(meshes)==186
assert all(any(m.type=='ARMATURE' for m in o.modifiers) for o in meshes)
results['checks'].append('FBX reimport: 51 bones, 186 weighted meshes')
open(r'F:\CompHw\rig_validation.json','w').write(json.dumps(results,indent=2))
print('RIG_VALIDATION_PASSED',json.dumps(results))
