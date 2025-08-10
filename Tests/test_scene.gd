extends Node3D

var myCar: VehicleBody3D
@onready var velocityLabel: Label = $Control/Vel
@onready var car_spawn_point = $SpawnPoint
@onready var checkpoint_manager: Node = $CheckpointManager

func _ready() -> void:
	GameManager.isPlaying = true
#	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	spawn_selected_car()
	_setup_checkpoint_manager()

func _setup_checkpoint_manager() -> void:
	# Connect to checkpoint manager signals
	if checkpoint_manager:
		checkpoint_manager.connect("checkpoint_reached", _on_checkpoint_reached)
		checkpoint_manager.connect("lap_completed", _on_lap_completed)
		checkpoint_manager.connect("all_checkpoints_completed", _on_all_checkpoints_completed)

func _process(_delta: float) -> void:
	updateVelocityLabel()

func updateVelocityLabel():
	if myCar:
		var vel = round((myCar.linear_velocity.length() * 3.6) / 2)
		velocityLabel.text = str(int(vel)) + " km/h"

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
	end_game()

func check_pointed():
	# This function is now handled by the CheckpointManager
	# Keeping it for compatibility but it won't be called
	pass

func end_game():
	GameManager.isPlaying = false
	$Control.emit_signal("end_timer")
	myCar.stop_car()
