class_name TurnController
extends Node

signal tick_finished
signal defeated
var grid: RoomGrid
var snake: Snake
var input: PlayerController
var enemies: Array[Enemy] = []
var combat := CombatResolver.new()
var tick_count: int = 0
var running: bool = false
var last_action: String = "Ready"

func initialize(room_grid: RoomGrid, player_snake: Snake, controller: PlayerController, room_enemies: Array[Enemy]) -> void:
    grid = room_grid
    snake = player_snake
    input = controller
    enemies = room_enemies.duplicate()
    tick_count = 0
    running = true

func advance_tick() -> void:
    # Tick consists of:
    # 1. Applying movement direction (player presses key)
    # 2. Resolving snake (trying to move and attacking enemies if encountered or taking no-move damage)
    # 3. Checking if player was defeated.
    # 4. Resolving enemies movement (checking if they can move in the direction they want to, dealing damange to snake if member is encountered and moving)
    # 5. Checking again if player was defeated (since enemy could have killed them)
    if not running:
        return
    tick_count += 1
    snake.apply_direction(input.consume_direction())
    _resolve_snake()
    if _check_defeat():
        return
    for enemy in enemies:
        if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or not grid.has_entity(enemy):
            continue
        _resolve_enemy(enemy)
        if _check_defeat():
            return
    tick_finished.emit()

func _resolve_snake() -> void:
    var leader := snake.members[0]
    var destination := leader.grid_cell + snake.facing
    var occupant := grid.get_actor_at(destination)
    # If there is enemy in destination - attack them
    if grid.is_walkable(destination) and occupant is Enemy:
        combat.attack(leader, snake.facing, grid)
        last_action = "%s attacks" % leader.name
        return
    if occupant is Character and snake.try_recruit(occupant, grid):
        last_action = "%s joins the snake" % occupant.name
    # Existing members cannot be recruited again; normal collision rules apply.
    elif not grid.try_move_batch(snake.proposed_move()):
        snake.take_damage(snake.collision_damage)
        last_action = "Collision! -%d HP" % snake.collision_damage
        return
    else:
        snake.refresh_textures()
        last_action = "Moving"
    FmodServer.play_one_shot("event:/step")
    # After movement - get any pickup at cells where snake members are
    for member in snake.members:
        var pickup := grid.get_pickup_at(member.grid_cell) as Pickup
        if pickup != null:
            pickup.apply_to(snake)
            grid.remove(pickup)
            pickup.queue_free()
            last_action = "Picked up healing"

# Patrols choose directions; this method resolves ground traversal and contact.
func _resolve_enemy(enemy: Enemy) -> void:
    for step in enemy.steps_per_tick:
        # Intended direction resolves it based on next lef of the patrol attached to the enemy
        var destination := enemy.grid_cell + enemy.intended_direction()
        if not grid.is_walkable(destination):
            enemy.advance_leg()
            return

        # If there is a snake member in destination - hit them and advance patrol leg (so basically enemy doesn't move but only deals damage)
        var occupant := grid.get_actor_at(destination)
        if occupant != null:
            if occupant is Character and snake.members.has(occupant):
                snake.take_damage(enemy.contact_damage)
                last_action = "%s hits snake" % enemy.name
            else:
                enemy.advance_leg()
            return
        var move: Dictionary[GridPlaceable, Vector2i] = {enemy: destination}
        if grid.try_move_batch(move):
            enemy.record_step()

func _check_defeat() -> bool:
    if snake.health > 0:
        return false
    running = false
    last_action = "Defeated! Press R to restart"
    defeated.emit()
    tick_finished.emit()
    return true
