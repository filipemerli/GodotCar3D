extends VehicleBody3D

const FORCE: int = 550
const MAX_SPEED: float = 890.0 # divide it by 3.6 to get real velocity
const METERSPORSEC = 3.6

@onready var camera_pivot = $CameraPivot
@onready var camera_3d = $CameraPivot/Camera3D
@onready var sound: AudioStreamPlayer3D = $EngineSound 

@export var steering_speed = 1.1

var target_look

func _ready() -> void:
	camera_pivot.top_level = true
	target_look = global_position
	camera_3d.position = Vector3(0, 1.9, -6.0)
	sound.play()

func handleCam(delta):
	camera_pivot.global_position = camera_pivot.global_position.lerp(
		global_position, 
		delta * 20.0
	)
	camera_pivot.transform = camera_pivot.transform.interpolate_with(
		transform, 
		delta * 5.0
	)
	target_look = target_look.lerp(
		global_position + linear_velocity, 
		delta * 5.0
	)
	camera_3d.look_at(target_look)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("changeCam"):
		$CameraPivot/Camera3D.current = false
		$Camera3D.current = true
	handleSound()
	steering = move_toward(
		steering, 
		Input.get_axis("ui_right", "ui_left") * .8, 
		delta * steering_speed
	)
	var acc = Input.get_axis("ui_down", "ui_up")
	var current_speed = linear_velocity.length() * METERSPORSEC
	var speed_factor = clamp(1.0 - (current_speed / MAX_SPEED), 0.0, 1.0)
	engine_force = acc * FORCE * speed_factor

func _physics_process(delta: float) -> void:
	handleCam(delta)

func handleSound():
	## 52 is almost the max speed value and 0.5 is the minimum pitch I want
	var newVal = (linear_velocity.length() / 52) + 0.5 
	sound.set_pitch_scale(newVal)

### SIMPLE WAY
#func _process(delta: float) -> void:
	#steering = move_toward(
		#steering,
		#Input.get_axis("ui_right", "ui_left") * .8,
		#delta * 1.1
	#)
	#var acc = Input.get_axis("ui_down", "ui_up")
	#engine_force = acc * FORCE
