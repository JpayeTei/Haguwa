extends Node3D

@export var player: CharacterBody3D

@export_group("Follow Settings")
@export var follow_speed: float = 5.0

@export_group("Sprint Effects")
@export var base_fov: float = 75.0
@export var sprint_fov: float = 90.0
@export var base_spring_length: float = 3.0
@export var sprint_spring_length: float = 5.0
@export var sprint_lerp_speed: float = 5.0

@onready var spring_arm: SpringArm3D = $CameraSpringArm
@onready var camera: Camera3D = $CameraSpringArm/Camera3D


func _ready() -> void:
	if player:
		global_position = player.global_position


func _process(delta: float) -> void:
	if not player:
		return

	global_position = global_position.lerp(player.global_position, follow_speed * delta)

	var target_fov := sprint_fov if player.is_sprinting else base_fov
	var target_length := sprint_spring_length if player.is_sprinting else base_spring_length
	var blend := sprint_lerp_speed * delta

	camera.fov = lerpf(camera.fov, target_fov, blend)
	spring_arm.spring_length = lerpf(spring_arm.spring_length, target_length, blend)
