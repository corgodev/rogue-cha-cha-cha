class_name CombatResolver
extends RefCounted

signal attacked(origin: Vector2, direction: Vector2, area: Rect2, damage: int)

func advance(delta: float, snake: Snake, room: Room) -> void:
    for member in snake.members:
        member.attack_remaining = maxf(0.0, member.attack_remaining - delta)
        if member.attack_remaining > 0.00001:
            continue
        var target := nearest_target(member, room)
        if target == null:
            continue
        var direction := member.global_position.direction_to(target.global_position)
        if direction.is_zero_approx():
            direction = snake.facing
        member.face_direction(direction)
        attack(member, direction, room)
        member.attack_remaining = member.attack.cooldown

func nearest_target(member: Character, room: Room) -> Enemy:
    var nearest: Enemy
    var nearest_distance := INF
    for enemy in room.enemies:
        if not is_instance_valid(enemy) or not enemy.is_active():
            continue
        var distance := member.global_position.distance_to(enemy.global_position)
        if distance > member.attack.reach + enemy.collision_radius or distance >= nearest_distance:
            continue
        if room.has_line_of_sight(member.global_position, enemy.global_position):
            nearest = enemy
            nearest_distance = distance
    return nearest

func attack(member: Character, direction: Vector2, room: Room) -> void:
    var area := member.attack.local_area()
    for enemy in room.enemies:
        if not is_instance_valid(enemy) or not enemy.is_active():
            continue
        var offset := (enemy.global_position - member.global_position).rotated(-direction.angle())
        var closest := offset.clamp(area.position, area.end)
        if offset.distance_squared_to(closest) > enemy.collision_radius * enemy.collision_radius:
            continue
        if room.has_line_of_sight(member.global_position, enemy.global_position):
            enemy.take_damage(member.attack.damage)
    attacked.emit(member.global_position, direction, area, member.attack.damage)
