@tool
class_name Enemy
extends WorldEntity

@export var definition: EnemyDefinition
@onready var sprite: Sprite2D = %Sprite2D
var health: int
var patrol: PatrolDefinition
var leg_index: int = 0
var leg_progress: float = 0.0
var contact_remaining: float = 0.0

func _ready() -> void:
    if definition == null:
        return
    health = definition.max_health
    patrol = definition.default_patrol
    sprite.texture = definition.texture
    sprite.region_enabled = true
    sprite.region_rect = definition.sprite_region

func is_active() -> bool:
    return health > 0 and super.is_active()

func advance_leg() -> void:
    leg_index = (leg_index + 1) % patrol.directions.size()
    leg_progress = 0.0

func advance(delta: float, room: Room) -> void:
    var remaining := definition.speed * delta
    while remaining > 0.0001:
        var distance := minf(remaining, minf(0.5, patrol.distance_per_leg - leg_progress))
        var destination := global_position + patrol.directions[leg_index].normalized() * distance
        if not room.can_traverse(global_position, destination, collision_radius, self):
            advance_leg()
            return
        global_position = destination
        leg_progress += distance
        remaining -= distance
        if leg_progress >= patrol.distance_per_leg - 0.0001:
            advance_leg()

func take_damage(amount: int) -> void:
    health = maxi(0, health - amount)
    if health == 0:
        queue_free()
