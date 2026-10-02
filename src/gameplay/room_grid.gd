class_name RoomGrid
extends Node

# Tiles describe terrain only. Actors can occupy any world position.
@export var walls: TileMapLayer
@export var ground: TileMapLayer

func world_to_cell(world_position: Vector2) -> Vector2i:
    return ground.local_to_map(ground.to_local(world_position))

func cell_to_world(cell: Vector2i) -> Vector2:
    return ground.to_global(ground.map_to_local(cell))

func is_walkable(cell: Vector2i) -> bool:
    var wall_cell := walls.local_to_map(walls.to_local(cell_to_world(cell)))
    return ground.get_cell_source_id(cell) != -1 and walls.get_cell_source_id(wall_cell) == -1

# Sweep a circle against tile rectangles (including missing ground). Checking
# edge distances gives rounded corners, instead of an inflated square collider.
func can_traverse(from: Vector2, to: Vector2, radius: float) -> bool:
    var local_from := ground.to_local(from)
    var local_to := ground.to_local(to)
    var local_radius := radius / ground.global_transform.x.length()
    var extent := Vector2.ONE * local_radius
    var low := ground.local_to_map(local_from.min(local_to) - extent) - Vector2i.ONE
    var high := ground.local_to_map(local_from.max(local_to) + extent) + Vector2i.ONE
    var half_tile := Vector2(ground.tile_set.tile_size) * 0.5
    for x in range(low.x, high.x + 1):
        for y in range(low.y, high.y + 1):
            var cell := Vector2i(x, y)
            if is_walkable(cell):
                continue
            var rectangle := Rect2(ground.map_to_local(cell) - half_tile, half_tile * 2.0)
            if _sweep_hits_rect(local_from, local_to, local_radius, rectangle):
                return false
    return true

static func _sweep_hits_rect(from: Vector2, to: Vector2, radius: float, rect: Rect2) -> bool:
    if rect.has_point(from) or rect.has_point(to):
        return true
    var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
    for index in 4:
        var edge_from: Vector2 = corners[index]
        var edge_to: Vector2 = corners[(index + 1) % 4]
        if Geometry2D.segment_intersects_segment(from, to, edge_from, edge_to) != null:
            return true
        var closest := Geometry2D.get_closest_points_between_segments(from, to, edge_from, edge_to)
        if closest[0].distance_squared_to(closest[1]) < radius * radius - 0.0001:
            return true
    return false
