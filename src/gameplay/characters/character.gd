@tool
class_name Character
extends GridPlaceable

@export var definition: CharacterDefinition
@export var attack: AttackDefinition

@onready var sprite: Sprite2D = %Sprite
@onready var section_sprite: Sprite2D = %SectionSprite

func _ready() -> void:
    sprite.texture = definition.texture
    sprite.region_enabled = true
    sprite.region_rect = definition.sprite_region


func set_section_texture(texture: Texture2D, angle: float = 0.0) -> void:
    section_sprite.texture = texture
    # AtlasTexture already selects its region within the spritesheet.
    section_sprite.region_enabled = false
    section_sprite.rotation = angle


func face_direction(direction: Vector2i) -> void:
    # Character artwork is upright when facing up. Rotate only the overlay,
    # independently of the straight/corner texture underneath it.
    sprite.rotation = Vector2.UP.angle_to(Vector2(direction))
