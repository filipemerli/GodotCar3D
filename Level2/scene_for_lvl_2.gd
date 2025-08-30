extends Node3D

var myCar: VehicleBody3D

@onready var velocityLabel: Label = $Control/Vel
@onready var car_spawn_point = $SpawnPoint

func _ready() -> void:
	GameManager.isPlaying = true
#	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	spawn_selected_car()
	

func spawn_selected_car():
	# Get car instance from the car manager
	var car_instance = CarManager.instantiate_car()
	if car_instance:
		# Set the car's position and rotation to match the spawn point
		car_instance.global_transform = car_spawn_point.global_transform
		
		# Add the car to the scene
		add_child(car_instance)
		myCar = car_instance
