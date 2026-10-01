@tool
class_name Character
extends GridPlaceable

@export var definition: CharacterDefinition
@export var attack: AttackDefinition

@onready var sprite: Sprite2D = %Sprite

func _ready() -> void:
    sprite.texture = definition.texture
    sprite.region_enabled = true
    sprite.region_rect = definition.sprite_region


func set_section_texture(texture: Texture2D, angle: float = 0.0) -> void:
    if texture == null:
        return
    sprite.texture = texture
    # AtlasTexture already selects its region within the spritesheet.
    sprite.region_enabled = false
    sprite.rotation = angle
