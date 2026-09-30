extends Node3D
## Sky Island - Phase 2
## 80,000 km² logical world, procedural terrain/water/forest, chunk streaming scaffold.

const WORLD_AREA_KM2 := 80000.0
const WORLD_RADIUS := 160.0
const WORLD_SCALE_KM_PER_UNIT := 0.7
const CHUNK_SIZE := 40.0
const LOAD_RADIUS := 2
const DETAIL_RADIUS := 1
const CAMERA_OVERVIEW := 360.0
const CAMERA_MIN := 18.0
const CAMERA_MAX := 620.0

var camera: Camera3D
var world_root: Node3D
var terrain_root: Node3D
var water_root: Node3D
var forest_root: Node3D
var zone_root: Node3D
var ui: CanvasLayer
var distance := CAMERA_OVERVIEW
var yaw := 0.55
var pitch := -0.48
var target := Vector3.ZERO
var level := 0
var dragging := false
var last_touch := Vector2.ZERO
var generated_chunks: Dictionary = {}
var noise := FastNoiseLite.new()

var zones = [
    {"name":"中央庄园区","pos":Vector3(-12,2,2),"size":24.0,"color":Color(0.86,0.76,0.48)},
    {"name":"生活居住区","pos":Vector3(35,2,12),"size":30.0,"color":Color(0.45,0.72,0.92)},
    {"name":"自然生态区","pos":Vector3(-62,2,-35),"size":48.0,"color":Color(0.28,0.62,0.34)},
    {"name":"湖泊水系区","pos":Vector3(12,2,-58),"size":30.0,"color":Color(0.22,0.55,0.78)},
    {"name":"娱乐休闲区","pos":Vector3(68,2,-30),"size":24.0,"color":Color(0.78,0.42,0.70)},
    {"name":"私人机场","pos":Vector3(70,2,45),"size":34.0,"color":Color(0.55,0.57,0.62)},
    {"name":"工业与能源区","pos":Vector3(-55,2,50),"size":30.0,"color":Color(0.55,0.55,0.58)},
    {"name":"农业区","pos":Vector3(-5,2,72),"size":30.0,"color":Color(0.45,0.68,0.30)}
]

func _ready() -> void:
    noise.seed = 20260930
    noise.frequency = 0.025
    noise.fractal_octaves = 4
    _setup_environment()
    _build_roots()
    _make_island_shell()
    _build_waterways()
    _build_zones()
    _build_camera()
    _build_ui()
    _set_level(0)
    _update_camera()

func _process(_delta: float) -> void:
    _update_streaming()
    _update_camera()

func _setup_environment() -> void:
    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color(0.055,0.085,0.14)
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color(0.72,0.78,0.9)
    e.ambient_light_energy = 0.95
    e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.environment = e
    add_child(env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52,-25,0)
    sun.light_energy = 1.15
    sun.shadow_enabled = true
    add_child(sun)

func _build_roots() -> void:
    world_root = Node3D.new()
    world_root.name = "World"
    add_child(world_root)
    terrain_root = Node3D.new()
    terrain_root.name = "TerrainChunks"
    world_root.add_child(terrain_root)
    water_root = Node3D.new()
    water_root.name = "Water"
    world_root.add_child(water_root)
    forest_root = Node3D.new()
    forest_root.name = "Forest"
    world_root.add_child(forest_root)
    zone_root = Node3D.new()
    zone_root.name = "Zones"
    world_root.add_child(zone_root)

func _make_island_shell() -> void:
    var mesh := CylinderMesh.new()
    mesh.top_radius = WORLD_RADIUS
    mesh.bottom_radius = WORLD_RADIUS * 0.82
    mesh.height = 7.0
    mesh.radial_segments = 96
    mesh.rings = 4
    var mi := MeshInstance3D.new()
    mi.mesh = mesh
    mi.position.y = -5.0
    mi.material_override = _mat(Color(0.12,0.15,0.19), 1.0)
    world_root.add_child(mi)

func _update_streaming() -> void:
    if camera == null:
        return
    var cx := int(floor(target.x / CHUNK_SIZE))
    var cz := int(floor(target.z / CHUNK_SIZE))
    var wanted := {}
    for x in range(cx-LOAD_RADIUS, cx+LOAD_RADIUS+1):
        for z in range(cz-LOAD_RADIUS, cz+LOAD_RADIUS+1):
            var key := Vector2i(x,z)
            wanted[key] = true
            if not generated_chunks.has(key):
                _generate_chunk(key, abs(x-cx)+abs(z-cz) <= DETAIL_RADIUS)
    var to_remove: Array = []
    for key in generated_chunks.keys():
        if not wanted.has(key):
            to_remove.append(key)
    for key in to_remove:
        var node: Node = generated_chunks[key]
        if is_instance_valid(node):
            node.queue_free()
        generated_chunks.erase(key)

func _generate_chunk(key: Vector2i, detailed: bool) -> void:
    var root := Node3D.new()
    root.name = "Chunk_%d_%d" % [key.x,key.y]
    root.position = Vector3(key.x*CHUNK_SIZE,0,key.y*CHUNK_SIZE)
    terrain_root.add_child(root)
    generated_chunks[key] = root

    var ground := PlaneMesh.new()
    ground.size = Vector2(CHUNK_SIZE,CHUNK_SIZE)
    ground.subdivide_width = 12 if detailed else 4
    ground.subdivide_depth = 12 if detailed else 4
    var surface := MeshInstance3D.new()
    surface.mesh = ground
    surface.position.y = 0.2
    surface.material_override = _mat(_terrain_color(key), 1.0)
    root.add_child(surface)

    var hill_count := 7 if detailed else 3
    for i in range(hill_count):
        var px := (noise.get_noise_2d(key.x*17+i*5,key.y*23+i*7))*CHUNK_SIZE*0.42
        var pz := (noise.get_noise_2d(key.x*31+i*3,key.y*11+i*9))*CHUNK_SIZE*0.42
        var h := 2.5 + abs(noise.get_noise_2d(key.x*5+i,key.y*7+i))*9.0
        var hill := CylinderMesh.new()
        hill.top_radius = 2.2 + float(i%3)*1.7
        hill.bottom_radius = hill.top_radius*1.55
        hill.height = h
        hill.radial_segments = 10 if detailed else 7
        var hm := MeshInstance3D.new()
        hm.mesh = hill
        hm.position = Vector3(px,h*0.5,pz)
        hm.material_override = _mat(Color(0.18,0.39,0.21),1.0)
        root.add_child(hm)

    if detailed:
        _spawn_forest(root, key)

func _spawn_forest(root: Node3D, key: Vector2i) -> void:
    var density := 18
    for i in range(density):
        var x := noise.get_noise_2d(key.x*101+i*13,key.y*71+i*3)*CHUNK_SIZE*0.48
        var z := noise.get_noise_2d(key.x*47+i*19,key.y*83+i*5)*CHUNK_SIZE*0.48
        var trunk := CylinderMesh.new()
        trunk.top_radius = 0.18
        trunk.bottom_radius = 0.25
        trunk.height = 1.7 + float(i%4)*0.45
        trunk.radial_segments = 6
        var tree := MeshInstance3D.new()
        tree.mesh = trunk
        tree.position = Vector3(x,1.0,z)
        tree.material_override = _mat(Color(0.22,0.25,0.18),1.0)
        root.add_child(tree)

        var crown := SphereMesh.new()
        crown.radius = 1.2 + float(i%3)*0.3
        crown.height = crown.radius*1.7
        var leaves := MeshInstance3D.new()
        leaves.mesh = crown
        leaves.position = tree.position + Vector3(0,1.4,0)
        leaves.material_override = _mat(Color(0.14,0.42,0.19),1.0)
        root.add_child(leaves)

func _build_waterways() -> void:
    # Large lake
    var lake := CylinderMesh.new()
    lake.top_radius = 22.0
    lake.bottom_radius = 22.0
    lake.height = 0.25
    lake.radial_segments = 64
    var lm := MeshInstance3D.new()
    lm.mesh = lake
    lm.position = Vector3(10,-0.05,-58)
    lm.scale.z = 0.62
    lm.material_override = _water_mat()
    water_root.add_child(lm)

    # Two procedural-looking river ribbons following deterministic curves.
    for river_id in range(2):
        var curve := Curve3D.new()
        var points := 18
        for i in range(points):
            var t := float(i)/(points-1)
            var x := -WORLD_RADIUS*0.88 + t*WORLD_RADIUS*1.76
            var z := (-48.0 if river_id==0 else 42.0) + sin(t*TAU*1.35+river_id)*15.0
            curve.add_point(Vector3(x,0.08,z))
        var path := Path3D.new()
        path.curve = curve
        water_root.add_child(path)
        var ribbon := PathFollow3D.new()
        path.add_child(ribbon)
        # Segment meshes approximate the river; keeps it cheap on mobile.
        for i in range(points-1):
            var a := curve.get_point_position(i)
            var b := curve.get_point_position(i+1)
            var seg := BoxMesh.new()
            seg.size = Vector3((b-a).length(),0.12,3.0)
            var mi := MeshInstance3D.new()
            mi.mesh = seg
            mi.position = (a+b)*0.5
            mi.rotation.y = atan2(b.x-a.x,b.z-a.z)
            mi.material_override = _water_mat()
            water_root.add_child(mi)

func _water_mat() -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = Color(0.10,0.40,0.62,0.82)
    m.roughness = 0.18
    m.metallic = 0.05
    m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    return m

func _terrain_color(key: Vector2i) -> Color:
    var n := noise.get_noise_2d(key.x*2.7,key.y*2.7)
    if n > 0.35:
        return Color(0.20,0.42,0.22)
    if n < -0.35:
        return Color(0.27,0.40,0.20)
    return Color(0.24,0.48,0.25)

func _build_zones() -> void:
    for z in zones:
        var marker := MeshInstance3D.new()
        var box := BoxMesh.new()
        box.size = Vector3(z.size,0.45,z.size*0.75)
        marker.mesh = box
        marker.position = z.pos + Vector3.UP*1.2
        marker.material_override = _mat(z.color,0.55)
        zone_root.add_child(marker)

func _build_camera() -> void:
    camera = Camera3D.new()
    camera.current = true
    camera.fov = 54.0
    add_child(camera)

func _build_ui() -> void:
    ui = CanvasLayer.new()
    add_child(ui)
    var panel := ColorRect.new()
    panel.position = Vector2(18,18)
    panel.size = Vector2(430,92)
    panel.color = Color(0.03,0.05,0.08,0.88)
    ui.add_child(panel)

    var title := Label.new()
    title.position = Vector2(18,10)
    title.text = "天穹之境 · 第二阶段"
    title.add_theme_font_size_override("font_size",24)
    panel.add_child(title)

    var sub := Label.new()
    sub.position = Vector2(18,50)
    sub.text = "80,000 km² · 程序地形 · 河流湖泊 · 森林 · Chunk"
    sub.add_theme_color_override("font_color",Color(0.65,0.75,0.86))
    panel.add_child(sub)

    var help := Label.new()
    help.position = Vector2(18,116)
    help.text = "拖动旋转 · 双指/滚轮缩放 · 点击区域聚焦"
    help.add_theme_color_override("font_color",Color(0.8,0.86,0.92))
    ui.add_child(help)

    var levels := ["地表","-1 生活","-2 军事","-3 工业","-4 能源"]
    for i in range(levels.size()):
        var b := Button.new()
        b.text = levels[i]
        b.position = Vector2(18+i*82,156)
        b.size = Vector2(76,42)
        b.pressed.connect(_set_level.bind(i))
        ui.add_child(b)

    var side := VBoxContainer.new()
    side.position = Vector2(18,220)
    side.size = Vector2(220,420)
    ui.add_child(side)
    var header := Label.new()
    header.text = "区域"
    header.add_theme_font_size_override("font_size",20)
    side.add_child(header)

    for idx in range(zones.size()):
        var b := Button.new()
        b.text = zones[idx].name
        b.custom_minimum_size = Vector2(210,38)
        b.pressed.connect(_focus_zone.bind(idx))
        side.add_child(b)

    var reset := Button.new()
    reset.text = "返回全岛"
    reset.position = Vector2(18,660)
    reset.size = Vector2(210,42)
    reset.pressed.connect(_reset_view)
    ui.add_child(reset)

    var info := Label.new()
    info.name = "Info"
    info.position = Vector2(450,18)
    info.size = Vector2(800,80)
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    info.text = "地表层"
    info.add_theme_font_size_override("font_size",22)
    ui.add_child(info)

func _set_level(v:int) -> void:
    level = v
    var labels=["地表层","-1层 · 生活/交通层","-2层 · 军事/大型机库/东西向贯穿通道","-3层 · 工业/仓储/设备维护","-4层 · 能源/控制/悬浮系统"]
    ui.get_node("Info").text = labels[v]

func _focus_zone(idx:int) -> void:
    target = zones[idx].pos
    distance = clamp(zones[idx].size*2.4,32.0,100.0)

func _reset_view() -> void:
    target=Vector3.ZERO
    distance=CAMERA_OVERVIEW
    yaw=0.55
    pitch=-0.48

func _update_camera() -> void:
    if camera==null:return
    var dir:=Vector3(cos(pitch)*sin(yaw),sin(pitch),cos(pitch)*cos(yaw))
    camera.position=target+dir*distance
    camera.look_at(target,Vector3.UP)

func _input(event:InputEvent)->void:
    if event is InputEventScreenTouch:
        if event.pressed:
            dragging=true
            last_touch=event.position
        else:
            dragging=false
    elif event is InputEventScreenDrag and dragging:
        var d:=event.position-last_touch
        yaw-=d.x*0.006
        pitch=clamp(pitch-d.y*0.004,-1.35,-0.12)
        last_touch=event.position
    elif event is InputEventMouseButton:
        if event.button_index==MOUSE_BUTTON_WHEEL_UP and event.pressed:
            distance=max(CAMERA_MIN,distance*0.88)
        elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
            distance=min(CAMERA_MAX,distance*1.14)
        elif event.button_index==MOUSE_BUTTON_LEFT:
            dragging=event.pressed
            last_touch=event.position
    elif event is InputEventMouseMotion and dragging:
        yaw-=event.relative.x*0.005
        pitch=clamp(pitch-event.relative.y*0.004,-1.35,-0.12)

func _mat(color:Color,alpha:float)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=Color(color.r,color.g,color.b,alpha)
    m.roughness=0.9
    if alpha<0.99:m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
    return m
