class_name ChunkKey
extends RefCounted

var layer_id: int
var coordinate: Vector2i

func _init(p_layer_id: int, p_coordinate: Vector2i) -> void:
    layer_id = p_layer_id
    coordinate = p_coordinate

func id() -> String:
    return "%d:%d:%d" % [layer_id, coordinate.x, coordinate.y]

func equals(other: ChunkKey) -> bool:
    return other != null and layer_id == other.layer_id and coordinate == other.coordinate
