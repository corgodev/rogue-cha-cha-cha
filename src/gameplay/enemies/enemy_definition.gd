class_name EnemyDefinition
extends Resource

@export_range(1, 100) var max_health: int = 3
@export_range(1.0, 480.0) var speed: float = 48.0
@export_range(1, 100) var contact_damage: int = 1
@export_range(0.1, 10.0) var contact_cooldown: float = 1.0
@export var texture: Texture2D
@export var sprite_region: Rect2
@export var default_patrol: PatrolDefinition
