extends Node

## LoadingManager Usage Example
## Demonstrates how to integrate LoadingManager with your game

var loading_manager: Node

func _ready():
	# Get LoadingManager singleton (will be available after autoload registration)
	loading_manager = get_node_or_null("/root/LoadingManager")
	if not loading_manager:
		print("LoadingManager not found! Make sure it's added as autoload.")
		return
	
	# Example: Preload common resources when the game starts
	_preload_game_resources()
	
	# Connect to loading manager signals for debugging
	loading_manager.loading_started.connect(_on_loading_started)
	loading_manager.loading_completed.connect(_on_loading_completed)
	loading_manager.loading_failed.connect(_on_loading_failed)
	
	# Example input handling
	print("LoadingManager Example - Press keys to test:")
	print("1 - Load test scene")
	print("2 - Preload car models") 
	print("3 - Show loading stats")
	print("4 - Clean up completed jobs")

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_test_scene_loading()
			KEY_2:
				_test_car_preloading()
			KEY_3:
				_show_loading_stats()
			KEY_4:
				loading_manager.cleanup_completed_jobs()

## Example: Loading a scene with loading screen
func _test_scene_loading():
	print("=== Testing Scene Loading ===")
	
	# Change to a different scene with loading screen
	var target_scenes: Array[String] = [
		"res://scenes/car_selection.tscn",
		"res://Tests/test_scene.tscn",
		"res://Level2/level_2.tscn"
	]
	
	# Pick a random scene to load
	var scene_path = target_scenes[randi() % target_scenes.size()]
	print("Loading scene: ", scene_path)
	
	loading_manager.change_scene_async(scene_path, true)

## Example: Preloading multiple resources
func _test_car_preloading():
	print("=== Testing Car Preloading ===")
	
	var car_resources: Array[String] = [
		"res://MyCars/Delorian/delorian.tscn",
		"res://MyCars/Challenger/challenger.tscn",
		"res://MyCars/NissanGTR/nissan_gtr.tscn",
		"res://MyCars/Skyline/skyline.tscn"
	]
	
	# Filter to only existing files
	var existing_cars: Array[String] = []
	for car_path in car_resources:
		if ResourceLoader.exists(car_path):
			existing_cars.append(car_path)
	
	if existing_cars.is_empty():
		print("No car models found to preload")
		return
	
	print("Preloading ", existing_cars.size(), " car models...")
	loading_manager.preload_resources(existing_cars, 2)

## Example: Game initialization with loading screen
func _preload_game_resources():
	print("=== Preloading Game Resources ===")
	
	# Essential resources to preload at startup
	var essential_resources: Array[String] = []
	
	# Check and add existing UI resources
	var ui_resources: Array[String] = [
		"res://Shared/UI/end_race_menu.tscn",
		"res://scenes/UIControlNode/ui_control_node.tscn"
	]
	
	for resource_path in ui_resources:
		if ResourceLoader.exists(resource_path):
			essential_resources.append(resource_path)
	
	# Check and add existing audio resources
	var audio_resources: Array[String] = [
		"res://MyAssets/sounds/check.wav",
		"res://Shared/engine_sound.tscn"
	]
	
	for resource_path in audio_resources:
		if ResourceLoader.exists(resource_path):
			essential_resources.append(resource_path)
	
	# Check and add existing mesh resources
	var mesh_resources: Array[String] = [
		"res://MyMeshes/road_array_mesh.tres"
	]
	
	for resource_path in mesh_resources:
		if ResourceLoader.exists(resource_path):
			essential_resources.append(resource_path)
	
	if not essential_resources.is_empty():
		print("Preloading ", essential_resources.size(), " essential resources...")
		loading_manager.preload_resources(essential_resources, 1)  # Conservative loading for startup
	else:
		print("No essential resources found to preload")

## Example: Loading individual resources
func load_car_model(car_name: String):
	var car_path = "res://MyCars/" + car_name + "/" + car_name.to_lower() + ".tscn"
	
	if not ResourceLoader.exists(car_path):
		print("Car model not found: ", car_path)
		return null
	
	print("Loading car model: ", car_name)
	return loading_manager.load_resource_async(car_path, "PackedScene", true)

## Example: Waiting for resource to complete loading
func wait_for_resource(resource_path: String) -> Resource:
	if not loading_manager.is_loading(resource_path):
		# Start loading if not already started
		loading_manager.load_resource_async(resource_path)
	
	# Wait for completion
	while loading_manager.is_loading(resource_path):
		await get_tree().process_frame
	
	# Check if it's in completed jobs
	if loading_manager.current_jobs.has(resource_path):
		var job = loading_manager.current_jobs[resource_path]
		# Use numeric enum values instead of class reference
		if job.state == 2:  # LoadingState.COMPLETED
			return job.loaded_resource
	
	print("Failed to load resource: ", resource_path)
	return null

## Debug: Show current loading statistics
func _show_loading_stats():
	print("=== Loading Manager Statistics ===")
	var stats = loading_manager.get_loading_stats()
	
	for key in stats.keys():
		print(key, ": ", stats[key])
	
	print("Overall progress: ", int(loading_manager.get_overall_progress() * 100), "%")
	
	# Show detailed job status
	loading_manager.print_loading_status()

## Example signal handlers

func _on_loading_started(resource_path: String):
	print("Loading started: ", resource_path.get_file())

func _on_loading_completed(_resource: Resource, resource_path: String):
	print("Loading completed: ", resource_path.get_file())

func _on_loading_failed(_error_code: Error, resource_path: String):
	print("Loading failed: ", resource_path.get_file())
