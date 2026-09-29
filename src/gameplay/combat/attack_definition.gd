class_name AttackDefinition
extends Resource

# Resource that defines shape of the attack as well as its strength

enum Shape {ADJACENT, FRONT_ROW, FORWARD_RAY}
@export var shape: Shape = Shape.ADJACENT
@export_range(1, 100) var damage: int = 3
