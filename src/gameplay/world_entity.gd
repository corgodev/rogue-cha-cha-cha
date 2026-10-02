@tool
class_name WorldEntity
extends Node2D

# A world-space circle used by the deterministic swept collision solver.
# Keeping movement in one solver lets the entire snake advance atomically.
@export_range(1.0, 8.0) var collision_radius: float = 5.0

func is_active() -> bool:
    return not is_queued_for_deletion()

func touches(other: WorldEntity, margin: float = 0.0) -> bool:
    return global_position.distance_to(other.global_position) <= collision_radius + other.collision_radius + margin

static func sweep_overlaps(from: Vector2, to: Vector2, center: Vector2, radius: float) -> bool:
    var closest := Geometry2D.get_closest_point_to_segment(center, from, to)
    return closest.distance_squared_to(center) < radius * radius - 0.0001
