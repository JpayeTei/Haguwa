extends Node3D
@export var human_scene : PackedScene
@onready var spawn_node := $SpawnPoint
@onready var despawn_node := $DespawnPoint
@onready var spawn_node_1 := $SpawnPoint2
@onready var despawn_node_1 := $DespawnPoint2
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawn_human()
	pass # Replace with function body.
func _physics_process(delta: float) -> void:
	
	pass
func spawn_human():
	var new_human = human_scene.instantiate()
	var new_human_1 = human_scene.instantiate()
	new_human_1.spawn_point = spawn_node_1
	new_human_1.despawn_point = despawn_node_1
	new_human_1.human_type = new_human_1.state.WALKING
	new_human.spawn_point = spawn_node
	new_human.despawn_point = despawn_node
	new_human.human_despawned.connect(_on_human_despawned)
	new_human_1.human_despawned.connect(_on_human_despawned)
	
	add_child(new_human)
	add_child(new_human_1)
func _on_human_despawned():

	spawn_human.call_deferred()
