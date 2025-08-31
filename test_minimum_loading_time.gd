extends Node

## Simple test script to verify minimum loading time functionality
## Run this from a scene to test the LoadingManager minimum loading time

func _ready():
	print("Testing LoadingManager minimum loading time...")
	
	# Test 1: Load a scene that should complete quickly (preloaded)
	print("\n=== Test 1: Quick loading with minimum time ===")
	
	# Get LoadingManager
	var loading_manager = get_node("/root/LoadingManager")
	if loading_manager:
		print("Minimum loading time set to: ", loading_manager.minimum_loading_time, " seconds")
		
		# First preload the scene
		loading_manager.load_resource_async("res://Tests/test_scene.tscn", "PackedScene")
		
		# Wait a bit for preload to complete
		await get_tree().create_timer(0.5).timeout
		
		# Now test scene transition with minimum time
		var transition_start = Time.get_ticks_msec()
		loading_manager.change_scene_async("res://Tests/test_scene.tscn", true)
		
		print("Transition started at: ", transition_start)
		print("Expected minimum duration: ", loading_manager.minimum_loading_time, " seconds")
	else:
		print("LoadingManager not found!")

func _input(event):
	if event.is_action_pressed("ui_accept"):
		_ready()  # Run test again
