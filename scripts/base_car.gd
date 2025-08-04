extends VehicleBody3D
class_name CarBase

const METERSPORSEC = 3.6
const SPEED_LVL_1: float = 75.0
const SPEED_LVL_2: float = 135.0
const SPEED_LVL_3: float = 170.0
const SPEED_LVL_4: float = 205.0
const EIGHTPERCENT: float = .8
const SEVENPERCENT: float = .7
const PERCENTAGE_1: float = 1.0
const PERCENTAGE_2: float = .73
const PERCENTAGE_3: float = .61
const PERCENTAGE_4: float = .42
const PERCENTAGE_5: float = .31
const HALF: float = .5
const QUARTER: float = .25
const SOUNDFACTOR: int = 52
const FIVEFLOAT: float = 5.0
const TWENTYFLOAT: float = 20.0

# Improved steering constants - Speed-based responsiveness approach
const MAX_STEERING_RESPONSIVENESS: float = 5.5    # Fast response at low speed (reduced from 8.0)
const MIN_STEERING_RESPONSIVENESS: float = 2.0    # Slower response at high speed
const STEERING_SPEED_THRESHOLD: float = 150.0     # Speed where steering response starts reducing
const STEERING_SMOOTHNESS: float = 1.5            # Controls steering response curve

@onready var camera_pivot = $CameraPivot
@onready var camera_3d: Camera3D = $CameraPivot/Camera3D
@onready var sound: AudioStreamPlayer3D = $EngineSound
#var backWhellL: VehicleWheel3D
#var backWhellR: VehicleWheel3D
#@onready var exhaust_system = $Exhaust

var last_sound_update_time: float = 0.0
var sound_update_interval: float = 0.1
var target_look
var isBackwards: bool = false

var max_speed: float = 890.0 # divide it by 3.6 to get real velocity
var acceleration = 550
var handling = 5.0
var braking = 7.0

#Camera handling
var camIsbackwards: bool = false

# Car state
var engine_force_value = 0.0
var steering_value = 1.0
var current_speed: float = 0.0
var brake_car: bool = false

func _ready() -> void:
	# Add this car to the "car" group
	add_to_group("car")
	
	_initialize_camera()
	_initialize_audio()
	#backWhellL = %VehicleWheelRL
	#backWhellR = %VehicleWheelRR

func _initialize_camera() -> void:
	target_look = global_position
	camera_3d.position = Vector3(0, 1.9, -6.0)
	camera_pivot.position = Vector3(0.0, 2.9, -9.487)

func _initialize_audio() -> void:
	sound.pitch_scale = HALF
	sound.play()

func handleCam(delta: float) -> void:
	_handle_camera_backwards_mode()
	_update_camera_position(delta)
	_update_camera_look_target(delta)

func _handle_camera_backwards_mode() -> void:
	var backwardsWithOffset = isBackwards and current_speed > 10.0
	if backwardsWithOffset and !camIsbackwards:
		camera_3d.position.z = 6.5
		camera_3d.position.y = 2.1
		camIsbackwards = true
	elif !backwardsWithOffset and camIsbackwards:
		camera_3d.position = Vector3(0, 1.9, -6.0)
		camIsbackwards = false

func _update_camera_position(delta: float) -> void:
	camera_pivot.global_position = camera_pivot.global_position.lerp(
		global_position, 
		delta * TWENTYFLOAT
	)
	camera_pivot.transform = camera_pivot.transform.interpolate_with(
		transform, 
		delta * FIVEFLOAT
	)

func _update_camera_look_target(delta: float) -> void:
	target_look = target_look.lerp(
		global_position + linear_velocity, 
		delta * FIVEFLOAT
	)
	camera_3d.look_at(target_look)

func _process(delta: float) -> void:
	if GameManager.isPlaying:
		_handle_active_gameplay(delta)
	else:
		_handle_stopped_state()

func _handle_active_gameplay(delta: float) -> void:
	_update_audio(delta)
	_handle_steering(delta)
	_handle_movement()

func _update_audio(delta: float) -> void:
	last_sound_update_time += delta
	if last_sound_update_time >= sound_update_interval:
		handleSound()
		last_sound_update_time = 0.0

func _handle_steering(delta: float) -> void:
	var dynamic_steering_speed: float = _calculate_steering_responsiveness()
	var target_steering: float = Input.get_axis("ui_right", "ui_left") * EIGHTPERCENT
	
	# Full steering angle available, but speed of response varies with speed
	steering = move_toward(
		steering, 
		target_steering, 
		delta * dynamic_steering_speed
	)

func _handle_movement() -> void:
	var acc = Input.get_axis("ui_down", "ui_up")
	current_speed = linear_velocity.length() * METERSPORSEC
	var speed_factor = clamp(1.0 - (current_speed / max_speed), 0.0, 1.0)
	
	_update_backwards_state()
	_apply_braking_or_acceleration(acc, speed_factor)

func _update_backwards_state() -> void:
	var velocity_direction = linear_velocity.normalized()
	var forward_direction = -global_transform.basis.z.normalized()
	isBackwards = forward_direction.dot(velocity_direction) > -0.1

func _apply_braking_or_acceleration(acc: float, speed_factor: float) -> void:
	var should_brake = (acc == -1 and isBackwards == false and current_speed > FIVEFLOAT)
	
	if should_brake:
		brake = braking 
	else:
		if brake != 0:
			brake = 0
		engine_force = acc * acceleration * speed_factor

func _handle_stopped_state() -> void:
	if brake_car:
		engine_force = 0
		brake = braking
		current_speed = linear_velocity.length() * METERSPORSEC
		handleSound()

func _physics_process(delta: float) -> void:
	handleCam(delta)
	#handleParticles()

func handleSound() -> void:
	var newVal = (current_speed / (SOUNDFACTOR * METERSPORSEC)) + HALF
	sound.set_pitch_scale(newVal)

func _calculate_steering_responsiveness() -> float:
	# Calculate how fast steering should respond based on current speed
	# At low speeds: fast response (MAX_STEERING_RESPONSIVENESS)
	# At high speeds: slower response (MIN_STEERING_RESPONSIVENESS)
	
	var speed_ratio: float = current_speed / STEERING_SPEED_THRESHOLD
	speed_ratio = clamp(speed_ratio, 0.0, 1.0)
	
	# Use a power curve for smoother transition
	var reduction_factor: float = pow(speed_ratio, STEERING_SMOOTHNESS)
	
	# Interpolate between max and min responsiveness
	return lerp(MAX_STEERING_RESPONSIVENESS, MIN_STEERING_RESPONSIVENESS, reduction_factor)

func stop_car() -> void:
	brake_car = true

#func handleParticles():
	#var left = backWhellL.get_skidinfo()
	#var right = backWhellL.get_skidinfo()
	#if right != 1.0 or left != 1.0:
		#print("-----")
		#print("L ",left)
		#print("R ",right)
		#print("-----")
