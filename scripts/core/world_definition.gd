class_name WorldDefinition
extends RefCounted

const WORLD_AREA_KM2: float = 80000.0
const WORLD_AREA_M2: float = WORLD_AREA_KM2 * 1000000.0
const APPROX_ISLAND_RADIUS_M: float = 159576.912
const WORLD_EXTENT_M: float = 320000.0
const CHUNK_SIZE_M: float = 512.0

const MIN_LAYER_ID: int = -4
const MAX_LAYER_ID: int = 0
const DEFAULT_LAYER_ID: int = 0

static func is_valid_layer(layer_id: int) -> bool:
    return layer_id >= MIN_LAYER_ID and layer_id <= MAX_LAYER_ID

static func layer_height(layer_id: int) -> float:
    return float(layer_id) * 180.0
