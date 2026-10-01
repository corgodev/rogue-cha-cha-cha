class_name Pickup
extends GridPlaceable

@export_range(1, 100) var healing: int = 2

func _init() -> void:
    occupancy = Occupancy.PICKUP

# TODO: We should have different types of pickups probably.
func apply_to(snake: Snake) -> void:
    snake.heal(healing)
