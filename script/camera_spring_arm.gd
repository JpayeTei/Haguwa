extends SpringArm3D

@export var mouse_sensitivity := 0.003

func _ready() -> void:
	top_level = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(_delta: float) -> void:
	global_position = get_parent().global_position + Vector3(0, 1.0, 0)

func _unhandled_input(event: InputEvent) -> void:
	# Toggle mouse capture with Tab / Escape
	if event.is_action_pressed("escape_mouse"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * mouse_sensitivity
		rotation.x = clamp(rotation.x - event.relative.y * mouse_sensitivity, -1.2, 0.6)
