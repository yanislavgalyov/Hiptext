extends Node2D

var pos = Vector2(0, 24)
var offset = 0


func _physics_process(delta: float) -> void:
	position = position.lerp(pos, delta * 15)
