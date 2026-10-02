extends Node2D

var flashes: Array[Dictionary] = []

func show_attack(origin: Vector2, direction: Vector2, area: Rect2, _damage: int) -> void:
    flashes.append({"origin": origin, "angle": direction.angle(), "area": area, "remaining": 0.2})
    queue_redraw()

func _process(delta: float) -> void:
    if flashes.is_empty():
        return
    for index in range(flashes.size() - 1, -1, -1):
        flashes[index].remaining -= delta
        if flashes[index].remaining <= 0.0:
            flashes.remove_at(index)
    queue_redraw()

func _draw() -> void:
    for flash in flashes:
        var area: Rect2 = flash.area
        var polygon := PackedVector2Array()
        for corner in [area.position, Vector2(area.end.x, area.position.y), area.end, Vector2(area.position.x, area.end.y)]:
            polygon.append(to_local(flash.origin + corner.rotated(flash.angle)))
        draw_colored_polygon(polygon, Color(1.0, 0.8, 0.3, flash.remaining * 2.5))
