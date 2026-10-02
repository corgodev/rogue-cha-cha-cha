class_name GameplayController
extends Node

signal defeated
var room: Room
var snake: Snake
var input: PlayerController
var combat := CombatResolver.new()
var elapsed: float = 0.0
var running: bool = false
var last_action: String = "Moving — attacks are automatic"

func initialize(active_room: Room, player_snake: Snake, controller: PlayerController) -> void:
    room = active_room
    snake = player_snake
    input = controller
    elapsed = 0.0
    running = true

func _physics_process(delta: float) -> void:
    advance(delta, input.desired_direction() if input != null else Vector2.ZERO)

func advance(delta: float, direction: Vector2) -> void:
    if not running:
        return
    var remaining := delta
    while remaining > 0.000001 and running:
        var dt := minf(remaining, 1.0 / 120.0)
        remaining -= dt
        elapsed += dt
        snake.advance(dt, direction, room)
        for character in room.characters:
            if snake.try_recruit(character, room):
                last_action = "%s joins the party" % character.name
        combat.advance(dt, snake, room)
        for enemy in room.enemies:
            if not is_instance_valid(enemy) or not enemy.is_active():
                continue
            # Check both sides of patrol movement: an enemy touching the party
            # may turn away on this step, but contact must still count.
            enemy.contact_remaining = maxf(0.0, enemy.contact_remaining - dt)
            _resolve_contact(enemy)
            if not running:
                break
            enemy.advance(dt, room)
            _resolve_contact(enemy)
            if not running:
                break
        if running:
            _collect_pickups()

func _resolve_contact(enemy: Enemy) -> void:
    if enemy.contact_remaining > 0.00001:
        return
    for member in snake.members:
        # The half-pixel movement step stops immediately before penetration.
        if enemy.touches(member, 0.51) and room.has_line_of_sight(enemy.global_position, member.global_position):
            snake.take_damage(enemy.definition.contact_damage)
            enemy.contact_remaining = enemy.definition.contact_cooldown
            last_action = "%s hits the party" % enemy.name
            if snake.health == 0:
                running = false
                last_action = "Defeated! Press R to restart"
                defeated.emit()
            return

func _collect_pickups() -> void:
    for pickup in room.pickups:
        if not is_instance_valid(pickup) or not pickup.is_active():
            continue
        for member in snake.members:
            if member.touches(pickup) and room.has_line_of_sight(member.global_position, pickup.global_position):
                pickup.apply_to(snake)
                pickup.queue_free()
                last_action = "Picked up healing"
                break
