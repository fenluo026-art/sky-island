class_name WorldLayer
extends RefCounted

const SURFACE := 0
const LIFE_AND_TRANSIT := -1
const MILITARY := -2
const INDUSTRIAL_STORAGE := -3
const ENERGY_CONTROL_CORE := -4

static func display_name(layer_id: int) -> String:
    match layer_id:
        SURFACE:
            return "地表"
        LIFE_AND_TRANSIT:
            return "-1 生活/交通"
        MILITARY:
            return "-2 军事"
        INDUSTRIAL_STORAGE:
            return "-3 工业/仓储"
        ENERGY_CONTROL_CORE:
            return "-4 能源/控制/核心设施"
        _:
            return "未知层"
