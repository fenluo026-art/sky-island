class_name LayerDebugPanel
extends CanvasLayer

signal layer_selected(layer_id: int)

func _ready() -> void:
    var panel := PanelContainer.new()
    panel.position = Vector2(18, 18)
    panel.size = Vector2(310, 62)
    add_child(panel)

    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 5)
    panel.add_child(row)

    for layer_id in [0, -1, -2, -3, -4]:
        var button := Button.new()
        button.text = "地表" if layer_id == 0 else str(layer_id)
        button.custom_minimum_size = Vector2(52, 44)
        button.pressed.connect(_on_layer_pressed.bind(layer_id))
        row.add_child(button)

func _on_layer_pressed(layer_id: int) -> void:
    layer_selected.emit(layer_id)
