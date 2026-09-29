# PlayerController caches last pending direction and consumes it when requested.

class_name PlayerController
extends Node

var pending_direction: Vector2i = Vector2i.ZERO

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("left"):
        pending_direction = Vector2i.LEFT
    elif event.is_action_pressed("right"):
        pending_direction = Vector2i.RIGHT
    elif event.is_action_pressed("up"):
        pending_direction = Vector2i.UP
    elif event.is_action_pressed("down"):
        pending_direction = Vector2i.DOWN

func consume_direction() -> Vector2i:
    var result := pending_direction
    pending_direction = Vector2i.ZERO
    return result
