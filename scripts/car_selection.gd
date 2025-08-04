extends Node3D

@onready var car_spawn_point: Marker3D = $Marker3D
@onready var carName: Label = $UI/CarStats/VBoxContainer/Name
@onready var carVeloc: Label = $UI/CarStats/VBoxContainer/Velocity
@onready var carAcc: Label = $UI/CarStats/VBoxContainer/Acc

var index: int = 0
var currentCar: VehicleBody3D

func _ready() -> void:
	await get_tree().create_timer(0.25).timeout
	call_deferred("spawn_selected_car")

func _on_next_pressed() -> void:
	#NOTE: This name is inverted
	change_selection(false)

func _on_prev_pressed() -> void:
	#NOTE: This name is inverted
	change_selection(true)

func _on_ok_pressed() -> void:
	get_tree().change_scene_to_file("res://Tests/test_scene.tscn")

func spawn_selected_car():
	CarManager.select_car(index)
	# Get car instance from the car manager
	var car_instance = CarManager.instantiate_car()
	if car_instance:
		# Set the car's position and rotation to match the spawn point
		car_instance.global_transform = car_spawn_point.global_transform
		
		# Add the car to the scene
		add_child(car_instance)
		currentCar = car_instance
		currentCar.sound.stop()
		updateStats()

func change_selection(sum: bool):
	var my_size = CarManager.available_cars.size()
	if sum:
		index += 1
		if index == my_size:
			index = 0
	else:
		if index == 0:
			index = my_size - 1
		else:
			index -= 1
	currentCar.queue_free()
	spawn_selected_car()
	updateStats()

func updateStats():
	var carData: CarData = CarManager.selected_car_data
	carName.text = "Car: " + str(carData.car_name)
	carVeloc.text = "Max Velocity: " + str(round(carData.max_speed / 6.5)) + " km/h"
	carAcc.text = "Acceleration: " + str(carData.acceleration)
