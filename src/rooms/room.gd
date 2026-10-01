class_name Room
extends Node2D

@export var starting_snake: Array[Character] = []
@onready var grid: RoomGrid = %RoomGrid
@onready var _grid_entities: Node2D = %GridEntities
var enemies: Array[Enemy] = []
var initialization_ok: bool = true

func _ready() -> void:
    # This snaps entities that are placed on grid to their correct position.
    grid.entity_placed.connect(_snap_entity)
    grid.entity_moved.connect(_on_entity_moved)

    # Place all GridPlaceable entities on grid, validate all enemies have patrol and append them to enemies list
    for child in _grid_entities.get_children():
        if not child is GridPlaceable:
            continue
        var entity := child as GridPlaceable
        var cell := grid.world_to_cell(entity.global_position)
        if not grid.try_place_entity(entity, cell):
            push_error("Cannot register %s at %s: check terrain and occupancy." % [entity.name, cell])
            initialization_ok = false
        if entity is Enemy:
            enemies.append(entity)
            if entity.patrol == null or not entity.patrol.is_valid():
                push_error("Enemy %s needs a valid patrol." % entity.name)
                initialization_ok = false

func _snap_entity(entity: GridPlaceable, cell: Vector2i) -> void:
    entity.global_position = grid.cell_to_world(cell)

func _on_entity_moved(entity: GridPlaceable, _from: Vector2i, to: Vector2i) -> void:
    _snap_entity(entity, to)
