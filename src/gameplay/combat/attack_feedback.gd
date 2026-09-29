extends Node2D

# Presentation only: the attack is already resolved before this flash appears.
@export var grid: RoomGrid
var cells: Array[Vector2i] = []
var remaining: float = 0.0


# The way it works is that we draw rectangle over cells that are attacked.
# Each visual frame we decrease remaining value and tell godot to redraw it.
# Opacity of the visual depends on the remaining value which lowers every frame.
func show_attack(targets: Array[Vector2i], _damage: int) -> void:
    cells = targets.duplicate()
    remaining = 0.3
    queue_redraw()

func _process(delta: float) -> void:
    if remaining > 0.0:
        remaining = maxf(0.0, remaining - delta)
        queue_redraw()

func _draw() -> void:
    if remaining <= 0.0:
        return
    var size := Vector2(grid.ground.tile_set.tile_size)
    for cell in cells:
        var center := to_local(grid.cell_to_world(cell))
        draw_rect(Rect2(center - size / 2.0, size), Color(1.0, 0.8, 0.3, remaining * 1.5))
