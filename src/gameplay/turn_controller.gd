class_name TurnController
extends Node

signal tick_finished
signal defeated
var grid: RoomGrid
var party: PlayerParty
var input: PlayerController
var enemies: Array[Enemy] = []
var combat := CombatResolver.new()
var tick_count: int = 0
var running: bool = false
var last_action: String = "Ready"

func initialize(room_grid: RoomGrid, player_party: PlayerParty, controller: PlayerController, room_enemies: Array[Enemy]) -> void:
    grid = room_grid
    party = player_party
    input = controller
    enemies = room_enemies.duplicate()
    tick_count = 0
    running = true

func advance_tick() -> void:
    # Tick consists of:
    # 1. Applying movement direction (player presses key)
    # 2. Resolving party (trying to move and attacking enemies if encountered or taking no-move damage)
    # 3. Checking if player was defeated.
    # 4. Resolving enemies movement (checking if they can move in the direction they want to, dealing damange to party if member is encountered and moving)
    # 5. Checking again if player was defeated (since enemy could have killed them)
    if not running:
        return
    tick_count += 1
    party.apply_direction(input.consume_direction())
    _resolve_party()
    if _check_defeat():
        return
    for enemy in enemies:
        if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or not grid.has_entity(enemy):
            continue
        _resolve_enemy(enemy)
        if _check_defeat():
            return
    tick_finished.emit()

func _resolve_party() -> void:
    var leader := party.members[0]
    var destination := leader.grid_cell + party.facing
    # If there is enemy in destination - attack them
    if grid.is_walkable(destination) and grid.get_actor_at(destination) is Enemy:
        combat.attack(leader, party.facing, grid)
        last_action = "%s attacks" % leader.name
        return
    # If party doesn't move (for any reason like wall, another actor in destination cell, or something else) - take damage
    if not grid.try_move_batch(party.proposed_move()):
        party.take_damage(party.collision_damage)
        last_action = "Collision! -%d HP" % party.collision_damage
        return
    last_action = "Moving"
    # After movement - get any pickup at cells where party members are
    for member in party.members:
        var pickup := grid.get_pickup_at(member.grid_cell) as Pickup
        if pickup != null:
            pickup.apply_to(party)
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

        # If there is a party member in destination - hit them and advance patrol leg (so basically enemy doesn't move but only deals damage)
        var occupant := grid.get_actor_at(destination)
        if occupant != null:
            if occupant is Character and party.members.has(occupant):
                party.take_damage(enemy.contact_damage)
                last_action = "%s hits party" % enemy.name
            else:
                enemy.advance_leg()
            return
        var move: Dictionary[GridPlaceable, Vector2i] = {enemy: destination}
        if grid.try_move_batch(move):
            enemy.record_step()

func _check_defeat() -> bool:
    if party.health > 0:
        return false
    running = false
    last_action = "Defeated! Press R to restart"
    defeated.emit()
    tick_finished.emit()
    return true
