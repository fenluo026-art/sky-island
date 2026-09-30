extends Node3D

const WorldDef = preload("res://scripts/core/world_definition.gd")
const WorldLayer = preload("res://scripts/world/world_layer.gd")
const WorldCoordinates = preload("res://scripts/core/world_coordinates.gd")
const ChunkManagerType = preload("res://scripts/world/chunk_manager.gd")
const TerrainGeneratorType = preload("res://scripts/world/terrain_generator.gd")
const WorldOverviewType = preload("res://scripts/world/world_overview.gd")
const SandboxCameraType = preload("res://scripts/camera/sandbox_camera.gd")
const LayerPanelType = preload("res://scripts/ui/layer_debug_panel.gd")

var camera: SandboxCamera
var chunk_manager: ChunkManager
var status_label: Label
var orientation_button: Button
var world_overview: WorldOverview
var portrait_mode := false

func _ready() -> void:
    DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
    _build_environment()
    _build_world_root()
    _build_camera()
    _build_overview()
    _build_ui()
    chunk_manager.update_streaming(camera.global_position)

func _process(_delta: float) -> void:
    if camera != null and chunk_manager != null:
        chunk_manager.update_streaming(camera.global_position)
        if world_overview != null:
            world_overview.visible = camera.distance > 9000.0 and chunk_manager.active_layer_id == WorldDef.DEFAULT_LAYER_ID
        _update_status()

func _build_world_root() -> void:
    chunk_manager = ChunkManagerType.new()
    add_child(chunk_manager)

func _build_camera() -> void:
    camera = SandboxCameraType.new()
    camera.focus = Vector3.ZERO
    camera.distance = 8200.0
    camera.min_distance = 80.0
    camera.max_distance = 260000.0
    add_child(camera)

func _build_overview() -> void:
    world_overview = WorldOverviewType.new()
    var generator := TerrainGeneratorType.new()
    world_overview.build(generator)
    add_child(world_overview)

func _build_environment() -> void:
    var world_environment := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.025, 0.075, 0.14)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.72, 0.80, 0.95)
    environment.ambient_light_energy = 0.9
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world_environment.environment = environment
    add_child(world_environment)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52.0, -25.0, 0.0)
    sun.light_energy = 1.35
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 5000.0
    add_child(sun)

func _build_ui() -> void:
    var panel := LayerPanelType.new()
    panel.layer_selected.connect(_on_layer_selected)
    add_child(panel)

    status_label = Label.new()
    status_label.position = Vector2(18, 92)
    status_label.add_theme_font_size_override("font_size", 18)
    add_child(status_label)

    orientation_button = Button.new()
    orientation_button.text = "竖屏" if not portrait_mode else "横屏"
    orientation_button.position = Vector2(1760, 24)
    orientation_button.size = Vector2(130, 54)
    orientation_button.add_theme_font_size_override("font_size", 20)
    orientation_button.pressed.connect(_toggle_orientation)
    add_child(orientation_button)

func _toggle_orientation() -> void:
    portrait_mode = not portrait_mode
    var target := DisplayServer.SCREEN_PORTRAIT if portrait_mode else DisplayServer.SCREEN_LANDSCAPE
    DisplayServer.screen_set_orientation(target)
    orientation_button.text = "横屏" if portrait_mode else "竖屏"

func _on_layer_selected(layer_id: int) -> void:
    chunk_manager.set_active_layer(layer_id)
    chunk_manager.update_streaming(camera.global_position)

func _update_status() -> void:
    var layer_name := WorldLayer.display_name(chunk_manager.active_layer_id)
    var chunk := WorldCoordinates.world_to_chunk(camera.global_position)
    status_label.text = "Sky Island · %s · Chunk (%d, %d) · 已加载 %d" % [
        layer_name,
        chunk.x,
        chunk.y,
        chunk_manager.loaded_chunks.size()
    ]
