extends Label

var speed = 0


func _ready() -> void:
	while true:
		await get_tree().create_timer(0.01).timeout
		text = "Speed:  %s" %($"../Player".velocity)
