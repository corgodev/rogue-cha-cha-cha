# Base enemy statistics (health, steps per tick, etc.) + resolves patrol resource to inteded direction
class_name Enemy
extends GridPlaceable

@export_range(1, 100) var max_health: int = 3
@export_range(0, 10) var steps_per_tick: int = 1
@export_range(1, 100) var contact_damage: int = 1
@export var patrol: PatrolDefinition
@export var tint: Color = Color("e05b62")
var health: int
var leg_index: int = 0
var leg_progress: int = 0

func _ready() -> void:
    health = max_health

# TODO: It would be nicer from designer perspective if patrol could be setup visually in editor by e.g. selecting grid cells or something like that.
# Also - it would be good if we moved it from enemy class and made it separate component that attaches to the enemy.
func intended_direction() -> Vector2i:
    return patrol.directions[leg_index]

func advance_leg() -> void:
    leg_index = (leg_index + 1) % patrol.directions.size()
    leg_progress = 0

func record_step() -> void:
    leg_progress += 1
    if leg_progress >= patrol.cells_per_leg:
        advance_leg()