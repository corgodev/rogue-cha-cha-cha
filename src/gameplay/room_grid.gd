class_name RoomGrid
extends Node

signal entity_placed(entity: GridPlaceable, cell: Vector2i)
signal entity_removed(entity: GridPlaceable, cell: Vector2i)
signal entity_moved(entity: GridPlaceable, from_cell: Vector2i, to_cell: Vector2i)

@export var walls: TileMapLayer
@export var ground: TileMapLayer
var actors_by_cell: Dictionary[Vector2i, GridPlaceable] = {}
var pickups_by_cell: Dictionary[Vector2i, GridPlaceable] = {}

# World to cell and reverse coordinates.
func world_to_cell(world_position: Vector2) -> Vector2i:
    return ground.local_to_map(ground.to_local(world_position))

func cell_to_world(cell: Vector2i) -> Vector2:
    return ground.to_global(ground.map_to_local(cell))

# Static information - check if it's a wall, ground, walkable,  etc.
func is_ground(cell: Vector2i) -> bool:
    return ground.get_cell_source_id(cell) != -1

func is_wall(cell: Vector2i) -> bool:
    return walls.get_cell_source_id(cell) != -1

func is_walkable(cell: Vector2i) -> bool:
    return is_ground(cell) and not is_wall(cell)

# Dynamic occupancy - get actor/pickup, check if it's on the grid, try to place it and remove it.

func get_actor_at(cell: Vector2i) -> GridPlaceable:
    return actors_by_cell.get(cell)

func get_pickup_at(cell: Vector2i) -> GridPlaceable:
    return pickups_by_cell.get(cell)

func _occupancy_map_for(entity: GridPlaceable) -> Dictionary[Vector2i, GridPlaceable]:
    return pickups_by_cell if entity.occupancy == GridPlaceable.Occupancy.PICKUP else actors_by_cell

func has_entity(entity: GridPlaceable) -> bool:
    return entity.registered_grid == self and _occupancy_map_for(entity).get(entity.grid_cell) == entity

func try_place_entity(entity: GridPlaceable, cell: Vector2i) -> bool:
    if entity.registered_grid != null or not is_walkable(cell) or _occupancy_map_for(entity).has(cell):
        return false
    _occupancy_map_for(entity)[cell] = entity
    entity.grid_cell = cell
    entity.registered_grid = self
    var cleanup := remove.bind(entity)
    if not entity.tree_exiting.is_connected(cleanup):
        entity.tree_exiting.connect(cleanup, CONNECT_ONE_SHOT)
    entity_placed.emit(entity, cell)
    return true

func remove(entity: GridPlaceable) -> void:
    if not has_entity(entity):
        return
    var cell := entity.grid_cell
    _occupancy_map_for(entity).erase(cell)
    entity.registered_grid = null
    entity.grid_cell = Constants.INVALID_CELL
    entity_removed.emit(entity, cell)

# Validate the whole move before writing. Observers see a completed transaction.
func try_move_batch(destinations: Dictionary[GridPlaceable, Vector2i]) -> bool:
    var seen: Dictionary[Vector2i, bool] = {}
    var previous: Dictionary[GridPlaceable, Vector2i] = {}
    for entity: GridPlaceable in destinations:
        var cell: Vector2i = destinations[entity]
        # Check that this entity is registered with grid and that this entity is an Actor
        if not has_entity(entity) or entity.occupancy != GridPlaceable.Occupancy.ACTOR:
            return false
        # Check that the destination cell is walkable and that we haven't seen that destination cell in the batch yet   
        if not is_walkable(cell) or seen.has(cell):
            return false

        # Check that the destination is not occupied or if it is - that the current occupant is also moving in the current batch.
        # Strictly speaking - it doesn't guarantee that occupant will move but if it won't - then above seen.has(cell) check should
        # fire and return false
        var occupant := get_actor_at(cell)
        if occupant != null and not destinations.has(occupant):
            return false
        seen[cell] = true
        previous[entity] = entity.grid_cell
    for entity: GridPlaceable in destinations:
        actors_by_cell.erase(entity.grid_cell)
    for entity: GridPlaceable in destinations:
        entity.grid_cell = destinations[entity]
        actors_by_cell[entity.grid_cell] = entity
    for entity: GridPlaceable in destinations:
        entity_moved.emit(entity, previous[entity], entity.grid_cell)
    return true
