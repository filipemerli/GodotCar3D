extends Node3D

var myCar: VehicleBody3D
@onready var velocityLabel: Label = $Control/Vel
@onready var car_spawn_point = $SpawnPoint
var check_points: Array[Node3D]
var checks_count = 0

func _ready() -> void:
	GameManager.isPlaying = true
#	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	spawn_selected_car()
	var checks = get_tree().get_nodes_in_group("checkpoint")
	for check in checks:
		if check is Node3D:
			check_points.append(check)
			check.connect("did_check", Callable(self, "check_pointed"))
	checks_count = check_points.size()

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

func check_pointed():
	$checkPoint.play()
	checks_count -= 1
	if checks_count == 0:
		end_game()

func end_game():
	GameManager.isPlaying = false
	$Control.emit_signal("end_timer")
	myCar.stop_car()
