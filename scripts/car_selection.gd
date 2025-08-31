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
	
	# Preload test scene and related resources for faster loading
	_preload_race_resources()

func _on_next_pressed() -> void:
	#NOTE: This name is inverted
	change_selection(false)

func _on_prev_pressed() -> void:
	#NOTE: This name is inverted
	change_selection(true)

func _on_ok_pressed() -> void:
	# Get LoadingManager dynamically to avoid autoload recognition issues
	var loading_manager = get_node_or_null("/root/LoadingManager")
	if loading_manager:
		# Use LoadingManager for smooth scene transition with loading screen
		loading_manager.change_scene_async("res://Tests/test_scene.tscn", true)
		#loading_manager.change_scene_async("res://Level2/scene_for_lvl_2.tscn", true)
	else:
		# Fallback to direct scene change if LoadingManager not available
		print("LoadingManager not available, using direct scene change")
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

func _preload_race_resources():
	"""Preload resources for faster race loading"""
	# Get LoadingManager (will be available after autoload)
	var loading_manager = get_node_or_null("/root/LoadingManager")
	if not loading_manager:
		print("LoadingManager not available yet, skipping preload")
		return
	
	# Resources to preload for racing
	var race_resources: Array[String] = [
		"res://Tests/test_scene.tscn",
		"res://Level2/scene_for_lvl_2.tscn",
		"res://Shared/UI/end_race_menu.tscn",
		"res://scenes/mobile_control.tscn",
		"res://MyAssets/sounds/check.wav"
	]
	
	# Filter to only existing resources
	var existing_resources: Array[String] = []
	for resource_path in race_resources:
		if ResourceLoader.exists(resource_path):
			existing_resources.append(resource_path)
	
	if existing_resources.size() > 0:
		print("Preloading ", existing_resources.size(), " race resources for smoother transitions")
		loading_manager.preload_resources(existing_resources, 1)  # Conservative loading for selection screen
	else:
		print("No race resources found to preload")
