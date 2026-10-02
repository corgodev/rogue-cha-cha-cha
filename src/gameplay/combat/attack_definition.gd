class_name AttackDefinition
extends Resource

enum Shape {ADJACENT, FRONT_ROW, FORWARD_RAY}
@export var shape: Shape = Shape.ADJACENT
@export_range(1, 100) var damage: int = 3
@export_range(0.1, 10.0) var cooldown: float = 1.0
@export_range(1.0, 320.0) var reach: float = 16.0
@export_range(1.0, 160.0) var width: float = 16.0

# All three existing attacks become oriented world-space rectangles. Resource
# dimensions preserve their short, wide, and ranged identities.
func local_area() -> Rect2:
    return Rect2(Vector2(0.0, -width * 0.5), Vector2(reach, width))
