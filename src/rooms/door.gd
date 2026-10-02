@tool
class_name Doors
extends WorldEntity

signal door_entered(room_to_enter: Room)

@export var open: bool = false:
    set(value):
        open = value
        if is_node_ready():
            _update_visuals()
@export var exit_door: bool = false
@export var current_room: Room = null
@export var next_room: Room = null

@onready var sprite: Sprite2D = %Sprite

const open_door_rect := Rect2(0.0, 0.0, 16.0, 16.0)
const closed_door_rect := Rect2(16.0, 0.0, 16.0, 16.0)

func _ready() -> void:
    _update_visuals()

func player_enter() -> void:
    if open and exit_door:
        door_entered.emit(next_room)

func _update_visuals() -> void:
    if open:
        sprite.region_rect = open_door_rect
    else:
        sprite.region_rect = closed_door_rect
