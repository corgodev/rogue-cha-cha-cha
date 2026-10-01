@tool
# Base enemy statistics (health, steps per tick, etc.) + resolves patrol resource to inteded direction
class_name Enemy
extends GridPlaceable

@export var definition: EnemyDefinition

@onready var sprite: Sprite2D = %Sprite2D

var health: int
var leg_index: int = 0
var leg_progress: int = 0
var steps_per_tick: int = 1
var contact_damage: int = 1
var patrol: PatrolDefinition
var tint: Color = Color("e05b62")


func _ready() -> void:
    health = definition.max_health
    patrol = definition.default_patrol
    steps_per_tick = definition.steps_per_tick
    contact_damage = definition.contact_damage

    sprite.texture = definition.texture
    sprite.region_enabled = true
    sprite.region_rect = definition.sprite_region


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
