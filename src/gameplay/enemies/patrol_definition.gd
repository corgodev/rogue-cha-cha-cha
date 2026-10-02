class_name PatrolDefinition
extends Resource

@export var directions: Array[Vector2] = [Vector2.RIGHT, Vector2.LEFT]
@export_range(1.0, 1024.0) var distance_per_leg: float = 48.0

func is_valid() -> bool:
    if directions.is_empty() or distance_per_leg <= 0.0:
        return false
    for direction in directions:
        if not direction.is_finite() or direction.is_zero_approx():
            return false
    return true
