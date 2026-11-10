extends Node
@export var camera_to_follow: Node3D

@onready var fly_audio = $FlyAudio
@onready var sprint_audio = $SprintAudio
@onready var flap_audio = $FlapAudio
@onready var takeoff_audio = $TakeoffAudio
var active_tweens := {}
var current_audio_state := -1

func _ready():
	fly_audio.volume_db = -80.0
	sprint_audio.volume_db = -80.0

func _process(delta: float) -> void:
	if camera_to_follow != null:
		fly_audio.global_position = camera_to_follow.global_position
		sprint_audio.global_position = camera_to_follow.global_position

func change_audio_state(new_state: int):
	print("Audio state requested: ", new_state)

	if (new_state == 0 or new_state == 1) and (current_audio_state == 0 or current_audio_state == 1):
		current_audio_state = new_state
		return
		
	current_audio_state = new_state

	fade_audio(fly_audio, -80.0, 0.3)
	fade_audio(sprint_audio, -80.0, 0.3)
	
	match new_state:
		0, 1:
			fly_audio.pitch_scale = randf_range(0.9, 1.1)
			fade_audio(fly_audio, -12, 0.3)
		5: # SPRINTING
			sprint_audio.pitch_scale = randf_range(0.95, 1.05)
			fade_audio(sprint_audio, -12, 0.2)

func play_flap_sound():
	if camera_to_follow != null:
		flap_audio.global_position = camera_to_follow.global_position	
	
	if flap_audio.playing:
		flap_audio.stop()
	
	flap_audio.pitch_scale = randf_range(0.85, 1.15)
	fade_audio(flap_audio, 0, 0.3)

func play_takeoff_sound():
	print_debug("playing takeoff sound")
	

	
	if takeoff_audio.playing:
		takeoff_audio.stop()
		
	takeoff_audio.pitch_scale = randf_range(0.85, 1.15)
	takeoff_audio.volume_db = 0.0 
	takeoff_audio.play()
	
	fade_audio(takeoff_audio, -12, 0.5)

func fade_audio(audio_node: AudioStreamPlayer3D, target_db: float, duration: float):
	if active_tweens.has(audio_node):
		active_tweens[audio_node].kill()

	if target_db > -80.0 and not audio_node.playing:
		audio_node.play()
		
	var tween = create_tween()
	active_tweens[audio_node] = tween
	tween.tween_property(audio_node, "volume_db", target_db, duration)
	
	if target_db == -80.0:
		tween.tween_callback(audio_node.stop)
