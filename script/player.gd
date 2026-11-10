extends CharacterBody3D

enum BirdState { FLY, GLIDE, IDLE, TAKEOFF, LANDING, SPRINTING }

@export var owl_stats: BirdStats
@export var poop: PackedScene
@export var splat: PackedScene
@export var speed_lines_ui: ColorRect
@export var camera_rig: Node3D
@export var camera_spring_arm: SpringArm3D

@export_group("Movement")
@export var speed := 20.0
@export var cruise_speed := 10.0
@export var acceleration := 25.0
@export var deceleration := 20.0

@export_group("Vertical")
@export var fall_acceleration := 9.8
@export var flap_velocity := 1000
@export var flap_acceleration := 10

@export_group("Stamina and Cooldowns")
@export var stamina_drain_interval := 3.3
@export var stamina_regen_interval := 2.0
@export var exhausted_duration := 5.0
@export var flap_regen_interval := 1.0
@export var poop_cooldown := 2.0

@export_group("Landing")
@export var landing_distance_threshold := 1.5

@export_group("Audio")
@export var bird_sound : Node

@onready var pivot: Node3D = $Pivot
@onready var debug_label: Label = $CanvasLayer/Label
@onready var shadow_aim: Node3D = $ShadowAim
@onready var ground_ray: RayCast3D = $GroundRay
@onready var landing_ray: RayCast3D = $LandingRay
@onready var poop_spawn: Marker3D = $Marker3D
@onready var animation := $Pivot/Sketchfab_Scene/AnimationPlayer2

@onready var flaps: int = owl_stats.max_flaps
@onready var stamina: int = owl_stats.stamina

var current_state := BirdState.IDLE
var fall_speed := 0.0
var is_sprinting := false
var drain_timer := 0.0
var stamina_regen_timer := 0.0
var flap_regen_timer := 0.0
var exhausted_timer := 0.0
var poop_timer := 0.0


func _ready() -> void:
	change_state(BirdState.IDLE)
	speed_lines_ui.visible = false


func _physics_process(delta: float) -> void:
	var direction := get_input_direction()
	face_direction(direction)
	update_state(delta)
	check_landing()

	var horizontal := get_horizontal_velocity(direction, delta)
	var ground := get_ground_velocity(direction, delta)
	var vertical := get_vertical_velocity(delta, direction)

	update_sprint(direction)

	if is_on_floor():
		velocity = Vector3(ground.x, vertical, ground.z)
	else:
		velocity = Vector3(horizontal.x, vertical, horizontal.z)

	move_and_slide()

	update_shadow()
	update_poop(delta)
	update_debug_label()


func update_state(delta: float) -> void:
	if is_on_floor():
		if current_state == BirdState.FLY or current_state == BirdState.GLIDE:
			change_state(BirdState.LANDING)
		elif current_state == BirdState.IDLE:
			if Input.is_action_just_pressed("fly") and flaps > 0:
				change_state(BirdState.TAKEOFF)
	elif current_state != BirdState.TAKEOFF and current_state != BirdState.FLY:
		if Input.is_action_pressed("fly") and stamina > 0 and not is_sprinting:
			if current_state != BirdState.SPRINTING:
				if bird_sound: bird_sound.play_flap_sound()
				change_state(BirdState.FLY)
		elif is_sprinting:
			change_state(BirdState.SPRINTING)
			drain_stamina(delta)
		elif current_state != BirdState.GLIDE and current_state != BirdState.LANDING:
			change_state(BirdState.GLIDE)


func check_landing() -> void:
	if current_state != BirdState.FLY and current_state != BirdState.GLIDE:
		return
	if velocity.y < 0.0 and landing_ray.is_colliding():
		var distance_to_ground := global_position.distance_to(landing_ray.get_collision_point())
		if distance_to_ground <= landing_distance_threshold:
			change_state(BirdState.LANDING)


func update_sprint(direction: Vector3) -> void:
	if Input.is_action_pressed("speedup") and direction != Vector3.ZERO and stamina > 0:
		if not is_sprinting:
			is_sprinting = true
			speed_lines_ui.visible = true
			change_state(BirdState.SPRINTING)
	elif is_sprinting:
		is_sprinting = false
		speed_lines_ui.visible = false


func get_input_direction() -> Vector3:
	var input := Input.get_vector("left", "right", "front", "back")
	var cam_basis := camera_spring_arm.global_transform.basis
	var direction := (cam_basis * Vector3(input.x, 0.0, input.y)).normalized()

	if not is_sprinting:
		direction.y = 0.0
		direction = direction.normalized()
	return direction


func get_ground_velocity(direction: Vector3, _delta: float) -> Vector3:
	return direction * 2.0


func face_direction(direction: Vector3) -> void:
	if direction != Vector3.ZERO:
		pivot.basis = Basis.looking_at(direction)


func get_horizontal_velocity(direction: Vector3, delta: float) -> Vector3:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var flat_dir := Vector3(direction.x, 0.0, direction.z)
	if flat_dir == Vector3.ZERO:
		return horizontal.move_toward(Vector3.ZERO, deceleration * delta)

	var top_speed := speed if is_sprinting else cruise_speed
	return horizontal.move_toward(flat_dir.normalized() * top_speed, acceleration * delta)


func get_vertical_velocity(delta: float, direction: Vector3) -> float:
	var flapped := Input.is_action_just_pressed("fly") and flaps > 0
	var hovering := Input.is_action_pressed("fly") and stamina > 0
	regen_flaps(delta)

	if is_sprinting and direction != Vector3.ZERO:
		var target_vertical_speed := direction.y * speed
		velocity.y = move_toward(velocity.y, target_vertical_speed, acceleration * delta)
		return velocity.y

	if flapped:
		flaps -= 1
		fall_speed = 0.0
		if not is_on_floor():
			change_state(BirdState.FLY)
		return flap_velocity

	if hovering:
		drain_stamina(delta)
		return fall_speed

	regen_stamina(delta)
	if fall_speed < -fall_acceleration *12 *delta:
		fall_speed = -fall_acceleration * 12 * delta
	else:
		fall_speed -= fall_acceleration * 0.05 * delta
	return fall_speed


func drain_stamina(delta: float) -> void:
	drain_timer += delta
	if is_sprinting and stamina > 0:
		drain_timer += 2.0 * delta
	elif stamina == 0:
		is_sprinting = false
	if drain_timer >= stamina_drain_interval:
		drain_timer = 0.0
		stamina -= 1


func regen_stamina(delta: float) -> void:
	if stamina >= owl_stats.stamina:
		stamina_regen_timer = 0.0
		return
	stamina_regen_timer += delta
	if stamina_regen_timer >= stamina_regen_interval:
		stamina_regen_timer = 0.0
		stamina += 1


func regen_flaps(delta: float) -> void:
	if flaps >= owl_stats.max_flaps:
		flap_regen_timer = 0.0
		return
	flap_regen_timer += delta
	if flap_regen_timer >= flap_regen_interval:
		flap_regen_timer = 0.0
		flaps += 1


func update_shadow() -> void:
	shadow_aim.visible = ground_ray.is_colliding()
	if shadow_aim.visible:
		shadow_aim.global_position = ground_ray.get_collision_point() + Vector3(0.0, 0.05, 0.0)


func update_poop(delta: float) -> void:
	poop_timer = maxf(poop_timer - delta, 0.0)
	if Input.is_action_just_pressed("poop") and poop_timer <= 0.0:
		poop_timer = poop_cooldown
		drop_poop()


func drop_poop() -> void:
	var drop := poop.instantiate()
	drop.poop_fell.connect(on_poop_fell)
	get_parent().add_child(drop)
	drop.global_position = poop_spawn.global_position


func on_poop_fell(poop_instance: Node3D) -> void:
	var splat_instance: Node3D = splat.instantiate()
	get_parent().add_child(splat_instance)
	splat_instance.global_position = poop_instance.global_position + Vector3(0.0, 0.07, 0.0)
	poop_instance.queue_free()


func update_debug_label() -> void:
	var status := " (exhausted)" if exhausted_timer > 0.0 else ""
	debug_label.text = "Current_Flaps : %d\nCurrent Stamina : %d%s\nState : %s" % [
		flaps, stamina, status, BirdState.keys()[current_state]
	]


func change_state(new_state: BirdState) -> void:
	if current_state == new_state:
		return

	current_state = new_state
	
	if bird_sound:
		bird_sound.change_audio_state(current_state)

	match current_state:
		BirdState.IDLE:
			animation.play(" 2/BirdRig|Standing Idle")
			animation.speed_scale = 1.0
		BirdState.TAKEOFF:
			if bird_sound: bird_sound.play_takeoff_sound()

			animation.play(" 2/BirdRig|Takeoff")
			animation.speed_scale = 1.7
			velocity.y = flap_velocity
		BirdState.GLIDE:
			animation.play(" 2/BirdRig|Gliding")
			animation.speed_scale = 1.0
		BirdState.FLY:
			animation.play(" 2/BirdRig|Flapping")
			animation.speed_scale = 0.667
		BirdState.LANDING:
			if bird_sound: 
				print_debug("landing sound")
				bird_sound.play_takeoff_sound()
			animation.play(" 2/BirdRig|Landing")
			animation.speed_scale = 1.7
		BirdState.SPRINTING:
			animation.play(" 2/BirdRig|Flapping")
			animation.speed_scale = 1.3


func _on_animation_player_2_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		" 2/BirdRig|Takeoff":
			if not is_sprinting and Input.is_action_pressed("fly") and stamina > 0:
				change_state(BirdState.FLY)
			else:
				change_state(BirdState.GLIDE)
		" 2/BirdRig|Landing":
			change_state(BirdState.IDLE)
		" 2/BirdRig|Flapping":
			if bird_sound: bird_sound.play_flap_sound()
			if Input.is_action_pressed("fly") and current_state == BirdState.FLY:
				animation.play(" 2/BirdRig|Flapping")
				
			else:
				change_state(BirdState.GLIDE)
