@abstract
class_name GridPlaceable
extends Node2D

var grid_cell: Vector2i = Constants.INVALID_CELL

# We need two types of occupancy to differentiate between actors and pickups when dealing with movement.
# For example - actor and pickup can both occupy the same cell
# Enemies can move onto pickups without interacting with them in any way, etc.
enum Occupancy {ACTOR, PICKUP}
@export var occupancy: Occupancy = Occupancy.ACTOR
var registered_grid: RoomGrid
