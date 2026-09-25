import bpy, math, os, json
from mathutils import Vector

OUT = r'F:\CompHw'
bpy.ops.object.mode_set(mode='OBJECT') if bpy.context.object and bpy.context.object.mode != 'OBJECT' else None
print('SOURCE_OBJECTS', [(o.name,o.type) for o in bpy.data.objects])
# Preserve the source on disk; generate into a separate deliverable.
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for col in list(bpy.data.collections):
    if col.name != 'Collection': bpy.data.collections.remove(col)

def mat(name, color, metal=0, rough=.45):
    m=bpy.data.materials.new(name); m.diffuse_color=(*color,1); m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF'); p.inputs['Base Color'].default_value=(*color,1)
    p.inputs['Metallic'].default_value=metal; p.inputs['Roughness'].default_value=rough
    return m
skin=mat('Warm skin',(.57,.30,.17)); shirt=mat('Petrol blue cotton',(.035,.25,.30)); pants=mat('Charcoal trousers',(.065,.085,.12)); shoe=mat('Off white sneakers',(.78,.79,.74)); sole=mat('Rubber soles',(.12,.15,.17)); hair=mat('Dark brown hair',(.055,.025,.018)); white=mat('Eye whites',(.88,.89,.82)); pupil=mat('Dark eyes',(.018,.024,.027)); steel=mat('Brushed steel',(.5,.59,.64),.85,.27); rubber=mat('Wheel rubber',(.045,.055,.06)); orange=mat('Handle orange',(.95,.24,.035)); hub=mat('Wheel hubs',(.28,.34,.38),.7)
parts=[]
def finish(o,name,m,bone):
    o.name=name; o.data.materials.append(m)
    for p in o.data.polygons: p.use_smooth=len(p.vertices)<=4
    if bone: parts.append((o,bone))
    return o
def ell(name,pos,scale,m,bone=None):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24,ring_count=16,location=pos)
    o=bpy.context.object; o.scale=scale; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return finish(o,name,m,bone)
def box(name,pos,scale,m,bone=None,bevel=.025):
    bpy.ops.mesh.primitive_cube_add(size=1,location=pos); o=bpy.context.object; o.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        mod=o.modifiers.new('Soft edges','BEVEL');mod.width=bevel;mod.segments=3
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return finish(o,name,m,bone)
def tube(name,a,b,r,m,bone=None,r2=None):
    a,b=Vector(a),Vector(b); d=b-a
    bpy.ops.mesh.primitive_cone_add(vertices=16,radius1=r,radius2=r if r2 is None else r2,depth=d.length,location=(a+b)/2)
    o=bpy.context.object;o.rotation_euler=d.to_track_quat('Z','Y').to_euler()
    return finish(o,name,m,bone)

# Facing +Y. The human and cart use a shared master and independent controls.
spec=[]
def bone(n,h,t,p=None,connected=False,deform=True): spec.append((n,h,t,p,connected,deform))
bone('MASTER',(0,0,.05),(0,0,.35),deform=False)
bone('pelvis',(0,0,.91),(0,0,1.06),'MASTER')
bone('spine',(0,0,1.06),(0,.035,1.27),'pelvis',True)
bone('chest',(0,.035,1.27),(0,.07,1.48),'spine',True)
bone('neck',(0,.07,1.48),(0,.08,1.58),'chest',True)
bone('head',(0,.08,1.58),(0,.09,1.84),'neck',True)
bone('CART',(0,.9,.22),(0,.9,.6),'MASTER')
ell('Hip trousers',(0,0,.96),(.195,.13,.15),pants,'pelvis')
ell('Shirt abdomen',(0,.018,1.15),(.20,.125,.23),shirt,'spine')
ell('Shirt chest',(0,.046,1.36),(.245,.145,.20),shirt,'chest')
tube('Neck',(0,.07,1.46),(0,.08,1.61),.067,skin,'neck')
ell('Head',(0,.09,1.70),(.115,.102,.151),skin,'head')
ell('Hair cap',(0,.072,1.79),(.117,.097,.075),hair,'head')
ell('Back hair',(0,.023,1.73),(.112,.056,.103),hair,'head')
ell('Nose',(0,.192,1.69),(.026,.037,.034),skin,'head')
tube('Smile',(-.035,.184,1.64),(.035,.184,1.64),.006,hair,'head')
for s,side in [(1,'L'),(-1,'R')]:
    ell('Ear.'+side,(s*.114,.084,1.70),(.023,.024,.038),skin,'head')
    ell('Eye.'+side,(s*.042,.180,1.729),(.022,.012,.016),white,'head')
    ell('Pupil.'+side,(s*.042,.191,1.729),(.009,.004,.010),pupil,'head')
    tube('Brow.'+side,(s*.023,.179,1.757),(s*.065,.174,1.757),.007,hair,'head')
    hip=(s*.115,0,.94); knee=(s*.125,.045,.53); ankle=(s*.13,0,.13)
    bone('thigh.'+side,hip,knee,'pelvis')
    bone('shin.'+side,knee,ankle,'thigh.'+side,True)
    bone('foot.'+side,ankle,(s*.13,.19,.09),'shin.'+side,True)
    bone('CTRL_foot.'+side,ankle,(s*.13,.19,.09),'MASTER',deform=False)
    bone('POLE_knee.'+side,(s*.125,.55,.53),(s*.125,.55,.65),'MASTER',deform=False)
    tube('Trouser thigh.'+side,hip,knee,.101,pants,'thigh.'+side,.078)
    ell('Knee.'+side,knee,(.079,.078,.085),pants,'shin.'+side)
    tube('Trouser calf.'+side,knee,ankle,.076,pants,'shin.'+side,.055)
    box('Sneaker.'+side,(s*.13,.065,.095),(.145,.285,.13),shoe,'foot.'+side,.045)
    box('Sole.'+side,(s*.13,.068,.042),(.15,.29,.04),sole,'foot.'+side,.016)
    for y in [.06,.10,.14]: tube('Lace.'+side, (s*.13-.045,y,.158),(s*.13+.045,y,.158),.005,white,'foot.'+side)
    sh=(s*.225,.06,1.44); elbow=(s*.28,.23,1.21); wrist=(s*.265,.49,1.12)
    bone('clavicle.'+side,(0,.07,1.48),sh,'chest')
    bone('upper_arm.'+side,sh,elbow,'clavicle.'+side,True)
    bone('forearm.'+side,elbow,wrist,'upper_arm.'+side,True)
    bone('hand.'+side,wrist,(s*.265,.555,1.095),'forearm.'+side,True)
    bone('CTRL_hand.'+side,wrist,(s*.265,.555,1.095),'CART',deform=False)
    bone('POLE_elbow.'+side,(s*.65,.04,1.15),(s*.65,.04,1.28),'MASTER',deform=False)
    ell('Shoulder.'+side,sh,(.092,.095,.095),shirt,'upper_arm.'+side)
    upperend=Vector(sh).lerp(Vector(elbow),.62)
    tube('Short sleeve.'+side,sh,upperend,.096,shirt,'upper_arm.'+side,.082)
    tube('Upper arm.'+side,upperend,elbow,.066,skin,'upper_arm.'+side,.056)
    ell('Elbow.'+side,elbow,(.057,.057,.057),skin,'forearm.'+side)
    tube('Forearm.'+side,elbow,wrist,.060,skin,'forearm.'+side,.039)
    ell('Palm.'+side,(s*.265,.525,1.105),(.048,.053,.033),skin,'hand.'+side)
    for j in range(4):
        x=s*.265+(j-1.5)*.021
        a=(x,.538,1.11);b=(x,.568,1.085);c=(x,.548,1.067)
        bn='finger_%d.%s'%(j+1,side);bone(bn,a,b,'hand.'+side)
        bone(bn+'_tip',b,c,bn,True)
        tube('Finger '+bn,a,b,.011,skin,bn);ell('Knuckle '+bn,b,(.011,.011,.011),skin,bn+'_tip');tube('Fingertip '+bn,b,c,.011,skin,bn+'_tip')
    a=(s*.228,.510,1.105); b=(s*.215,.544,1.08)
    bone('thumb.'+side,a,b,'hand.'+side);tube('Thumb.'+side,a,b,.017,skin,'thumb.'+side)

# Open wire shopping basket: tapered bottom and full metal grid.
for z,w,rear,front in [(.64,.255,.66,1.28),(1.03,.34,.60,1.43)]:
    for a,b in [((-w,rear,z),(w,rear,z)),((-w,front,z),(w,front,z)),((-w,rear,z),(-w,front,z)),((w,rear,z),(w,front,z))]:tube('Basket rim',a,b,.014,steel,'CART')
for i in range(12):
    u=i/11
    for s in [-1,1]:tube('Side vertical wire',(s*.255,.66+u*.62,.64),(s*.34,.60+u*.83,1.03),.0045,steel,'CART')
for i in range(11):
    u=i/10
    for y0,y1 in [(.66,.60),(1.28,1.43)]:tube('End vertical wire',(-.255+u*.51,y0,.64),(-.34+u*.68,y1,1.03),.0045,steel,'CART')
    tube('Basket floor',(-.255+u*.51,.66,.64),(-.255+u*.51,1.28,.64),.0045,steel,'CART')
for i in range(1,6):
    u=i/6;z=.64+u*.39;w=.255+u*.085;ya=.66-u*.06;yb=1.28+u*.15
    for s in [-1,1]:tube('Side horizontal wire',(s*w,ya,z),(s*w,yb,z),.004,steel,'CART')
    for y in [ya,yb]:tube('End horizontal wire',(-w,y,z),(w,y,z),.004,steel,'CART')
for s in [-1,1]:
    tube('Base rail',(s*.29,.57,.22),(s*.29,1.36,.22),.019,steel,'CART')
    tube('Rear upright',(s*.29,.61,.22),(s*.34,.61,1.03),.021,steel,'CART')
    tube('Basket brace',(s*.29,1.29,.22),(s*.29,.74,.77),.017,steel,'CART')
    tube('Handle stem',(s*.34,.60,1.03),(s*.34,.54,1.095),.019,steel,'CART')
tube('Push handle',(-.355,.54,1.095),(.355,.54,1.095),.022,orange,'CART')
for y in [.57,1.36]:tube('Chassis cross rail',(-.29,y,.22),(.29,y,.22),.018,steel,'CART')
for i in range(7):tube('Lower rack',(-.25+i*.083,.65,.245),(-.25+i*.083,1.28,.245),.007,steel,'CART')
for s,side in [(1,'L'),(-1,'R')]:
    for y,end in [(.60,'rear'),(1.30,'front')]:
        x=s*.29; n='wheel_'+end+'.'+side
        bone(n,(x,y,.105),(x+.13,y,.105),'CART')
        tube('Caster fork',(x,y,.22),(x,y,.105),.023,steel,'CART')
        tube('Tire '+n,(x-.034,y,.105),(x+.034,y,.105),.10,rubber,n)
        tube('Hub '+n,(x-.036,y,.105),(x+.036,y,.105),.052,hub,n)

arm=bpy.data.armatures.new('Man and cart skeleton');rig=bpy.data.objects.new('RIG • Man pushing cart',arm);bpy.context.collection.objects.link(rig)
bpy.context.view_layer.objects.active=rig;rig.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
for n,h,t,p,c,d in spec:
    b=arm.edit_bones.new(n);b.head=h;b.tail=t
    if p: b.parent=arm.edit_bones[p];b.use_connect=c
    b.use_deform=d
bpy.ops.object.mode_set(mode='OBJECT')
rig.show_in_front=True;arm.display_type='STICK'
for o,n in parts:
    vg=o.vertex_groups.new(name=n);vg.add(list(range(len(o.data.vertices))),1,'REPLACE')
    mod=o.modifiers.new('Skeleton deformation','ARMATURE');mod.object=rig;o.parent=rig
for side in ['L','R']:
    for limb,target in [('forearm','hand'),('shin','foot')]:
        pb=rig.pose.bones[limb+'.'+side];con=pb.constraints.new('IK');con.name='Two-bone '+target+' IK';con.target=rig;con.subtarget='CTRL_'+target+'.'+side;con.chain_count=2;con.use_stretch=False
    for n in ['hand','foot']:
        c=rig.pose.bones[n+'.'+side].constraints.new('COPY_ROTATION');c.target=rig;c.subtarget='CTRL_'+n+'.'+side;c.target_space='WORLD';c.owner_space='WORLD'
# Pole controls are supplied as optional targets; free IK preserves the modeled bend without a snap.
controls=arm.collections.new('CONTROLS — pose these');deforms=arm.collections.new('DEFORM — connected skeleton');optional=arm.collections.new('OPTIONAL — IK poles')
for b in arm.bones:
    (optional if b.name.startswith('POLE') else controls if b.name.startswith('CTRL') or b.name in ['MASTER','CART','pelvis'] or b.name.startswith('wheel') else deforms).assign(b)
    b.color.palette='THEME04' if b.name.startswith('CTRL') else 'THEME03' if b.name=='CART' else 'DEFAULT'
optional.is_visible=False;deforms.is_visible=False
rig['HOW TO POSE']='Pose Mode: MASTER moves everything. CART moves cart and hand IK. CTRL_foot.L/R place feet. pelvis sets body height. CTRL_hand.L/R adjust grips. Wheel bones rotate on local Y. Fingers have individual bones.'
rig['STYLE']='Stylized articulated character. Rigid segment weights; rounded joints conceal bends.'
readme='''MAN + SHOPPING CART\n\nOpen man_shopping_cart.blend for the complete posing rig.\nSelect RIG and enter Pose Mode (Ctrl+Tab).\nMASTER: move/rotate the entire assembly.\nCART: move/rotate the cart; both hands follow the handle via IK.\npelvis: move the body; feet stay on their IK controls.\nCTRL_foot.L / .R: animate steps; rotate to tilt shoes.\nCTRL_hand.L / .R: adjust hand grips relative to the cart.\nwheel_front/rear.L/R: rotate LOCAL Y to roll the wheels.\nEnable DEFORM bone collection to pose spine, head and fingers.\nOptional pole bones are provided but not assigned; the initial bends guide IK.\nCharacter uses intentionally stylized rigid segments with rounded joints.\n\nFBX contains meshes, materials and connected skeleton. Blender IK constraints\nand control behavior are native to the .blend and are not portable in FBX.\nAnimate in the .blend, then export FBX with Bake Animation enabled.\nNo animation clips have been added. Original cart.blend is preserved.\n'''
bpy.data.texts.new('READ ME — posing').write(readme)
open(os.path.join(OUT,'README_rig.txt'),'w',encoding='utf8').write(readme)

# Presentation objects are excluded from FBX.
ground=mat('Studio sand',(.20,.235,.25))
box('Studio ground',(0,.65,-.055),(200,200,.08),ground,bevel=0)
bpy.ops.object.camera_add(location=(3.4,4.5,2.7));cam=bpy.context.object;cam.name='Preview camera';cam.rotation_euler=(Vector((0,.63,.95))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=2.8;bpy.context.scene.camera=cam
for name,loc,power,size in [('Key',(2,1,4),650,4),('Fill',(-3,2,2.5),450,3),('Rim',(0,-3,3),750,3)]:
    bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.name=name;o.data.energy=power;o.data.shape='DISK';o.data.size=size;o.rotation_euler=(Vector((0,.6,1))-o.location).to_track_quat('-Z','Y').to_euler()
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=32;scene.render.resolution_x=1000;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
scene.world.color=(.25,.25,.25)
scene.render.filepath=os.path.join(OUT,'man_shopping_cart_preview.png')
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);bpy.context.view_layer.objects.active=rig
for o,n in parts:o.select_set(True)
bpy.ops.export_scene.fbx(filepath=os.path.join(OUT,'man_shopping_cart.fbx'),use_selection=True,object_types={'ARMATURE','MESH'},add_leaf_bones=False,bake_anim=False,axis_forward='-Z',axis_up='Y')
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);bpy.context.view_layer.objects.active=rig
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D':
            area.spaces.active.region_3d.view_distance=3.3;area.spaces.active.region_3d.view_location=(0,.6,.95)
            area.spaces.active.region_3d.view_rotation=cam.rotation_euler.to_quaternion()
            area.spaces.active.shading.type='MATERIAL'
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,'man_shopping_cart.blend'))
bpy.ops.render.render(write_still=True)
print('BUILD_COMPLETE',len(parts),'mesh parts',len(arm.bones),'bones')
