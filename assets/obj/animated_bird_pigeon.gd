extends Node3D


# Called when the node enters the scene tree for the first time.


func _on_animation_player_2_animation_finished(anim_name: StringName) -> void:
	if anim_name == " 2/BirdRig|Takeoff":
		change_state(BirdState.FLY)
	elif anim_name == " 2/BirdRig|Landing":
		change_state(BirdState.IDLE)
		
	elif anim_name  == " 2/BirdRig|Flapping":
		if hovering:
			animation.play(" 2/BirdRig|Flapping")
		else:
			change_state(BirdState.GLIDE)
