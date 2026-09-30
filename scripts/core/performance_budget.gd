class_name PerformanceBudget
extends RefCounted

const MAX_LOADED_CHUNKS := 49
const STREAM_LOAD_RADIUS := 2
const STREAM_UNLOAD_RADIUS := 3

static func clamp_loaded_count(count: int) -> int:
    return min(count, MAX_LOADED_CHUNKS)
