extends CharacterBody3D

@export var fall_acceleration = 9.8
@export var gravity = 9.8
@export var speed = 20
#so I want the human to walk around state, running state, idle state
enum state {IDLE, WALKING, RUNNING, ATTACKING, CLAPPING}

@onready var anim_player = $Human_Model/AnimationPlayer3
#when on each state I want the animation to play

var current_state = state.CLAPPING
var input_dir = Vector2(1,1)

func _ready():
	change_state(state.WALKING)


#i want a system when its on the state of walking it will walk towards a designated point rihgt?.
#velocity.x and velocity.z are those that decide where the player moves right. 
func _physics_process(delta: float) -> void:
	if not is_on_floor():#gravity
		velocity.y = -9.8*delta-fall_acceleration
	else:
		velocity.y = 0
	
	if velocity.x == 0 and velocity.z == 0:
		change_state(state.IDLE)
	match current_state:
		state.IDLE:
			velocity.x = 0
			velocity.z = 0
		state.WALKING:
			var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

			if direction:
				print_debug(direction.x)
				print_debug(direction.y)
				velocity.x = direction.x * speed
				velocity.z = direction.y * speed
				look_at(position + direction, Vector3.UP)
				input_dir = Vector2.ZERO
			else:
				print_debug("inside else")
				velocity.x = move_toward(velocity.x, 0, speed)
				velocity.z = move_toward(velocity.z, 0, speed)
	move_and_slide()


func change_state(new_state : state):
	
	if current_state == new_state:
		return

	current_state = new_state
	match current_state:
		state.IDLE:
			anim_player.play("HumanArmature|Man_Idle")
		state.RUNNING:
			anim_player.play("HumanArmature|Man_Run")
		state.WALKING:
			anim_player.play("HumanArmature|Man_Walk")
		state.ATTACKING:
			anim_player.play("HumanArmature|Man_Punch")
		
		
		
		
		
