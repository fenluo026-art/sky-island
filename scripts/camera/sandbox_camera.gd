class_name SandboxCamera
extends Camera3D

@export var min_distance := 120.0
@export var max_distance := 6000.0
@export var rotation_speed := 0.012

var focus := Vector3.ZERO
var yaw := 0.65
var pitch := -0.72
var distance := 1800.0
var touch_points: Dictionary = {}

func _ready() -> void:
    current = true
    _apply_transform()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        yaw -= event.relative.x * rotation_speed
        pitch = clamp(pitch - event.relative.y * rotation_speed, -1.45, -0.12)
        _apply_transform()
    elif event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            distance = max(min_distance, distance * 0.88)
            _apply_transform()
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            distance = min(max_distance, distance * 1.14)
            _apply_transform()
    elif event is InputEventScreenTouch:
        if event.pressed:
            touch_points[event.index] = event.position
        else:
            touch_points.erase(event.index)
    elif event is InputEventScreenDrag:
        if touch_points.size() == 1:
            yaw -= event.screen_relative.x * rotation_speed
            pitch = clamp(pitch - event.screen_relative.y * rotation_speed, -1.45, -0.12)
            touch_points[event.index] = event.position
            _apply_transform()
        elif touch_points.size() >= 2:
            var previous: Vector2 = touch_points[event.index]
            var delta: Vector2 = event.position - previous
            focus += _pan_delta(delta)
            touch_points[event.index] = event.position
            _apply_transform()

func _pan_delta(screen_delta: Vector2) -> Vector3:
    var right := global_transform.basis.x
    var forward := -global_transform.basis.z
    forward.y = 0.0
    forward = forward.normalized()
    return (-right * screen_delta.x + forward * screen_delta.y) * (distance * 0.0008)

func _apply_transform() -> void:
    var horizontal := cos(pitch) * distance
    var offset := Vector3(
        sin(yaw) * horizontal,
        -sin(pitch) * distance,
        cos(yaw) * horizontal
    )
    global_position = focus + offset
    look_at(focus, Vector3.UP)
