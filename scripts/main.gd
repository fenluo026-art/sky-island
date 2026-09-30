extends Node3D

const CHUNK_SIZE = 40.0
const LOAD_RADIUS = 2
const WORLD_RADIUS = 160.0
const CAMERA_DISTANCE = 360.0

var camera
var chunks = {}
var seed_value = 20260930
var noise

func _ready():
    noise = FastNoiseLite.new()
    noise.seed = seed_value
    noise.frequency = 0.025

    _make_environment()
    _make_camera()
    _make_roots()
    _make_island()
    _make_water()
    _stream_chunks(Vector3.ZERO)

func _process(_delta):
    if camera:
        camera.look_at(Vector3.ZERO, Vector3.UP)

func _make_environment():
    var env_node = WorldEnvironment.new()
    var env = Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.055, 0.085, 0.14)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.72, 0.78, 0.9)
    env.ambient_light_energy = 0.9
    env_node.environment = env
    add_child(env_node)

    var sun = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52, -25, 0)
    sun.light_energy = 1.15
    sun.shadow_enabled = true
    add_child(sun)

func _make_camera():
    camera = Camera3D.new()
    camera.current = true
    camera.position = Vector3(0, 260, 250)
    add_child(camera)

func _make_roots():
    var terrain = Node3D.new()
    terrain.name = "TerrainChunks"
    add_child(terrain)
    var water = Node3D.new()
    water.name = "Water"
    add_child(water)

func _make_island():
    var mesh = CylinderMesh.new()
    mesh.top_radius = WORLD_RADIUS
    mesh.bottom_radius = WORLD_RADIUS * 0.82
    mesh.height = 7.0
    mesh.radial_segments = 96
    mesh.rings = 4

    var island = MeshInstance3D.new()
    island.mesh = mesh
    island.position.y = -5.0
    island.material_override = _material(Color(0.12, 0.15, 0.19))
    add_child(island)

func _make_water():
    var lake = CylinderMesh.new()
    lake.top_radius = 22.0
    lake.bottom_radius = 22.0
    lake.height = 0.2
    lake.radial_segments = 48

    var lake_node = MeshInstance3D.new()
    lake_node.mesh = lake
    lake_node.position = Vector3(10, 0, -58)
    lake_node.scale.z = 0.62
    lake_node.material_override = _material(Color(0.10, 0.40, 0.62))
    add_child(lake_node)

func _stream_chunks(center):
    var cx = int(floor(center.x / CHUNK_SIZE))
    var cz = int(floor(center.z / CHUNK_SIZE))

    for x in range(cx - LOAD_RADIUS, cx + LOAD_RADIUS + 1):
        for z in range(cz - LOAD_RADIUS, cz + LOAD_RADIUS + 1):
            var key = Vector2i(x, z)
            if not chunks.has(key):
                _create_chunk(key)

func _create_chunk(key):
    var root = Node3D.new()
    root.name = "Chunk_%d_%d" % [key.x, key.y]
    root.position = Vector3(key.x * CHUNK_SIZE, 0, key.y * CHUNK_SIZE)
    add_child(root)
    chunks[key] = root

    var ground = PlaneMesh.new()
    ground.size = Vector2(CHUNK_SIZE, CHUNK_SIZE)
    ground.subdivide_width = 4
    ground.subdivide_depth = 4

    var surface = MeshInstance3D.new()
    surface.mesh = ground
    surface.position.y = 0.2
    surface.material_override = _material(_terrain_color(key))
    root.add_child(surface)

    for i in range(3):
        var hill = CylinderMesh.new()
        hill.top_radius = 3.0 + i
        hill.bottom_radius = 5.0 + i
        hill.height = 4.0 + i * 2.0
        hill.radial_segments = 8

        var hill_node = MeshInstance3D.new()
        hill_node.mesh = hill
        hill_node.position = Vector3(
            noise.get_noise_2d(key.x * 17 + i, key.y * 23 + i) * 12.0,
            hill.height * 0.5,
            noise.get_noise_2d(key.x * 31 + i, key.y * 11 + i) * 12.0
        )
        hill_node.material_override = _material(Color(0.18, 0.39, 0.21))
        root.add_child(hill_node)

func _terrain_color(key):
    var n = noise.get_noise_2d(key.x * 2.7, key.y * 2.7)
    if n > 0.35:
        return Color(0.20, 0.42, 0.22)
    if n < -0.35:
        return Color(0.27, 0.40, 0.20)
    return Color(0.24, 0.48, 0.25)

func _material(color):
    var material = StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.9
    return material
