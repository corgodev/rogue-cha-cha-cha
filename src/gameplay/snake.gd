class_name Snake
extends Node

signal health_changed
@export_range(1, 100) var max_health: int = 10
@export_range(1, 100) var collision_damage: int = 1
@export var initial_direction: Vector2i = Vector2i.RIGHT

# Textures for sections
@export var head: AtlasTexture
@export var straight: AtlasTexture
@export var tail: AtlasTexture
@export var up_right: AtlasTexture
@export var down_right: AtlasTexture
@export var down_left: AtlasTexture
@export var up_left: AtlasTexture

var health: int
var facing: Vector2i
var members: Array[Character] = []

func initialize(starting_members: Array[Character], grid: RoomGrid) -> bool:
    members = starting_members.duplicate()
    if members.is_empty():
        return false
    var seen: Array[Character] = []
    for index in members.size():
        var member := members[index]
        if not is_character_valid(member, seen, grid, index):
            return false
        seen.append(member)
    
    # snake is facing direction of the "head" of the character chain and if there is only one character - initial_direction
    facing = members[0].grid_cell - members[1].grid_cell if members.size() > 1 else initial_direction
    health = max_health
    if not is_cardinal(facing):
        return false
    refresh_textures()
    return true

func is_character_valid(member: Character, seen: Array[Character], grid: RoomGrid, current_index: int) -> bool:
        if not is_instance_valid(member) or seen.has(member) or not grid.has_entity(member) or member.attack == null:
            # Check that each character is a valid instantiated scene, is not an already seen character (to avoid duplicates), is registered with grid and has attack
            return false
        if member.occupancy != GridPlaceable.Occupancy.ACTOR:
            # Check that each character is an actor
            return false
        if current_index > 0 and not is_cardinal(members[current_index - 1].grid_cell - member.grid_cell):
            # Check that each character is exactly behind the previous one.
            return false
        return true

# TODO: maybe move this to either grid class or some helper script with other methods related to grid math?
static func is_cardinal(direction: Vector2i) -> bool:
    return absi(direction.x) + absi(direction.y) == 1

func apply_direction(direction: Vector2i) -> void:
    if is_cardinal(direction) and direction != -facing:
        facing = direction
        refresh_textures()

# Neighbours come from chain order, not nearby occupied cells: the snake can
# touch itself without those touching sections becoming connected.
func refresh_textures() -> void:
    for index in members.size():
        var member := members[index]
        if index == 0:
            # The source head faces up; a single-member snake is also a head.
            member.set_section_texture(head, Vector2.UP.angle_to(Vector2(facing)))
            continue
        var toward_head := members[index - 1].grid_cell - member.grid_cell
        if index == members.size() - 1:
            # The source tail connects upward to the preceding section.
            member.set_section_texture(tail, Vector2.UP.angle_to(Vector2(toward_head)))
            continue
        var toward_tail := members[index + 1].grid_cell - member.grid_cell
        if toward_head == -toward_tail:
            # The source straight section is vertical.
            member.set_section_texture(straight, PI / 2.0 if toward_head.x != 0 else 0.0)
            continue
        # Corner names describe the two connections, regardless of travel direction.
        var connections := toward_head + toward_tail
        var corner: AtlasTexture
        match connections:
            Vector2i(1, -1): corner = up_right
            Vector2i(1, 1): corner = down_right
            Vector2i(-1, 1): corner = down_left
            Vector2i(-1, -1): corner = up_left
        member.set_section_texture(corner)


# This constructs PROPOSED movement (collisions, walls, etc. are checked elsewhere).
# The way it works is that leader moves in the facing direction and each next character takes place of the one ahead of it.
func proposed_move() -> Dictionary[GridPlaceable, Vector2i]:
    var destinations: Dictionary[GridPlaceable, Vector2i] = {}
    var leader: GridPlaceable = members[0]
    destinations[leader] = leader.grid_cell + facing
    for index in range(1, members.size()):
        var follower: GridPlaceable = members[index]
        destinations[follower] = members[index - 1].grid_cell
    return destinations

func take_damage(amount: int) -> void:
    health = maxi(0, health - amount)
    health_changed.emit()

func heal(amount: int) -> void:
    health = mini(max_health, health + amount)
    health_changed.emit()
