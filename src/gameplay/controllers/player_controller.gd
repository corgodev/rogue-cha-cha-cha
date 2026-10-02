class_name PlayerController
extends Node

func desired_direction() -> Vector2:
    return Input.get_vector("left", "right", "up", "down")
