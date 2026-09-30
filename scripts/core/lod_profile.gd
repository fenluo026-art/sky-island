class_name LodProfile
extends RefCounted

const LEVEL_0_DISTANCE_M := 700.0
const LEVEL_1_DISTANCE_M := 1600.0
const LEVEL_2_DISTANCE_M := 3200.0

static func level_for_distance(distance_m: float) -> int:
    if distance_m < LEVEL_0_DISTANCE_M:
        return 0
    if distance_m < LEVEL_1_DISTANCE_M:
        return 1
    if distance_m < LEVEL_2_DISTANCE_M:
        return 2
    return 3

static func subdivisions_for_level(level: int) -> int:
    match level:
        0:
            return 8
        1:
            return 4
        2:
            return 2
        _:
            return 1
