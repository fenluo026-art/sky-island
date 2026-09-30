extends Node3D

const WorldDef = preload("res://scripts/core/world_definition.gd")
const WorldLayer = preload("res://scripts/world/world_layer.gd")
const WorldCoordinates = preload("res://scripts/core/world_coordinates.gd")
const ChunkManagerType = preload("res://scripts/world/chunk_manager.gd")
const SandboxCameraType = preload("res://scripts/camera/sandbox_camera.gd")
const LayerPanelType = preload("res://scripts/ui/layer_debug_panel.gd")

var camera: SandboxCamera
var chunk_manager: ChunkManager
var status_label: Label

func _ready() -> void:
    _build_environment()
    _build_world_root()
    _build_camera()
    _build_ui()

    chunk_manager.update_streaming(camera.global_position)

func _process(_delta: float) -> void:
    if camera != null and chunk_manager != null:
        chunk_manager.update_streaming(camera.global_position)
        _update_status()

func _build_world_root() -> void:
    chunk_manager = ChunkManagerType.new()
    add_child(chunk_manager)

    var origin := MeshInstance3D.new()
    origin.name = "WorldOrigin"
    var mesh := SphereMesh.new()
    mesh.radius = 12.0
    mesh.height = 24.0
    origin.mesh = mesh
    origin.position = Vector3.ZERO
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.95, 0.72, 0.20)
    origin.material_override = material
    add_child(origin)

func _build_camera() -> void:
    camera = SandboxCameraType.new()
    camera.focus = Vector3.ZERO
    add_child(camera)

func _build_environment() -> void:
    var world_environment := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.035, 0.055, 0.09)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.72, 0.78, 0.90)
    environment.ambient_light_energy = 0.8
    world_environment.environment = environment
    add_child(world_environment)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52.0, -25.0, 0.0)
    sun.light_energy = 1.15
    sun.shadow_enabled = false
    add_child(sun)

func _build_ui() -> void:
    var panel := LayerPanelType.new()
    panel.layer_selected.connect(_on_layer_selected)
    add_child(panel)

    status_label = Label.new()
    status_label.position = Vector2(18, 92)
    status_label.add_theme_font_size_override("font_size", 18)
    add_child(status_label)

func _on_layer_selected(layer_id: int) -> void:
    chunk_manager.set_active_layer(layer_id)
    chunk_manager.update_streaming(camera.global_position)

func _update_status() -> void:
    var layer_name := WorldLayer.display_name(chunk_manager.active_layer_id)
    var chunk := WorldCoordinates.world_to_chunk(camera.global_position)
    status_label.text = "阶段 0 · %s · Chunk (%d, %d) · 已加载 %d" % [
        layer_name,
        chunk.x,
        chunk.y,
        chunk_manager.loaded_chunks.size()
    ]
