class_name SandboxCamera
extends Camera3D

@export var min_distance := 80.0
@export var max_distance := 260000.0
@export var rotation_speed := 0.009
@export var zoom_step := 0.90

var focus := Vector3.ZERO
var yaw := 0.35
var pitch := -0.82
var distance := 8200.0
var touch_points: Dictionary = {}

func _ready() -> void:
    current = true
    projection = Camera3D.PROJECTION_PERSPECTIVE
    fov = 55.0
    _apply_transform()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        _rotate_camera(event.relative)
    elif event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            _zoom(zoom_step)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            _zoom(1.0 / zoom_step)
    elif event is InputEventScreenTouch:
        if event.pressed:
            touch_points[event.index] = event.position
        else:
            touch_points.erase(event.index)
    elif event is InputEventScreenDrag:
        if touch_points.size() == 1:
            _rotate_camera(event.screen_relative)
            touch_points[event.index] = event.position
        elif touch_points.size() >= 2:
            var previous: Vector2 = touch_points.get(event.index, event.position)
            var delta: Vector2 = event.position - previous
            focus += _pan_delta(delta)
            touch_points[event.index] = event.position
            _apply_transform()

func _rotate_camera(screen_delta: Vector2) -> void:
    yaw -= screen_delta.x * rotation_speed
    pitch = clamp(pitch - screen_delta.y * rotation_speed, -1.42, -0.18)
    _apply_transform()

func _zoom(multiplier: float) -> void:
    distance = clamp(distance * multiplier, min_distance, max_distance)
    _apply_transform()

func _pan_delta(screen_delta: Vector2) -> Vector3:
    var right := global_transform.basis.x
    right.y = 0.0
    right = right.normalized()
    var forward := -global_transform.basis.z
    forward.y = 0.0
    forward = forward.normalized()
    var pan_scale := max(distance * 0.00055, 0.35)
    return (-right * screen_delta.x + forward * screen_delta.y) * pan_scale

func _apply_transform() -> void:
    var horizontal := cos(pitch) * distance
    var offset := Vector3(
        sin(yaw) * horizontal,
        -sin(pitch) * distance,
        cos(yaw) * horizontal
    )
    global_position = focus + offset
    look_at(focus, Vector3.UP)
