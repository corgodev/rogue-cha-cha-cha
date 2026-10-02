extends SceneTree

var failures: int = 0
var checks: int = 0

func _initialize() -> void:
    _run.call_deferred()

func check(condition: bool, message: String) -> void:
    checks += 1
    if not condition:
        failures += 1
        push_error(message)

func make_room(positions: Array[Vector2]) -> Room:
    var room := Room.new()
    var ground := TileMapLayer.new()
    ground.name = "Ground"
    ground.tile_set = load("res://resources/tileset.tres")
    room.add_child(ground)
    for x in range(-10, 30):
        for y in range(-10, 30):
            ground.set_cell(Vector2i(x, y), 1, Vector2i.ZERO)
    var walls := TileMapLayer.new()
    walls.name = "Walls"
    walls.tile_set = ground.tile_set
    room.add_child(walls)
    var grid := RoomGrid.new()
    grid.name = "RoomGrid"
    grid.ground = ground
    grid.walls = walls
    room.add_child(grid)
    grid.owner = room
    grid.unique_name_in_owner = true
    var entities := Node2D.new()
    entities.name = "GridEntities"
    room.add_child(entities)
    entities.owner = room
    entities.unique_name_in_owner = true
    for position in positions:
        var member := make_character(position)
        entities.add_child(member)
        room.starting_snake.append(member)
    root.add_child(room)
    check(room.initialization_ok, "Fixture room initializes")
    return room

func make_character(position: Vector2) -> Character:
    var character: Character = load("res://src/gameplay/characters/character.tscn").instantiate()
    character.position = position
    character.attack = load("res://resources/attacks/warrior.tres").duplicate()
    return character

func make_snake(room: Room) -> Snake:
    var snake := Snake.new()
    room.add_child(snake)
    check(snake.initialize(room.starting_snake, room), "Snake initializes")
    return snake

func add_enemy(room: Room, position: Vector2, health: int = 20) -> Enemy:
    var enemy: Enemy = load("res://src/gameplay/enemies/enemy.tscn").instantiate()
    enemy.definition = enemy.definition.duplicate()
    enemy.definition.max_health = health
    enemy.position = position
    room.get_node("GridEntities").add_child(enemy)
    room.enemies.append(enemy)
    return enemy

func make_controller(room: Room, snake: Snake) -> GameplayController:
    var controller := GameplayController.new()
    room.add_child(controller)
    controller.set_physics_process(false)
    controller.initialize(room, snake, null)
    return controller

func _run() -> void:
    _test_input()
    _test_movement_rates()
    _test_terrain_and_following()
    _test_self_collision()
    _test_recruitment()
    _test_combat()
    _test_attack_areas_and_doors()
    _test_contact_and_pickups()
    _test_contact_timing()
    _test_patrol()
    await _test_scenes_and_restart()
    print("Free movement: %d checks, %d failures" % [checks, failures])
    quit(1 if failures else 0)

func _test_input() -> void:
    var input := PlayerController.new()
    Input.action_press("up")
    Input.action_press("right")
    check(input.desired_direction().distance_to(Vector2(1, -1).normalized()) < 0.001, "Arrow input supports normalized diagonal steering")
    Input.action_release("up")
    Input.action_release("right")
    check(input.desired_direction() == Vector2.ZERO, "Releasing arrows stops steering")
    input.free()

func _test_movement_rates() -> void:
    var results: Array[Vector2] = []
    for fps in [30, 60, 120]:
        var room := make_room([Vector2(72, 72)])
        var snake := make_snake(room)
        for frame in fps:
            snake.advance(1.0 / fps, Vector2.ZERO, room)
        check(snake.members[0].global_position.distance_to(Vector2(120, 72)) < 0.01, "Release keeps constant forward speed at %d FPS" % fps)
        for frame in fps:
            snake.advance(1.0 / fps, Vector2(1, 1), room)
        results.append(snake.members[0].global_position)
        check(is_equal_approx(snake.facing.length(), 1.0), "Diagonal heading normalized")
        room.free()
    check(results[0].distance_to(results[2]) < 0.01 and results[1].distance_to(results[2]) < 0.01, "Turning is independent of frame rate")

func _test_terrain_and_following() -> void:
    var room := make_room([Vector2(72, 72), Vector2(56, 72), Vector2(40, 72)])
    var snake := make_snake(room)
    room.grid.walls.set_cell(Vector2i(8, 4), 3, Vector2i.ZERO)
    check(not room.grid.can_traverse(Vector2(72, 72), Vector2(200, 72), 5.0), "Sweep cannot tunnel through a wall")
    room.grid.ground.erase_cell(Vector2i(7, 6))
    check(not room.grid.can_traverse(Vector2(72, 104), Vector2(200, 104), 5.0), "Missing ground blocks a sweep")
    snake.advance(2.0, Vector2.RIGHT, room)
    var stopped := snake.members[0].global_position
    check(stopped.x <= 123.01 and stopped.x > 122.0, "Circle stops at the wall surface")
    check(snake.health == snake.max_health, "Wall collision causes no damage")
    check(snake.members[1].global_position.distance_to(stopped - Vector2(16, 0)) < 0.01, "Blocked chain does not compress")
    snake.advance(0.6, Vector2.UP, room)
    check(snake.members[0].global_position.y < stopped.y - 10.0, "Steering escapes a blocked wall")
    for index in snake.members.size():
        check(snake.members[index].global_position.distance_to(snake.position_on_trail(index * snake.member_spacing)) < 0.001, "Follower stays on the distance-sampled path")
        check(room.grid.can_traverse(snake.members[index].global_position, snake.members[index].global_position, 5.0), "Follower stays out of terrain")
    room.free()

func _test_self_collision() -> void:
    var room := make_room([Vector2(72, 72), Vector2(56, 72), Vector2(40, 72)])
    var snake := make_snake(room)
    # Exercise simultaneous movement: head and tail sweep through one another.
    check(not snake._can_advance([Vector2(40, 72), Vector2(56, 72), Vector2(72, 72)], room), "Swept self-collision catches crossing between frames")
    check(snake._can_advance([Vector2(73, 72), Vector2(57, 72), Vector2(41, 72)], room), "Adjacent followers do not block forward movement")
    var health := snake.health
    for frame in 240:
        snake.advance(1.0 / 120.0, Vector2.LEFT, room)
        for i in snake.members.size():
            for j in range(i + 2, snake.members.size()):
                if snake.members[i].global_position.distance_to(snake.members[j].global_position) < 9.999:
                    check(false, "Turning cannot overlap a nonadjacent member")
    check(snake.health == health, "Self-collision causes no damage")
    room.free()

func _test_recruitment() -> void:
    var room := make_room([Vector2(72, 72)])
    var snake := make_snake(room)
    var recruit := make_character(Vector2(78, 72))
    room.get_node("GridEntities").add_child(recruit)
    room.characters.append(recruit)
    check(not snake.try_recruit(recruit, room), "Recruit waits for sufficient trail")
    snake.advance(0.5, Vector2.RIGHT, room)
    recruit.global_position = snake.members[0].global_position + Vector2(6, 0)
    var tail_position := snake.position_on_trail(16.0)
    var blocker := add_enemy(room, tail_position)
    check(not snake.try_recruit(recruit, room), "Recruit waits when tail space is occupied")
    room.enemies.erase(blocker)
    blocker.free()
    check(snake.try_recruit(recruit, room), "Touching recruit joins when tail space is safe")
    check(recruit.global_position.distance_to(tail_position) < 0.001, "Recruit is placed at the tail")
    check(not snake.try_recruit(recruit, room), "Existing member cannot be recruited twice")
    room.free()

func _test_combat() -> void:
    var room := make_room([Vector2(72, 72), Vector2(56, 72)])
    var snake := make_snake(room)
    var combat := CombatResolver.new()
    var front := add_enemy(room, Vector2(86, 72))
    var back := add_enemy(room, Vector2(42, 72))
    snake.members[1].attack.cooldown = 0.5
    combat.advance(0.0, snake, room)
    check(front.health == 17 and back.health == 17, "Every member attacks its own nearest target")
    combat.advance(0.5, snake, room)
    check(front.health == 17 and back.health == 14, "Each member has an independent cooldown")
    combat.advance(0.5, snake, room)
    check(front.health == 14 and back.health == 11, "Cooldown expires in seconds")
    room.enemies.erase(front)
    front.free()
    room.enemies.erase(back)
    back.free()
    combat.advance(2.0, snake, room)
    check(snake.members[0].attack_remaining == 0.0, "No target leaves attack ready")
    front = add_enemy(room, Vector2(104, 72))
    snake.members[0].attack = load("res://resources/attacks/archer.tres").duplicate()
    room.grid.walls.set_cell(Vector2i(5, 4), 3, Vector2i.ZERO)
    combat.advance(0.0, snake, room)
    check(front.health == 20, "Attacks cannot target through walls")
    room.grid.walls.erase_cell(Vector2i(5, 4))
    combat.advance(0.0, snake, room)
    check(front.health == 19, "Ready ranged attack fires as soon as target is visible")
    front.health = 1
    combat.attack(snake.members[0], Vector2.RIGHT, room)
    combat.attack(snake.members[0], Vector2.RIGHT, room)
    check(not front.is_active() and front.health == 0, "Dead enemies immediately leave targeting and collision")
    room.free()

func _test_contact_and_pickups() -> void:
    var room := make_room([Vector2(72, 72), Vector2(56, 72)])
    var snake := make_snake(room)
    var controller := make_controller(room, snake)
    var enemy := add_enemy(room, Vector2(64, 78))
    controller._resolve_contact(enemy)
    controller._resolve_contact(enemy)
    check(snake.health == 9, "One enemy touching two members damages once per cooldown")
    enemy.contact_remaining = 0.0
    controller._resolve_contact(enemy)
    check(snake.health == 8, "Contact can damage again after cooldown")
    var potion: Pickup = load("res://src/gameplay/items/healing_potion.tscn").instantiate()
    potion.position = snake.members[1].global_position
    room.get_node("GridEntities").add_child(potion)
    room.pickups.append(potion)
    controller._collect_pickups()
    controller._collect_pickups()
    check(snake.health == 10 and potion.is_queued_for_deletion(), "Follower collects healing exactly once")
    snake.health = 1
    enemy.contact_remaining = 0.0
    controller._resolve_contact(enemy)
    var position := snake.members[0].global_position
    var enemy_position := enemy.global_position
    controller.advance(1.0, Vector2.RIGHT)
    check(not controller.running and snake.health == 0, "Lethal contact defeats party")
    check(snake.members[0].global_position == position and enemy.global_position == enemy_position, "Defeat stops all simulation")
    room.free()

func _test_contact_timing() -> void:
    var room := make_room([Vector2(72, 72)])
    var snake := make_snake(room)
    snake.members[0].attack.reach = 1.0
    var enemy := add_enemy(room, Vector2(82, 72), 100)
    enemy.definition.speed = 0.0
    var controller := make_controller(room, snake)
    controller.advance(2.1, Vector2.RIGHT)
    check(snake.health == 7, "Sustained contact hits immediately, then once each second")
    check(snake.members[0].global_position == Vector2(72, 72), "Enemy contact blocks continuous movement")
    room.free()

func _test_attack_areas_and_doors() -> void:
    var room := make_room([Vector2(72, 72)])
    var snake := make_snake(room)
    var member := snake.members[0]
    member.attack = load("res://resources/attacks/mage.tres").duplicate()
    var upper := add_enemy(room, Vector2(84, 56))
    var middle := add_enemy(room, Vector2(84, 72))
    var lower := add_enemy(room, Vector2(84, 88))
    var behind := add_enemy(room, Vector2(60, 72))
    var combat := CombatResolver.new()
    combat.attack(member, Vector2.RIGHT, room)
    check(upper.health == 19 and middle.health == 19 and lower.health == 19, "Wide attack hits each enemy in its area once")
    check(behind.health == 20, "Forward attack excludes enemies behind caster")
    for enemy in room.enemies:
        enemy.free()
    room.enemies.clear()
    var door: Doors = load("res://src/rooms/door.tscn").instantiate()
    door.position = Vector2(96, 72)
    room.get_node("GridEntities").add_child(door)
    room.doors.append(door)
    check(not room.can_traverse(Vector2(72, 72), Vector2(112, 72), 5.0, member), "Closed door blocks movement")
    check(not room.has_line_of_sight(Vector2(72, 72), Vector2(112, 72)), "Closed door blocks attacks")
    door.open = true
    check(room.can_traverse(Vector2(72, 72), Vector2(112, 72), 5.0, member), "Open door allows movement")
    check(room.has_line_of_sight(Vector2(72, 72), Vector2(112, 72)), "Open door allows attacks")
    room.free()

func _test_patrol() -> void:
    var room := make_room([Vector2(72, 72)])
    var enemy := add_enemy(room, Vector2(200, 200))
    enemy.advance(1.0 / 3.0, room)
    check(enemy.global_position.distance_to(Vector2(216, 200)) < 0.01 and enemy.leg_index == 1, "Patrol uses distance and speed, preserving one-tile leg")
    enemy.advance(1.0 / 3.0, room)
    check(enemy.global_position.distance_to(Vector2(200, 200)) < 0.01 and enemy.leg_index == 0, "Patrol returns along next leg")
    room.free()

func _test_scenes_and_restart() -> void:
    for path in ["res://src/rooms/playground.tscn", "res://src/rooms/test_room.tscn", "res://src/rooms/test_room_second.tscn"]:
        var scene: Node = load(path).instantiate()
        root.add_child(scene)
        if scene is Room:
            check(scene.initialization_ok, "%s initializes" % path)
        scene.free()
    for restart in 2:
        var game: Game = load("res://src/gameplay/main_game.tscn").instantiate()
        root.add_child(game)
        game.gameplay.set_physics_process(false)
        game.set_process(false)
        check(game.gameplay.running and game.snake.health == 10 and game.gameplay.elapsed == 0.0, "Fresh game resets health, clock, and simulation")
        game.gameplay.advance(0.5, Vector2.RIGHT)
        check(game.snake.members[0].global_position.x > 72.0, "Main scene runs continuous movement")
        game.queue_free()
        await process_frame
    var game: Game = load("res://src/gameplay/main_game.tscn").instantiate()
    root.add_child(game)
    current_scene = game
    game.gameplay.set_physics_process(false)
    game.gameplay.advance(0.5, Vector2.UP)
    game.snake.health = 1
    var restart_key := InputEventKey.new()
    restart_key.pressed = true
    restart_key.keycode = KEY_R
    paused = true
    game._unhandled_key_input(restart_key)
    await process_frame
    await process_frame
    var restarted := current_scene as Game
    check(is_instance_valid(restarted) and restarted != game, "R reloads the current scene")
    check(restarted.snake.health == 10 and restarted.snake.members.size() == 1, "R resets party and health")
    check(restarted.gameplay.elapsed == 0.0, "R resets elapsed time")
    restarted.queue_free()
    await process_frame
    paused = false
