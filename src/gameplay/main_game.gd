class_name Game
extends Node2D

@export var CURRENT_ROOM: Room
@onready var snake: Snake = $Snake
@onready var controller: PlayerController = $PlayerController
@onready var gameplay: GameplayController = $GameplayController
@onready var status: Label = $HUD/Status
@onready var detail: Label = $HUD/Detail

func _ready() -> void:
    if CURRENT_ROOM == null:
        status.text = "Setup failed: assign CURRENT_ROOM."
        return
    if not CURRENT_ROOM.initialization_ok:
        status.text = "Room setup failed; check debugger."
        return
    if not snake.initialize(CURRENT_ROOM.starting_snake, CURRENT_ROOM):
        status.text = "Snake setup failed; check debugger."
        push_error("Starting party needs distinct registered characters, attacks, and member-spacing separation.")
        return
    gameplay.initialize(CURRENT_ROOM, snake, controller)
    var feedback := CURRENT_ROOM.get_node_or_null("AttackFeedback")
    if feedback != null:
        gameplay.combat.attacked.connect(feedback.show_attack)
    _update_hud()

func _process(_delta: float) -> void:
    if gameplay.room == null:
        return
    _update_hud()
    if gameplay.running and snake.consume_step_sound():
        FmodServer.play_one_shot("event:/step")

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
        get_tree().reload_current_scene()

func _update_hud() -> void:
    status.text = "HP %d/%d   Time %ds   Party %d" % [snake.health, snake.max_health, int(gameplay.elapsed), snake.members.size()]
    detail.text = gameplay.last_action
