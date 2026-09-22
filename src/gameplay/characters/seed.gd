@tool
class_name Seed
extends Node2D

@export var production_rate := 600.0
@export var creep_field: Node2D:
    set(value):
        if not Engine.is_editor_hint() and is_inside_tree() and is_instance_valid(creep_field):
            creep_field.UnregisterSource(self)
        creep_field = value
        if not Engine.is_editor_hint() and is_inside_tree() and is_instance_valid(creep_field):
            creep_field.RegisterSource(self)
        update_configuration_warnings()

@onready var sprite: AnimatedSprite2D = %Sprite
var mouse_inside = false


func add_mass_produced(mass: float) -> void:
    production_rate += mass


func _enter_tree() -> void:
    if not Engine.is_editor_hint() and is_instance_valid(creep_field):
        creep_field.RegisterSource(self)


func _exit_tree() -> void:
    if not Engine.is_editor_hint() and is_instance_valid(creep_field):
        creep_field.UnregisterSource(self)


func emission_position() -> Vector2:
    return (%CreepOrigin as Marker2D).global_position


func _get_configuration_warnings() -> PackedStringArray:
    if creep_field == null:
        return PackedStringArray(
            [
                "Assign the level's CreepField to produce creep. Use creep_preview.tscn for standalone testing."
            ]
        )
    return PackedStringArray()


func _on_area_2d_mouse_entered() -> void:
    mouse_inside = true
    sprite.play("open")


func _on_area_2d_mouse_exited() -> void:
    mouse_inside = false
    sprite.play_backwards("open")
    sprite.animation_finished.connect(
        func():
            sprite.play("idle"),
        CONNECT_ONE_SHOT,
    )
