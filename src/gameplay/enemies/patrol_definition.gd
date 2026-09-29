class_name PatrolDefinition
extends Resource

@export var directions: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT]
@export_range(1, 30) var cells_per_leg: int = 3


# PlayerParty.is_cardinal(direction) checks that each patrol direction is one of the four grid directions: up, down, left, or right.
# TODO: We should add different type of movements (flying, jumping) and also allow cardinal movement.
func is_valid() -> bool:
    if directions.is_empty() or cells_per_leg < 1:
        return false
    for direction in directions:
        if not PlayerParty.is_cardinal(direction):
            return false
    return true
