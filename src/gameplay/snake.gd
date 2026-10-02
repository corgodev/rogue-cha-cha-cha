class_name Snake
extends Node2D

signal health_changed
signal recruited(character: Character)

@export_range(1, 100) var max_health: int = 10
@export_range(1.0, 480.0) var speed: float = 48.0
@export_range(1.0, 720.0) var turn_speed_degrees: float = 360.0
@export_range(12.0, 32.0) var member_spacing: float = 16.0
@export var initial_direction: Vector2 = Vector2.RIGHT
@export var head: AtlasTexture
@export var tail: AtlasTexture

var health: int
var facing := Vector2.RIGHT
var members: Array[Character] = []
# Newest point first. Distances are measured along this polyline, not by time.
var trail: Array[Vector2] = []
var _connector: Line2D
var _step_distance: float = 0.0

func initialize(starting_members: Array[Character], room: Room) -> bool:
    if starting_members.is_empty() or initial_direction.is_zero_approx():
        return false
    members.clear()
    trail.clear()
    for member in starting_members:
        if not is_instance_valid(member) or members.has(member) or not room.characters.has(member) or member.attack == null:
            return false
        if not members.is_empty():
            var previous: Vector2 = members.back().global_position
            if not is_equal_approx(previous.distance_to(member.global_position), member_spacing):
                return false
            if not room.grid.can_traverse(previous, member.global_position, member.collision_radius):
                return false
        members.append(member)
        trail.append(member.global_position)
        member.attack_remaining = 0.0
    for index in members.size():
        for other_index in range(index + 2, members.size()):
            if members[index].touches(members[other_index]):
                return false
    facing = initial_direction.normalized()
    if members.size() > 1:
        facing = (trail[0] - trail[1]).normalized()
    health = max_health
    _step_distance = 0.0
    if _connector == null:
        _connector = Line2D.new()
        _connector.width = 8.0
        _connector.default_color = Color("779d52")
        _connector.joint_mode = Line2D.LINE_JOINT_ROUND
        _connector.begin_cap_mode = Line2D.LINE_CAP_ROUND
        _connector.end_cap_mode = Line2D.LINE_CAP_ROUND
        _connector.z_index = 1
        add_child(_connector)
    refresh_visuals()
    return true

func advance(delta: float, desired: Vector2, room: Room) -> void:
    # Small integration steps make steering and sweeps independent of render FPS.
    var remaining := delta
    while remaining > 0.000001:
        var dt := minf(remaining, minf(1.0 / 120.0, 0.5 / speed))
        remaining -= dt
        if not desired.is_zero_approx():
            var angle := rotate_toward(facing.angle(), desired.angle(), deg_to_rad(turn_speed_degrees) * dt)
            facing = Vector2.from_angle(angle)
        var destination := members[0].global_position + facing * speed * dt
        trail.push_front(destination)
        var positions: Array[Vector2] = []
        for index in members.size():
            positions.append(position_on_trail(index * member_spacing))
        if not _can_advance(positions, room):
            trail.pop_front()
            continue
        for index in members.size():
            members[index].global_position = positions[index]
        _step_distance += speed * dt
        _trim_trail()
    refresh_visuals()

func _can_advance(positions: Array[Vector2], room: Room) -> bool:
    for index in members.size():
        var member := members[index]
        if not room.can_traverse(member.global_position, positions[index], member.collision_radius, member, true):
            return false
        # Recruits are triggers, not obstacles. Party collisions use simultaneous
        # relative motion so a vacating tail doesn't incorrectly block the head.
        for other_index in range(index + 2, members.size()):
            var other := members[other_index]
            if WorldEntity.sweep_overlaps(member.global_position - other.global_position, positions[index] - positions[other_index], Vector2.ZERO, member.collision_radius + other.collision_radius):
                return false
    return true

func position_on_trail(distance: float) -> Vector2:
    for index in range(1, trail.size()):
        var length := trail[index - 1].distance_to(trail[index])
        if distance <= length:
            return trail[index - 1].lerp(trail[index], distance / maxf(length, 0.000001))
        distance -= length
    return trail.back()

func trail_length() -> float:
    var length := 0.0
    for index in range(1, trail.size()):
        length += trail[index - 1].distance_to(trail[index])
    return length

func _trim_trail() -> void:
    var length := 0.0
    for index in range(1, trail.size()):
        length += trail[index - 1].distance_to(trail[index])
        if length > members.size() * member_spacing + 1.0:
            trail.resize(index + 1)
            return

func try_recruit(character: Character, room: Room) -> bool:
    if not is_instance_valid(character) or not character.is_active() or members.has(character) or character.attack == null:
        return false
    if not members[0].touches(character) or not room.has_line_of_sight(members[0].global_position, character.global_position):
        return false
    var distance := members.size() * member_spacing
    if trail_length() < distance:
        return false
    var destination := position_on_trail(distance)
    if not room.can_traverse(destination, destination, character.collision_radius, character):
        return false
    character.global_position = destination
    character.attack_remaining = 0.0
    members.append(character)
    refresh_visuals()
    recruited.emit(character)
    return true

func refresh_visuals() -> void:
    var points := PackedVector2Array()
    var length := 0.0
    var visible_length := (members.size() - 1) * member_spacing
    points.append(to_local(trail[0]))
    for index in range(1, trail.size()):
        length += trail[index - 1].distance_to(trail[index])
        if length >= visible_length:
            break
        points.append(to_local(trail[index]))
    if members.size() > 1:
        points.append(to_local(members.back().global_position))
    _connector.points = points
    for index in members.size():
        var member := members[index]
        var direction := facing if index == 0 else (position_on_trail(maxf(0.0, index * member_spacing - 1.0)) - member.global_position).normalized()
        member.section_sprite.visible = index == 0 or index == members.size() - 1
        member.set_section_texture(head if index == 0 else tail, Vector2.UP.angle_to(direction))
        # Combat can override character aim without rotating the snake body.
        if member.attack_remaining <= 0.0:
            member.face_direction(direction)

func consume_step_sound() -> bool:
    if _step_distance < member_spacing:
        return false
    _step_distance = fmod(_step_distance, member_spacing)
    return true

func take_damage(amount: int) -> void:
    health = maxi(0, health - amount)
    health_changed.emit()

func heal(amount: int) -> void:
    health = mini(max_health, health + amount)
    health_changed.emit()
