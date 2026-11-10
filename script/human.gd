extends CharacterBody3D
#Today I will finish roam element
@export var fall_acceleration = 9.8
@export var gravity = 9.8
@export var main_speed = 275

@export var spawn_point : Node3D
@export var despawn_point : Node3D

@export var splat_scene: PackedScene
#so I want the human to walk around state, running state, idle state
enum state {IDLE, WALKING, RUNNING, ATTACKING, CLAPPING, SITTER, JUMPING, DEATH}
@export var human_type : state = state.RUNNING


@onready var anim_player = $Human_Model/AnimationPlayer3
@onready var mesh_instance = $Human_Model/RootNode/HumanArmature/Skeleton3D/BaseHuman
@onready var human_model = $Human_Model
#when on each state I want the animation to play
signal human_despawned

var current_state = state.CLAPPING
var input_dir = Vector2(1,1)
var target_position = Vector3.ZERO
func _ready():
	
	change_state(state.IDLE)
	if spawn_point != null:
		global_position = spawn_point.global_position
	if despawn_point != null:
		target_position = despawn_point.global_position

#i want a system when its on the state of walking it will walk towards a designated point rihgt?.
#velocity.x and velocity.z are those that decide where the player moves right. 
func _physics_process(delta: float) -> void:
	if not is_on_floor():#gravity
		velocity.y = -9.8*delta-fall_acceleration
	else:
		velocity.y = 0
	match human_type:
		state.RUNNING:
			move(target_position, delta, main_speed*3.6)
		state.WALKING:
			anim_player.play("HumanArmature|Man_Walk")
			move(target_position, delta, main_speed)
		state.SITTER:
			anim_player.play("HumanArmature|Man_Sitting")
		state.CLAPPING:
			anim_player.play("HumanArmature|Man_Clapping")
		state.ATTACKING:
			anim_player.play("HumanArmature|Man_Punch")
		state.JUMPING:
			anim_player.play("HumanArmature|Man_Jump")
		state.DEATH:
			anim_player.play("HumanArmature|Man_Death")
		#anim_player.play("")
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


func move(t_p: Vector3,  del : float, speed : float ):
	var direction = t_p - global_position
	direction.y = 0
	
	direction = direction.normalized()
	
	if direction != Vector3.ZERO:
		look_at(global_position - direction, Vector3.UP)
	change_state(state.RUNNING)
	
	
	velocity.x = direction.x * speed * del
	velocity.z = direction.z * speed * del
	
	var distance_to_target = global_position.distance_to(t_p)
	if distance_to_target < 2.0:
		human_despawned.emit()
		queue_free()
	return

func spawn_splat(global_hit_point: Vector3):
	var splat = splat_scene.instantiate()
	
	human_model.add_child(splat)
	
	splat.global_position = global_hit_point
	
	splat.rotation.z =  randf_range(0, TAU)
