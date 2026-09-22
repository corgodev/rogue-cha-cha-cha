class_name NPC
extends StaticBody2D
@onready var sprite: AnimatedSprite2D = %Sprite

@export var mass_added: float = 50.0

var is_hovering := false
var is_selected := false
var is_falling := false

signal npc_dropped(who: NPC)


func _process(_delta: float) -> void:
    if is_hovering:
        position = get_global_mouse_position()


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
    if event.is_action_pressed("left_click"):
        is_hovering = true
        is_selected = true
        sprite.play("hover")
    elif event.is_action_released("left_click"):
        is_hovering = false
        is_selected = false
        npc_dropped.emit(self)


func fall(eaten: bool = false) -> void:
    if eaten:
        sprite.animation_finished.connect(self.queue_free, CONNECT_ONE_SHOT)
        sprite.play("fall")
    else:
        sprite.play("idle")
