extends CharacterBody3D

@export var owl_stats : BirdStats

@export var speed = 20
@export var fall_acceleration = 9.8
@export var gravity = 0
@export var jump_impulse = 4
@export var poop : PackedScene
@export var splat : PackedScene

@onready var debug_label = $CanvasLayer/Label
@onready var current_flaps = owl_stats.max_flaps
@onready var current_stamina = owl_stats.stamina
@onready var shadow_aim = $ShadowAim
@onready var ground_ray = $GroundRay

var target_velocity = Vector3.ZERO
var state = "fall"
var frame_counter = 0
var fly_counter = 0
var flyable = true
var stamina_cooldown = 5
var ground_speed = 4
var poop_cooldown = 2
var poopable = true

func _physics_process(delta: float) -> void:
	frame_counter += 1
	var direction = Vector3.ZERO

	debug_label.text = "Current_Flaps : " + str(current_flaps)
#movements
	if Input.is_action_pressed("right"):
		direction.x += 1
	if Input.is_action_pressed("left"):
		direction.x -= 1
	if Input.is_action_pressed("front"):
		direction.z -= 1
	if Input.is_action_pressed("back"):
		direction.z += 1


	direction = direction.rotated(Vector3.UP, $CameraSpringArm/Camera3D.global_rotation.y)

#organize the direction where the player looks at
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		$Pivot.basis = Basis.looking_at(direction)

	if Input.is_action_just_pressed("fly") and current_flaps != 0:
		state = "fly"
		direction.y += 1
		gravity = 0
		current_flaps -= 1 

	if Input.is_action_pressed("fly") and flyable == true:
		fly_counter += 1
		state = "fly"
		gravity = 0
		debug_label.text += "\nFly Counter : " + str(fly_counter)

		if fly_counter >= 200 and current_stamina > 0:
			current_stamina -= 1
			fly_counter = 0

	debug_label.text += "\nCurrent Stamina : " + str(current_stamina)


	if current_stamina == 0 and flyable == true:
		flyable = false
	if frame_counter % 120 == 0 and current_stamina <= owl_stats.stamina and stamina_cooldown != 5 and state == "fall":#stamina regen
		current_stamina += 1
	if frame_counter % 60 == 0 and current_flaps <= owl_stats.max_flaps: #flaps adder
		current_flaps += 1
	if frame_counter % 60 == 0: #stamina cooldown timer
		stamina_cooldown -= 1
		poop_cooldown -= 1
		if stamina_cooldown < 1:
			flyable = true
			stamina_cooldown = 5
		if poop_cooldown < 1:
			poop_cooldown = 2
			poopable = true
	if not is_on_floor():#velocity when flying
		target_velocity.x = direction.x * speed
		target_velocity.y = direction.y * jump_impulse * speed
		target_velocity.z = direction.z * speed

	else:
		target_velocity.x = direction.x * ground_speed
		target_velocity.y = direction.y * jump_impulse * speed
		target_velocity.z = direction.z * ground_speed

	if not is_on_floor():#gravity
		gravity -= (fall_acceleration*delta)

	velocity.x = target_velocity.x
	velocity.z = target_velocity.z
	velocity.y = target_velocity.y
	debug_label.text += "\nState : " + str (state)

	if not is_on_floor():#state changer
		if state == "fly":
			velocity.y = target_velocity.y
			state = "fall"
		else :
			velocity.y = gravity
	move_and_slide()


	if ground_ray.is_colliding():
		shadow_aim.visible = true
		
		var hit_point = ground_ray.get_collision_point()
		
		shadow_aim.global_position = hit_point + Vector3(0, 0.05, 0)

	else:
		shadow_aim.visible = false
		
	if Input.is_action_just_pressed("poop") :

		var a = poop.instantiate()
		a.poop_fell.connect(_on_poop_fell)
		#if poop_cooldown == 2 and poopable == true:
		get_parent().add_child(a)
		a.global_position = $Marker3D.global_position
		poopable = false

func _on_poop_fell(poop_instance):

	print_debug("_on_poop_fell called")
	var s = splat.instantiate()
	
	get_parent().add_child(s)

	s.global_position = poop_instance.global_position + Vector3(0, 0.07, 0)
	poop_instance.queue_free()
