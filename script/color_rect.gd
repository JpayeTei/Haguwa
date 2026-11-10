extends ColorRect

@export var player: CharacterBody3D 
@export var fade_speed: float = 1

var tween: Tween
var current_target: float = 0.0

func _ready():
	modulate.a = 0.0 

func _process(_delta):
	if player == null: return

	var new_target = 0.7 if player.is_sprinting else 0.0

	if new_target != current_target:
		current_target = new_target
		
		if tween and tween.is_running():
			tween.kill()
			
		tween = create_tween()
		
		tween.tween_property(self, "modulate:a", current_target, fade_speed)
