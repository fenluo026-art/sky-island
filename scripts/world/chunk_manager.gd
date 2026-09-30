class_name ChunkManager
extends Node3D

const WorldDef = preload("res://scripts/core/world_definition.gd")
const WorldCoords = preload("res://scripts/core/world_coordinates.gd")
const ChunkKeyType = preload("res://scripts/core/chunk_key.gd")
const Lod = preload("res://scripts/core/lod_profile.gd")
const Budget = preload("res://scripts/core/performance_budget.gd")

var active_layer_id: int = WorldDef.DEFAULT_LAYER_ID
var loaded_chunks: Dictionary = {}
var last_center: Vector2i = Vector2i(999999, 999999)
var debug_materials: Dictionary = {}

func _ready() -> void:
    name = "ChunkManager"

func set_active_layer(layer_id: int) -> void:
    if not WorldDef.is_valid_layer(layer_id) or layer_id == active_layer_id:
        return
    _unload_all()
    active_layer_id = layer_id
    last_center = Vector2i(999999, 999999)

func update_streaming(world_position: Vector3) -> void:
    var center := WorldCoords.world_to_chunk(world_position)
    if center == last_center and not loaded_chunks.is_empty():
        _update_lod(world_position)
        return
    last_center = center

    var wanted: Dictionary = {}
    for x in range(center.x - Budget.STREAM_LOAD_RADIUS, center.x + Budget.STREAM_LOAD_RADIUS + 1):
        for z in range(center.y - Budget.STREAM_LOAD_RADIUS, center.y + Budget.STREAM_LOAD_RADIUS + 1):
            var coordinate := Vector2i(x, z)
            var key := ChunkKeyType.new(active_layer_id, coordinate)
            wanted[key.id()] = key

    for id in wanted:
        if not loaded_chunks.has(id):
            _create_chunk(wanted[id])

    var remove_ids: Array[String] = []
    for id in loaded_chunks:
        var key: ChunkKeyType = loaded_chunks[id]["key"]
        var dx := abs(key.coordinate.x - center.x)
        var dz := abs(key.coordinate.y - center.y)
        if max(dx, dz) > Budget.STREAM_UNLOAD_RADIUS:
            remove_ids.append(id)

    for id in remove_ids:
        _unload_chunk(id)

    _update_lod(world_position)

func _create_chunk(key: ChunkKeyType) -> void:
    if loaded_chunks.size() >= Budget.MAX_LOADED_CHUNKS:
        return

    var root := Node3D.new()
    root.name = "Chunk_%s" % key.id().replace(":", "_")
    root.position = WorldCoords.visual_position(key.layer_id, key.coordinate)
    add_child(root)

    var surface := MeshInstance3D.new()
    surface.name = "DebugSurface"
    var mesh := PlaneMesh.new()
    mesh.size = Vector2(WorldDef.CHUNK_SIZE_M, WorldDef.CHUNK_SIZE_M)
    mesh.subdivide_width = 2
    mesh.subdivide_depth = 2
    surface.mesh = mesh
    surface.material_override = _material_for_layer(key.layer_id)
    root.add_child(surface)

    loaded_chunks[key.id()] = {
        "key": key,
        "root": root,
        "surface": surface,
        "lod": 2
    }

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

func _update_lod(world_position: Vector3) -> void:
    for id in loaded_chunks:
        var data: Dictionary = loaded_chunks[id]
        var key: ChunkKeyType = data["key"]
        var center := WorldCoords.chunk_to_world(key.coordinate)
        var distance := world_position.distance_to(Vector3(center.x, world_position.y, center.z))
        var level := Lod.level_for_distance(distance)
        if level == data["lod"]:
            continue
        var surface: MeshInstance3D = data["surface"]
        var mesh: PlaneMesh = surface.mesh
        var subdivisions := Lod.subdivisions_for_level(level)
        mesh.subdivide_width = subdivisions
        mesh.subdivide_depth = subdivisions
        data["lod"] = level
        loaded_chunks[id] = data

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
