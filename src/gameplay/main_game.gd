class_name Game
extends Node2D

# TODO: To consider - do we want to increase game tick frequency with time or something similar (like how the snake goes faster in snake?)
@export_range(0.1, 10.0) var GAME_TICK_FREQUENCY: float = 1.0
@export var CURRENT_ROOM: Room
@onready var timer: Timer = $GameTickTimer
@onready var snake: Snake = $Snake
@onready var controller: PlayerController = $PlayerController
@onready var turns: TurnController = $TurnController
@onready var status: Label = $HUD/Status
@onready var detail: Label = $HUD/Detail

func _ready() -> void:
    if CURRENT_ROOM == null:
        status.text = "Setup failed: assign CURRENT_ROOM."
        detail.text = "Select MainGame and assign the room in Inspector."
        push_error("MainGame.CURRENT_ROOM is empty. Assign the room instance in the Inspector.")
        return
    if not CURRENT_ROOM.initialization_ok:
        status.text = "Room setup failed; check debugger."
        return
    if not snake.initialize(CURRENT_ROOM.starting_snake, CURRENT_ROOM.grid):
        status.text = "snake setup failed; check debugger."
        push_error("Starting snake needs distinct, adjacent, registered characters with attacks.")
        return
    turns.initialize(CURRENT_ROOM.grid, snake, controller, CURRENT_ROOM.enemies)
    var feedback := CURRENT_ROOM.get_node_or_null("AttackFeedback")
    if feedback != null:
        turns.combat.attacked.connect(feedback.show_attack)
    turns.tick_finished.connect(_update_hud)
    turns.defeated.connect(timer.stop)
    timer.timeout.connect(turns.advance_tick)
    timer.wait_time = 1.0 / GAME_TICK_FREQUENCY
    _update_hud()
    timer.start()

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
        get_tree().reload_current_scene()

func _update_hud() -> void:
    status.text = "HP %d/%d   Tick %d   %s" % [snake.health, snake.max_health, turns.tick_count, snake.members[0].name]
    detail.text = turns.last_action
