extends RigidBody3D
var player : Node3D
signal poop_fell

var has_hit = false

func _on_body_entered(body: Node) -> void:
	if has_hit:
		return
	has_hit = true
	if body.collision_layer == 2:
		poop_fell.emit(self)
