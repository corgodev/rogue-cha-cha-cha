class_name Room
extends Node2D

@export var starting_snake: Array[Character] = []
@onready var grid: RoomGrid = %RoomGrid
@onready var _entities: Node2D = %GridEntities
var enemies: Array[Enemy] = []
var characters: Array[Character] = []
var pickups: Array[Pickup] = []
var doors: Array[Doors] = []
var initialization_ok: bool = true

func _ready() -> void:
    for child in _entities.get_children():
        if not child is WorldEntity:
            continue
        var entity := child as WorldEntity
        if not grid.can_traverse(entity.global_position, entity.global_position, entity.collision_radius):
            push_error("%s overlaps impassable terrain." % entity.name)
            initialization_ok = false
        if entity is Enemy:
            enemies.append(entity)
            if entity.patrol == null or not entity.patrol.is_valid():
                push_error("Enemy %s needs a valid patrol." % entity.name)
                initialization_ok = false
        elif entity is Character:
            characters.append(entity)
            if entity.attack == null:
                initialization_ok = false
                push_error("Character %s needs an attack." % entity.name)
        elif entity is Pickup:
            pickups.append(entity)
        elif entity is Doors:
            doors.append(entity)
    var actors: Array[WorldEntity] = []
    actors.append_array(characters)
    actors.append_array(enemies)
    for door in doors:
        if not door.open:
            actors.append(door)
    for index in actors.size():
        for other in range(index + 1, actors.size()):
            if WorldEntity.sweep_overlaps(actors[index].global_position, actors[index].global_position, actors[other].global_position, actors[index].collision_radius + actors[other].collision_radius):
                initialization_ok = false
                push_error("%s and %s overlap at room startup." % [actors[index].name, actors[other].name])

func can_traverse(from: Vector2, to: Vector2, radius: float, ignored: WorldEntity = null, ignore_characters: bool = false) -> bool:
    if not grid.can_traverse(from, to, radius):
        return false
    for enemy in enemies:
        if is_instance_valid(enemy) and enemy != ignored and enemy.is_active():
            if WorldEntity.sweep_overlaps(from, to, enemy.global_position, radius + enemy.collision_radius):
                return false
    for door in doors:
        if is_instance_valid(door) and door.is_active() and not door.open:
            if WorldEntity.sweep_overlaps(from, to, door.global_position, radius + door.collision_radius):
                return false
    if not ignore_characters:
        for character in characters:
            if is_instance_valid(character) and character != ignored and character.is_active():
                if WorldEntity.sweep_overlaps(from, to, character.global_position, radius + character.collision_radius):
                    return false
    return true

func has_line_of_sight(from: Vector2, to: Vector2) -> bool:
    if not grid.can_traverse(from, to, 0.0):
        return false
    for door in doors:
        if is_instance_valid(door) and not door.open and WorldEntity.sweep_overlaps(from, to, door.global_position, door.collision_radius):
            return false
    return true
