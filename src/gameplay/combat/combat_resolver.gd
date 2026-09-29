class_name CombatResolver
extends RefCounted

signal attacked(cells: Array[Vector2i], damage: int)

func target_cells(origin: Vector2i, forward: Vector2i, attack: AttackDefinition, grid: RoomGrid) -> Array[Vector2i]:
    var cells: Array[Vector2i] = []
    match attack.shape:
        AttackDefinition.Shape.ADJACENT:
            if grid.is_walkable(origin + forward):
                cells.append(origin + forward)
        AttackDefinition.Shape.FRONT_ROW:
            var side := Vector2i(-forward.y, forward.x)
            for offset in range(-1, 2):
                var cell := origin + forward + side * offset
                if grid.is_walkable(cell):
                    cells.append(cell)
        AttackDefinition.Shape.FORWARD_RAY:
            for distance in range(1, 4):
                var cell := origin + forward * distance
                if not grid.is_walkable(cell):
                    break
                cells.append(cell)
    return cells

func attack(leader: Character, forward: Vector2i, grid: RoomGrid) -> void:
    var cells := target_cells(leader.grid_cell, forward, leader.attack, grid)
    for cell in cells:
        var enemy := grid.get_actor_at(cell) as Enemy
        if enemy != null:
            enemy.health = maxi(0, enemy.health - leader.attack.damage)
            enemy.queue_redraw()
            if enemy.health == 0:
                grid.remove(enemy)
                enemy.queue_free()
    attacked.emit(cells, leader.attack.damage)
