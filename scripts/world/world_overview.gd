class_name WorldOverview
extends MeshInstance3D

const WorldDef = preload("res://scripts/core/world_definition.gd")
const TerrainGeneratorType = preload("res://scripts/world/terrain_generator.gd")

const GRID := 65
const WORLD_X := 318000.0
const WORLD_Z := 252000.0

func build(generator: TerrainGenerator) -> void:
    var vertices := PackedVector3Array()
    var normals := PackedVector3Array()
    var colors := PackedColorArray()
    var indices := PackedInt32Array()

    for z in range(GRID):
        var vz := float(z) / float(GRID - 1)
        var wz := (vz - 0.5) * WORLD_Z
        for x in range(GRID):
            var vx := float(x) / float(GRID - 1)
            var wx := (vx - 0.5) * WORLD_X
            var h: float = generator.height_at(wx, wz)
            vertices.append(Vector3(wx, h, wz))
            normals.append(Vector3.UP)
            colors.append(generator.terrain_color(h))

    for z in range(GRID - 1):
        for x in range(GRID - 1):
            var a := z * GRID + x
            var b := a + 1
            var c := a + GRID
            var d := c + 1
            indices.append_array(PackedInt32Array([a, c, b, b, c, d]))

    for i in range(0, indices.size(), 3):
        var a := vertices[indices[i]]
        var b := vertices[indices[i + 1]]
        var c := vertices[indices[i + 2]]
        var n := (b - a).cross(c - a).normalized()
        normals[indices[i]] = n
        normals[indices[i + 1]] = n
        normals[indices[i + 2]] = n

    var arrays: Array = []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_NORMAL] = normals
    arrays[Mesh.ARRAY_COLOR] = colors
    arrays[Mesh.ARRAY_INDEX] = indices

    var mesh := ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    self.mesh = mesh

    var material := StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.roughness = 1.0
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    material.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_DISABLED
    material.albedo_color = Color.WHITE
    material.metallic = 0.0
    material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
    material_override = material
    cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    name = "WorldOverviewLOD"
