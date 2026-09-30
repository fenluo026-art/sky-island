class_name WorldCoordinates
extends RefCounted

const WorldDef = preload("res://scripts/core/world_definition.gd")

static func world_to_chunk(position: Vector3) -> Vector2i:
    return Vector2i(
        floori(position.x / WorldDef.CHUNK_SIZE_M),
        floori(position.z / WorldDef.CHUNK_SIZE_M)
    )

static func chunk_to_world(coordinate: Vector2i) -> Vector3:
    return Vector3(
        (float(coordinate.x) + 0.5) * WorldDef.CHUNK_SIZE_M,
        0.0,
        (float(coordinate.y) + 0.5) * WorldDef.CHUNK_SIZE_M
    )

static func chunk_origin(coordinate: Vector2i) -> Vector3:
    return Vector3(
        float(coordinate.x) * WorldDef.CHUNK_SIZE_M,
        0.0,
        float(coordinate.y) * WorldDef.CHUNK_SIZE_M
    )

static func visual_position(layer_id: int, coordinate: Vector2i) -> Vector3:
    var p := chunk_origin(coordinate)
    p.y = WorldDef.layer_height(layer_id)
    return p
