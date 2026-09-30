class_name ChunkManager
extends Node3D

const WorldDef = preload("res://scripts/core/world_definition.gd")
const WorldCoords = preload("res://scripts/core/world_coordinates.gd")
const ChunkKeyType = preload("res://scripts/core/chunk_key.gd")
const Lod = preload("res://scripts/core/lod_profile.gd")
const Budget = preload("res://scripts/core/performance_budget.gd")
const TerrainGeneratorType = preload("res://scripts/world/terrain_generator.gd")

var active_layer_id: int = WorldDef.DEFAULT_LAYER_ID
var loaded_chunks: Dictionary = {}
var last_center: Vector2i = Vector2i(999999, 999999)
var debug_materials: Dictionary = {}
var terrain_generator: TerrainGenerator

func _ready() -> void:
    name = "ChunkManager"
    terrain_generator = TerrainGeneratorType.new()

func set_active_layer(layer_id: int) -> void:
    if not WorldDef.is_valid_layer(layer_id) or layer_id == active_layer_id:
        return
    _unload_all()
    active_layer_id = layer_id
    last_center = Vector2i(999999, 999999)

func update_streaming(world_position: Vector3) -> void:
    if active_layer_id != WorldDef.DEFAULT_LAYER_ID:
        _update_debug_layers(world_position)
        return

    var center := WorldCoords.world_to_chunk(world_position)
    if center == last_center and not loaded_chunks.is_empty():
        _update_lod(world_position)
        return
    last_center = center

    var wanted: Dictionary = {}
    for x in range(center.x - Budget.STREAM_LOAD_RADIUS, center.x + Budget.STREAM_LOAD_RADIUS + 1):
        for z in range(center.y - Budget.STREAM_LOAD_RADIUS, center.y + Budget.STREAM_LOAD_RADIUS + 1):
            var coordinate := Vector2i(x, z)
            var center_world := WorldCoords.chunk_to_world(coordinate)
            if not _inside_island(center_world.x, center_world.z):
                continue
            var key := ChunkKeyType.new(active_layer_id, coordinate)
            wanted[key.id()] = key

    for id in wanted:
        if not loaded_chunks.has(id):
            _create_chunk(wanted[id])

    var remove_ids: Array[String] = []
    for id in loaded_chunks:
        var key: ChunkKeyType = loaded_chunks[id]["key"]
        var dx: int = abs(key.coordinate.x - center.x)
        var dz: int = abs(key.coordinate.y - center.y)
        if max(dx, dz) > Budget.STREAM_UNLOAD_RADIUS:
            remove_ids.append(id)

    for id in remove_ids:
        _unload_chunk(id)

    _update_lod(world_position)

func _inside_island(wx: float, wz: float) -> bool:
    var ellipse := Vector2(wx / 159000.0, wz / 126000.0)
    return ellipse.length() < 1.08

func _create_chunk(key: ChunkKeyType) -> void:
    if loaded_chunks.size() >= Budget.MAX_LOADED_CHUNKS:
        return

    var root := Node3D.new()
    root.name = "Chunk_%s" % key.id().replace(":", "_")
    root.position = WorldCoords.visual_position(key.layer_id, key.coordinate)
    add_child(root)

    var surface := MeshInstance3D.new()
    surface.name = "TerrainSurface"
    surface.material_override = _terrain_material()
    surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
    root.add_child(surface)

    var data := {
        "key": key,
        "root": root,
        "surface": surface,
        "lod": -1
    }
    loaded_chunks[key.id()] = data
    _set_chunk_lod(data, 0)

func _set_chunk_lod(data: Dictionary, level: int) -> void:
    if data["lod"] == level:
        return
    var key: ChunkKeyType = data["key"]
    var surface: MeshInstance3D = data["surface"]
    var grid_size := Lod.grid_size_for_level(level)
    surface.mesh = terrain_generator.build_chunk_mesh(key.coordinate.x, key.coordinate.y, grid_size)
    data["lod"] = level

func _update_lod(world_position: Vector3) -> void:
    for id in loaded_chunks:
        var data: Dictionary = loaded_chunks[id]
        var key: ChunkKeyType = data["key"]
        var center := WorldCoords.chunk_to_world(key.coordinate)
        var distance := world_position.distance_to(Vector3(center.x, world_position.y, center.z))
        var level := Lod.level_for_distance(distance)
        _set_chunk_lod(data, level)
        loaded_chunks[id] = data

func _update_debug_layers(world_position: Vector3) -> void:
    if loaded_chunks.is_empty():
        var center := WorldCoords.world_to_chunk(world_position)
        for x in range(center.x - 1, center.x + 2):
            for z in range(center.y - 1, center.y + 2):
                _create_debug_chunk(ChunkKeyType.new(active_layer_id, Vector2i(x, z)))

func _create_debug_chunk(key: ChunkKeyType) -> void:
    if loaded_chunks.has(key.id()):
        return
    var root := Node3D.new()
    root.name = "DebugChunk_%s" % key.id().replace(":", "_")
    root.position = WorldCoords.visual_position(key.layer_id, key.coordinate)
    add_child(root)
    var surface := MeshInstance3D.new()
    var mesh := PlaneMesh.new()
    mesh.size = Vector2(WorldDef.CHUNK_SIZE_M, WorldDef.CHUNK_SIZE_M)
    surface.mesh = mesh
    surface.material_override = _material_for_layer(key.layer_id)
    root.add_child(surface)
    loaded_chunks[key.id()] = {"key": key, "root": root, "surface": surface, "lod": 0}

func _unload_chunk(id: String) -> void:
    if not loaded_chunks.has(id):
        return
    var data: Dictionary = loaded_chunks[id]
    var root: Node3D = data["root"]
    root.queue_free()
    loaded_chunks.erase(id)

func _unload_all() -> void:
    for id in loaded_chunks.keys():
        var data: Dictionary = loaded_chunks[id]
        var root: Node3D = data["root"]
        root.queue_free()
    loaded_chunks.clear()

func _terrain_material() -> Material:
    var material := StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.roughness = 1.0
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
    return material

func _material_for_layer(layer_id: int) -> Material:
    if debug_materials.has(layer_id):
        return debug_materials[layer_id]
    var material := StandardMaterial3D.new()
    material.roughness = 1.0
    material.albedo_color = _layer_color(layer_id)
    debug_materials[layer_id] = material
    return material

func _layer_color(layer_id: int) -> Color:
    match layer_id:
        0:
            return Color(0.20, 0.45, 0.26)
        -1:
            return Color(0.26, 0.39, 0.55)
        -2:
            return Color(0.38, 0.31, 0.25)
        -3:
            return Color(0.36, 0.36, 0.39)
        -4:
            return Color(0.28, 0.25, 0.38)
        _:
            return Color(0.35, 0.35, 0.35)
