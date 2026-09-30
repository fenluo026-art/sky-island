class_name WorldRegion
extends RefCounted

var region_id: String
var display_name: String

func _init(p_region_id: String = "unassigned", p_display_name: String = "未规划区域") -> void:
    region_id = p_region_id
    display_name = p_display_name

static func query(_position: Vector3) -> WorldRegion:
    return WorldRegion.new()
