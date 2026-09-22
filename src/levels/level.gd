class_name GameLevel
extends Node2D

var npcs_eaten: float = 0
@onready var seed: Seed = %Seed
@onready var score: Label = %Score


func _ready() -> void:
    for npc: NPC in get_tree().get_nodes_in_group("npc"):
        npc.npc_dropped.connect(npc_dropped)


func npc_dropped(npc: NPC) -> void:
    if seed.mouse_inside:
        npcs_eaten += 1.0
        score.text = "Score: %s" % npcs_eaten
        seed.add_mass_produced(npc.mass_added)
        npc.fall(true)
    else:
        npc.fall(false)
