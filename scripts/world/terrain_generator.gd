class_name TerrainGenerator
extends RefCounted

const WorldDef = preload("res://scripts/core/world_definition.gd")
const DEFAULT_GRID_SIZE := 17

var _macro := FastNoiseLite.new()
var _detail := FastNoiseLite.new()

func _init() -> void:
    _macro.seed = 1703926
    _macro.frequency = 0.000012
    _macro.fractal_octaves = 4
    _macro.fractal_lacunarity = 2.0
    _macro.fractal_gain = 0.52
    _detail.seed = 904211
    _detail.frequency = 0.000055
    _detail.fractal_octaves = 3
    _detail.fractal_gain = 0.5

func build_chunk_mesh(chunk_x: int, chunk_z: int, grid_size: int = DEFAULT_GRID_SIZE) -> ArrayMesh:
    var vertices := PackedVector3Array()
    var normals := PackedVector3Array()
    var uvs := PackedVector2Array()
    var colors := PackedColorArray()
    var indices := PackedInt32Array()
    var sample_step: float = WorldDef.CHUNK_SIZE_M / float(grid_size - 1)

    for z in range(grid_size):
        for x in range(grid_size):
            var wx: float = float(chunk_x) * WorldDef.CHUNK_SIZE_M + float(x) * sample_step
            var wz: float = float(chunk_z) * WorldDef.CHUNK_SIZE_M + float(z) * sample_step
            var h: float = height_at(wx, wz)
            vertices.append(Vector3(float(x) * sample_step, h, float(z) * sample_step))
            normals.append(Vector3.UP)
            uvs.append(Vector2(float(x) / float(grid_size - 1), float(z) / float(grid_size - 1)))
            colors.append(terrain_color(h))

    for z in range(grid_size - 1):
        for x in range(grid_size - 1):
            var a := z * grid_size + x
            var b := a + 1
            var c := a + grid_size
            var d := c + 1
            indices.append_array(PackedInt32Array([a, c, b, b, c, d]))

    _calculate_normals(vertices, indices, normals)
    var arrays: Array = []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_NORMAL] = normals
    arrays[Mesh.ARRAY_TEX_UV] = uvs
    arrays[Mesh.ARRAY_COLOR] = colors
    arrays[Mesh.ARRAY_INDEX] = indices

    var mesh := ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    return mesh

func height_at(wx: float, wz: float) -> float:
    var rotated := Vector2(wx * 0.94 - wz * 0.34, wx * 0.34 + wz * 0.94)
    var nx: float = rotated.x / 159000.0
    var nz: float = rotated.y / 126000.0
    var radial := Vector2(nx, nz).length()
    var angle := atan2(nz, nx)
    var angular := 0.055 * sin(angle * 5.0 + 0.8) + 0.035 * sin(angle * 9.0 - 1.2)
    var boundary: float = radial / (1.0 + angular)
    var edge: float = 1.0 - smoothstep(0.70, 1.0, boundary)
    if edge <= 0.0:
        return -24.0

    var macro: float = (_macro.get_noise_2d(wx, wz) + 1.0) * 0.5
    var detail: float = (_detail.get_noise_2d(wx, wz) + 1.0) * 0.5
    var mountain_band: float = max(0.0, _macro.get_noise_2d(wx * 0.72, wz * 0.72))
    var base: float = 55.0 + macro * 160.0
    var hills: float = pow(max(0.0, macro), 2.0) * 380.0
    var mountains: float = pow(mountain_band, 3.0) * 1050.0
    var height: float = (base + hills + mountains + detail * 45.0) * edge
    height = _apply_lakes_and_rivers(height, wx, wz)
    return max(-24.0, height)

func _apply_lakes_and_rivers(height: float, wx: float, wz: float) -> float:
    var lakes := [
        Vector2(-52000.0, 34000.0),
        Vector2(47000.0, -28000.0),
        Vector2(18000.0, 56000.0),
        Vector2(-76000.0, -18000.0)
    ]
    for center: Vector2 in lakes:
        var d: float = Vector2(wx, wz).distance_to(center)
        if d < 4200.0:
            var t: float = 1.0 - d / 4200.0
            height -= smoothstep(0.0, 1.0, t) * 180.0

    var river_axis: float = abs(wz - sin(wx * 0.000018) * 18000.0 - 7000.0)
    if river_axis < 850.0:
        var river_factor: float = 1.0 - river_axis / 850.0
        height -= river_factor * 105.0
    return height

func terrain_color(height: float) -> Color:
    if height < 8.0:
        return Color(0.10, 0.32, 0.46)
    if height < 80.0:
        return Color(0.20, 0.45, 0.24)
    if height < 260.0:
        return Color(0.27, 0.52, 0.25)
    if height < 600.0:
        return Color(0.34, 0.43, 0.25)
    if height < 900.0:
        return Color(0.39, 0.37, 0.29)
    return Color(0.62, 0.60, 0.54)

func _calculate_normals(vertices: PackedVector3Array, indices: PackedInt32Array, normals: PackedVector3Array) -> void:
    for i in range(normals.size()):
        normals[i] = Vector3.ZERO
    for i in range(0, indices.size(), 3):
        var a := vertices[indices[i]]
        var b := vertices[indices[i + 1]]
        var c := vertices[indices[i + 2]]
        var n := (b - a).cross(c - a).normalized()
        normals[indices[i]] += n
        normals[indices[i + 1]] += n
        normals[indices[i + 2]] += n
    for i in range(normals.size()):
        normals[i] = normals[i].normalized()
