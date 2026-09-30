extends Node3D

# Sky Island Sandbox - first mobile prototype
# World scale: 1 Godot unit = 1 metre.
# Island target area: 80,000 km² (~282.84 km x 282.84 km square envelope).
# This prototype uses procedural terrain and scalable detail layers.

const AREA_KM2 := 80000.0
const SIDE_M := 282842.7125
const HALF := SIDE_M * 0.5
const GRID := 160
const TERRAIN_STEP := SIDE_M / float(GRID)
const TERRAIN_SIZE := GRID + 1

var camera: Camera3D
var island_root: Node3D
var terrain: MeshInstance3D
var city_root: Node3D
var landmark_root: Node3D
var airport_root: Node3D
var underground_root: Node3D
var sun: DirectionalLight3D
var world_env: WorldEnvironment
var label: Label
var help: Label
var weather_label: Label
var time_slider: HSlider
var weather_menu: OptionButton
var layer_menu: OptionButton

var camera_target := Vector3.ZERO
var camera_distance := 220000.0
var yaw := 0.45
var pitch := -0.55
var dragging := false
var last_touch := Vector2.ZERO
var last_pinch := 0.0
var current_weather := "晴天"

func _ready():
    _build_environment()
    _build_world()
    _build_ui()
    _apply_weather("晴天")
    _set_time(12.0)

func _build_environment():
    world_env = WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var mat := ProceduralSkyMaterial.new()
    mat.sky_top_color = Color("#3b6ea8")
    mat.sky_horizon_color = Color("#d7ecff")
    mat.ground_bottom_color = Color("#1b2430")
    mat.ground_horizon_color = Color("#b8d4e8")
    mat.sun_angle_max = 30.0
    sky.sky_material = mat
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.ambient_light_energy = 0.8
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world_env.environment = env
    add_child(world_env)

    sun = DirectionalLight3D.new()
    sun.light_energy = 1.5
    sun.shadow_enabled = true
    sun.rotation_degrees = Vector3(-45, -25, 0)
    add_child(sun)

func _build_world():
    island_root = Node3D.new()
    island_root.name = "Island_80000km2"
    add_child(island_root)

    _init_streaming_world()

    _make_rivers_and_lakes()
    _make_city()
    _make_landmarks()
    _make_airport()
    _make_underground()

    camera = Camera3D.new()
    camera.name = "FreeCamera"
    camera.current = true
    camera.fov = 55.0
    add_child(camera)
    _update_camera()

func _height(x: float, z: float) -> float:
    var nx := x / SIDE_M
    var nz := z / SIDE_M
    var mountain := exp(-pow((nx + 0.18) * 3.0, 2.0) - pow((nz + 0.02) * 2.1, 2.0))
    mountain += 0.55 * exp(-pow((nx - 0.28) * 4.0, 2.0) - pow((nz + 0.18) * 3.0, 2.0))
    var waves := sin(nx * 18.0 + nz * 5.0) * 0.18 + cos(nz * 21.0 - nx * 3.0) * 0.12
    var broad := sin(nx * 4.0) * cos(nz * 5.0) * 0.25
    return 80.0 + mountain * 2400.0 + broad * 500.0 + waves * 180.0

func _make_terrain() -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for z in range(GRID):
        for x in range(GRID):
            var x0 := -HALF + x * TERRAIN_STEP
            var x1 := x0 + TERRAIN_STEP
            var z0 := -HALF + z * TERRAIN_STEP
            var z1 := z0 + TERRAIN_STEP
            _tri(st, x0,z0,x1,z0,x1,z1)
            _tri(st, x0,z0,x1,z1,x0,z1)
    st.generate_normals()
    return st.commit()

func _tri(st: SurfaceTool, ax:float,az:float,bx:float,bz:float,cx:float,cz:float):
    st.set_uv(Vector2((ax+HALF)/SIDE_M,(az+HALF)/SIDE_M)); st.set_vertex(Vector3(ax,_height(ax,az),az))
    st.set_uv(Vector2((bx+HALF)/SIDE_M,(bz+HALF)/SIDE_M)); st.set_vertex(Vector3(bx,_height(bx,bz),bz))
    st.set_uv(Vector2((cx+HALF)/SIDE_M,(cz+HALF)/SIDE_M)); st.set_vertex(Vector3(cx,_height(cx,cz),cz))

func _box(parent:Node3D, pos:Vector3, size:Vector3, color:Color, name_:String):
    var mi := MeshInstance3D.new()
    mi.name = name_
    var bm := BoxMesh.new()
    bm.size = size
    mi.mesh = bm
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 0.72
    mi.material_override = m
    mi.position = pos
    parent.add_child(mi)
    return mi

func _make_city():
    city_root = Node3D.new()
    city_root.name = "CoreCity"
    island_root.add_child(city_root)
    var city_center := Vector3(38000, _height(38000,-20000)+25, -20000)
    # City lake
    var lake := MeshInstance3D.new()
    var cyl := CylinderMesh.new()
    cyl.top_radius = 3500.0
    cyl.bottom_radius = 3500.0
    cyl.height = 12.0
    lake.mesh = cyl
    var water := StandardMaterial3D.new()
    water.albedo_color = Color("#2d7894")
    water.metallic = 0.15
    water.roughness = 0.12
    lake.material_override = water
    lake.position = Vector3(city_center.x, city_center.y-8, city_center.z)
    lake.scale = Vector3(1.0,1.0,0.62)
    city_root.add_child(lake)

    for i in range(34):
        var a := TAU * float(i) / 34.0
        var r := 5000.0 + (i % 5) * 850.0
        var p := Vector3(city_center.x + cos(a)*r, city_center.y + 70, city_center.z + sin(a)*r)
        var h := 90.0 + float((i*37)%170)
        _box(city_root,p,Vector3(180+((i%4)*55),h,180+((i%3)*45)),Color("#aeb9c5"),"CityBuilding_%02d"%i)
    # a few skyline anchors, deliberately sparse
    for i in range(5):
        var a := 0.6 + i*1.1
        var p := Vector3(city_center.x+cos(a)*7200,city_center.y+260,city_center.z+sin(a)*7200)
        _box(city_root,p,Vector3(260,520+(i%2)*170,260),Color("#8197a8"),"Skyline_%02d"%i)

func _make_rivers_and_lakes():
    # Broad schematic water bodies to establish the continent's hydrology.
    var water_mat := StandardMaterial3D.new()
    water_mat.albedo_color = Color("#2f7690")
    water_mat.roughness = 0.16
    for i in range(7):
        var lake := MeshInstance3D.new()
        var cm := CylinderMesh.new()
        cm.top_radius = 900.0 + i*260.0
        cm.bottom_radius = cm.top_radius
        cm.height = 10.0
        lake.mesh = cm
        lake.material_override = water_mat
        var x := -80000.0 + i*26000.0
        var z := -50000.0 + sin(i*1.7)*42000.0
        lake.position = Vector3(x,_height(x,z)-8,z)
        lake.scale = Vector3(1.6,1.0,0.8)
        island_root.add_child(lake)

func _make_landmarks():
    landmark_root = Node3D.new()
    landmark_root.name = "ScatteredBeautifulLandmarks"
    island_root.add_child(landmark_root)
    var places = [
        Vector3(-62000,0,-18000), Vector3(-18000,0,65000),
        Vector3(8000,0,72000), Vector3(72000,0,26000),
        Vector3(76000,0,-52000), Vector3(-70000,0,52000),
        Vector3(20000,0,-76000), Vector3(-42000,0,-70000)
    ]
    for i in range(places.size()):
        var p:Vector3 = places[i]
        p.y = _height(p.x,p.z)+60
        var base := _box(landmark_root,p,Vector3(900,120,900),Color("#d8c9a7"),"Landmark_%02d"%i)
        # small central tower gives each landmark a readable silhouette
        _box(landmark_root,p+Vector3(0,300,0),Vector3(260,600,260),Color("#c9b28c"),"LandmarkTower_%02d"%i)

func _make_airport():
    airport_root = Node3D.new()
    airport_root.name = "RemoteAirport"
    island_root.add_child(airport_root)
    var x := -90000.0
    var z := 85000.0
    var y := _height(x,z)+25
    _box(airport_root,Vector3(x,y,z),Vector3(26000,30,1800),Color("#343c44"),"Runway")
    _box(airport_root,Vector3(x,y+45,z-2200),Vector3(7000,90,1800),Color("#b6bcc2"),"Terminal")
    _box(airport_root,Vector3(x+6500,y+160,z+1800),Vector3(1800,320,2200),Color("#66737e"),"Hangar")
    _box(airport_root,Vector3(x-15000,y+60,z+2000),Vector3(1000,120,1000),Color("#6b747b"),"AirportService")

func _make_underground():
    underground_root = Node3D.new()
    underground_root.name = "Underground"
    island_root.add_child(underground_root)
    # Kept mostly hidden until the layer selector is used.
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color("#39434b")
    var pipe := BoxMesh.new()
    pipe.size = Vector3(190000,9000,9000)
    var tunnel := MeshInstance3D.new()
    tunnel.name = "Minus2_EastWest_HollowStructure"
    tunnel.mesh = pipe
    tunnel.material_override = mat
    tunnel.position = Vector3(0,-1200,0)
    underground_root.add_child(tunnel)
    underground_root.visible = false

func _build_ui():
    var layer := CanvasLayer.new()
    add_child(layer)
    var panel := PanelContainer.new()
    panel.position = Vector2(18,18)
    panel.size = Vector2(310,230)
    layer.add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation",8)
    panel.add_child(box)

    label = Label.new()
    label.text = "天空岛 · 80,000 km²"
    label.add_theme_font_size_override("font_size",20)
    box.add_child(label)

    weather_label = Label.new()
    weather_label.text = "天气：晴天"
    box.add_child(weather_label)

    weather_menu = OptionButton.new()
    for w in ["晴天","多云","小雨","暴雨","大雾","雷暴"]:
        weather_menu.add_item(w)
    weather_menu.item_selected.connect(func(i): _apply_weather(weather_menu.get_item_text(i)))
    box.add_child(weather_menu)

    var time_title := Label.new()
    time_title.text = "岛上时间"
    box.add_child(time_title)
    time_slider = HSlider.new()
    time_slider.min_value = 0
    time_slider.max_value = 24
    time_slider.step = 0.1
    time_slider.value = 12
    time_slider.value_changed.connect(_set_time)
    box.add_child(time_slider)

    layer_menu = OptionButton.new()
    for s in ["地表","-1层（预留）","-2层 / 东西向贯穿结构"]:
        layer_menu.add_item(s)
    layer_menu.item_selected.connect(_layer_selected)
    box.add_child(layer_menu)

    help = Label.new()
    help.text = "手机：单指拖动旋转 · 双指捏合缩放\n双指拖动平移 · 右侧可继续扩展交互"
    help.position = Vector2(18,260)
    layer.add_child(help)

func _input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            last_touch = event.position
        else:
            dragging = false
    elif event is InputEventScreenDrag:
        var delta := event.position - last_touch
        last_touch = event.position
        if event.index == 0:
            yaw -= delta.x * 0.004
            pitch = clamp(pitch - delta.y * 0.003, -1.35, -0.12)
            _update_camera()
    elif event is InputEventScreenPinch:
        camera_distance = clamp(camera_distance / max(event.factor,0.05), 900.0, 360000.0)
        _update_camera()
    elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        yaw -= event.relative.x * 0.004
        pitch = clamp(pitch - event.relative.y * 0.003, -1.35, -0.12)
        _update_camera()
    elif event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
            camera_distance = max(900.0,camera_distance*0.85)
            _update_camera()
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
            camera_distance = min(360000.0,camera_distance*1.18)
            _update_camera()

func _update_camera():
    if not camera: return
    var dir := Vector3(cos(pitch)*sin(yaw), sin(pitch), cos(pitch)*cos(yaw))
    camera.position = camera_target + dir * camera_distance
    camera.look_at(camera_target,Vector3.UP)

func _apply_weather(w:String):
    current_weather = w
    weather_label.text = "天气：" + w
    var env := world_env.environment
    var sky_mat := env.sky.sky_material as ProceduralSkyMaterial
    if w == "晴天":
        sky_mat.sky_top_color = Color("#3b6ea8")
        sun.light_energy = 1.5
    elif w == "多云":
        sky_mat.sky_top_color = Color("#536575")
        sun.light_energy = 0.9
    elif w == "小雨":
        sky_mat.sky_top_color = Color("#43515c")
        sun.light_energy = 0.65
    elif w == "暴雨":
        sky_mat.sky_top_color = Color("#25313b")
        sun.light_energy = 0.35
    elif w == "大雾":
        sky_mat.sky_top_color = Color("#8b979e")
        sun.light_energy = 0.45
    elif w == "雷暴":
        sky_mat.sky_top_color = Color("#1c2430")
        sun.light_energy = 0.25

func _set_time(t:float):
    var angle := (t / 24.0) * 360.0 - 90.0
    sun.rotation_degrees = Vector3(-max(8.0,sin(deg_to_rad(angle))*65.0), angle, 0)
    sun.light_energy = max(0.12, sin(deg_to_rad(angle))*1.5 + 0.2) if current_weather != "暴雨" else 0.18

func _layer_selected(i:int):
    underground_root.visible = i == 2
    if chunk_root:
        chunk_root.visible = i == 0
    city_root.visible = i == 0
    landmark_root.visible = i == 0
    airport_root.visible = i == 0
    if i == 1:
        # First placeholder layer: show a subtle underground plane by reusing the core root.
        if chunk_root:
            chunk_root.visible = false
        city_root.visible = false
        landmark_root.visible = false
        airport_root.visible = false
        underground_root.visible = false
    _update_camera()
