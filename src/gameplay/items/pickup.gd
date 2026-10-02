class_name Pickup
extends WorldEntity

@export_range(1, 100) var healing: int = 2

func apply_to(snake: Snake) -> void:
    snake.heal(healing)
