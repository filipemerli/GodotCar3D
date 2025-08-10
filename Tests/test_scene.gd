extends Node3D

var myCar: VehicleBody3D
@onready var velocityLabel: Label = $Control/Vel
@onready var car_spawn_point = $SpawnPoint
@onready var checkpoint_manager: Node = $CheckpointManager
@onready var track_timer: Node = $TrackTimer
@onready var timer_label: Label = $Control/TimerLabel

func _ready() -> void:
	print("TestScene: Starting _ready()")
	GameManager.isPlaying = true
#	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Debug node references
	print("TestScene: Checking node references...")
	print("  checkpoint_manager: ", checkpoint_manager)
	print("  track_timer: ", track_timer)
	print("  timer_label: ", timer_label)
	print("  velocityLabel: ", velocityLabel)
	
	spawn_selected_car()
	_setup_checkpoint_manager()
	_setup_track_timer()
	print("TestScene: _ready() completed")

func _setup_checkpoint_manager() -> void:
	# Connect to checkpoint manager signals
	if checkpoint_manager:
		checkpoint_manager.connect("checkpoint_reached", _on_checkpoint_reached)
		checkpoint_manager.connect("lap_completed", _on_lap_completed)
		checkpoint_manager.connect("all_checkpoints_completed", _on_all_checkpoints_completed)

func _setup_track_timer() -> void:
	# Connect to track timer signals
	if track_timer:
		track_timer.connect("time_warning_triggered", _on_time_warning)
		track_timer.connect("time_expired", _on_time_expired)
		track_timer.connect("race_completed", _on_race_completed)
		
		# Don't auto-start the timer - let the Control semaphore handle it
		print("TestScene: TrackTimer configured, waiting for semaphore start")
	else:
		print("Warning: TrackTimer node not found - timer functionality disabled")

func _process(_delta: float) -> void:
	updateVelocityLabel()
	updateTimerLabel()

func updateVelocityLabel():
	if myCar:
		var vel = round((myCar.linear_velocity.length() * 3.6) / 2)
		velocityLabel.text = str(int(vel)) + " km/h"

func updateTimerLabel():
	if track_timer and timer_label:
		var remaining_time = track_timer.get_formatted_remaining_time()
		var color = Color.WHITE
		
		# Change color when time is running low
		if track_timer.get_remaining_time() <= 3.0:
			color = Color.RED  # Last 3 seconds - critical
		elif track_timer.get_remaining_time() <= 10.0:
			color = Color.YELLOW  # Last 10 seconds - warning
		
		timer_label.text = "Time: " + remaining_time
		timer_label.modulate = color
	elif not timer_label:
		print("Warning: TimerLabel not found in scene")
	elif not track_timer:
		print("Warning: TrackTimer not found in scene")

func spawn_selected_car():
	# Get car instance from the car manager
	var car_instance = CarManager.instantiate_car()
	if car_instance:
		# Set the car's position and rotation to match the spawn point
		car_instance.global_transform = car_spawn_point.global_transform
		
		# Add the car to the scene
		add_child(car_instance)
		myCar = car_instance

# Checkpoint Manager Signal Handlers
func _on_checkpoint_reached(checkpoint_index: int) -> void:
	print("Checkpoint ", checkpoint_index, " reached!")
	$checkPoint.play()
	
	# You can add more feedback here (UI updates, effects, etc.)

func _on_lap_completed() -> void:
	print("Lap completed! Starting another lap...")
	# You can add lap completion logic here

func _on_all_checkpoints_completed() -> void:
	print("All checkpoints completed!")
	# Complete the race successfully
	if track_timer:
		track_timer.complete_race()

# Timer Signal Handlers
func _on_time_warning(remaining_time: float) -> void:
	print("Time Warning! ", remaining_time, " seconds remaining!")
	# You can add warning effects here (screen flash, sound, etc.)

func _on_time_expired() -> void:
	print("TIME'S UP! Race failed!")
	end_game()

func _on_race_completed(final_time: float, passed: bool) -> void:
	if passed:
		print("Race completed successfully! Time: ", final_time, " seconds")
	else:
		print("Race failed! Time: ", final_time, " seconds")
	
	end_game()

func check_pointed():
	# This function is now handled by the CheckpointManager
	# Keeping it for compatibility but it won't be called
	pass

func end_game():
	GameManager.isPlaying = false
	$Control.emit_signal("end_timer")
	myCar.stop_car()
