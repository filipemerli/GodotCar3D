extends Node

## LoadingManager - Mobile-optimized async resource loading for Godot 4.4
## Provides non-blocking scene transitions with progress feedback

signal loading_started(resource_path: String)
signal loading_progress_changed(progress: float, resource_path: String)
signal loading_completed(resource: Resource, resource_path: String)
signal loading_failed(error_code: Error, resource_path: String)

enum LoadingState {
	IDLE,
	LOADING,
	COMPLETED,
	FAILED
}

class LoadingJob:
	var resource_path: String
	var type_hint: String = ""
	var use_sub_threads: bool = false
	var cache_mode: ResourceLoader.CacheMode = ResourceLoader.CACHE_MODE_REUSE
	var state: LoadingState = LoadingState.IDLE
	var progress: float = 0.0
	var loaded_resource: Resource = null
	var error_code: Error = OK
	
	func _init(path: String, hint: String = "", sub_threads: bool = false, cache: ResourceLoader.CacheMode = ResourceLoader.CACHE_MODE_REUSE):
		resource_path = path
		type_hint = hint
		use_sub_threads = sub_threads
		cache_mode = cache

var current_jobs: Dictionary = {}  # String -> LoadingJob
var loading_queue: Array[LoadingJob] = []
var max_concurrent_loads: int = 2  # Mobile-friendly concurrent loading limit

# Minimum time to show loading screen (prevents flashing)
@export var minimum_loading_time: float = 2.0

# Scene transition management
var current_scene_path: String = ""
var target_scene_path: String = ""
var is_transitioning: bool = false

# Performance monitoring
var frame_time_limit_ms: float = 16.67  # Target 60fps - spend max 16.67ms per frame on loading
var loading_start_time: int = 0

func _ready():
	# Configure for mobile performance
	set_process(true)
	set_physics_process(false)
	
	# Monitor current scene
	var scene_tree = get_tree()
	if scene_tree.current_scene:
		current_scene_path = scene_tree.current_scene.scene_file_path

func _process(_delta):
	_update_loading_jobs()
	_process_loading_queue()

## Start loading a resource asynchronously
func load_resource_async(resource_path: String, type_hint: String = "", use_sub_threads: bool = false) -> LoadingJob:
	# Check if already loading or loaded
	if current_jobs.has(resource_path):
		var existing_job = current_jobs[resource_path]
		if existing_job.state == LoadingState.COMPLETED:
			# Already loaded, return immediately
			loading_completed.emit(existing_job.loaded_resource, resource_path)
		return existing_job
	
	# Check cache first for mobile optimization
	if ResourceLoader.has_cached(resource_path):
		var cached_resource = ResourceLoader.get_cached_ref(resource_path)
		if cached_resource and is_instance_valid(cached_resource):
			var cached_job = LoadingJob.new(resource_path, type_hint, use_sub_threads)
			cached_job.state = LoadingState.COMPLETED
			cached_job.loaded_resource = cached_resource
			cached_job.progress = 1.0
			loading_completed.emit(cached_resource, resource_path)
			return cached_job
	
	# Create new loading job
	var job = LoadingJob.new(resource_path, type_hint, use_sub_threads)
	current_jobs[resource_path] = job
	loading_queue.append(job)
	
	print("LoadingManager: Queued resource for loading: ", resource_path)
	return job

## Load scene with transition (mobile-optimized)
func change_scene_async(scene_path: String, show_loading_screen: bool = true) -> void:
	if is_transitioning:
		print("LoadingManager: Scene transition already in progress")
		return
	
	if not ResourceLoader.exists(scene_path):
		print("LoadingManager: Scene file does not exist: ", scene_path)
		loading_failed.emit(ERR_FILE_NOT_FOUND, scene_path)
		return
	
	is_transitioning = true
	target_scene_path = scene_path
	
	# Connect to completion BEFORE starting loading
	if not loading_completed.is_connected(_on_scene_loading_completed):
		loading_completed.connect(_on_scene_loading_completed)
	
	# Check if scene is already loaded
	if current_jobs.has(scene_path):
		var existing_job = current_jobs[scene_path]
		if existing_job.state == LoadingState.COMPLETED:
			print("LoadingManager: Scene already preloaded, showing loading screen for minimum time")
			
			# Show loading screen even for preloaded content to respect minimum time
			if show_loading_screen:
				_show_loading_screen()
			
			# Call completion handler directly
			_on_scene_loading_completed(existing_job.loaded_resource, scene_path)
			return
	
	# Show loading screen if requested
	if show_loading_screen:
		_show_loading_screen()
	
	# Start loading the scene
	var _job = load_resource_async(scene_path, "PackedScene", true)  # Use sub-threads for scenes
	
	print("LoadingManager: Started scene transition to: ", scene_path)

## Preload multiple resources (useful for game initialization)
func preload_resources(resource_paths: Array[String], batch_size: int = 3) -> void:
	print("LoadingManager: Preloading ", resource_paths.size(), " resources in batches of ", batch_size)
	
	# Limit concurrent loads for mobile performance
	max_concurrent_loads = mini(batch_size, 3)
	
	for path in resource_paths:
		load_resource_async(path)

## Check if a resource is currently loading
func is_loading(resource_path: String) -> bool:
	return current_jobs.has(resource_path) and current_jobs[resource_path].state == LoadingState.LOADING

## Get loading progress for a specific resource
func get_loading_progress(resource_path: String) -> float:
	if current_jobs.has(resource_path):
		return current_jobs[resource_path].progress
	return 0.0

## Get overall loading progress (all active jobs)
func get_overall_progress() -> float:
	if current_jobs.is_empty():
		return 1.0
	
	var total_progress = 0.0
	var job_count = 0
	
	for job in current_jobs.values():
		if job.state == LoadingState.LOADING or job.state == LoadingState.COMPLETED:
			total_progress += job.progress
			job_count += 1
	
	return total_progress / max(job_count, 1)

## Cancel loading of a specific resource
func cancel_loading(resource_path: String) -> bool:
	if not current_jobs.has(resource_path):
		return false
	
	var job = current_jobs[resource_path]
	if job.state == LoadingState.LOADING:
		# Note: Godot doesn't provide a direct way to cancel ResourceLoader.load_threaded_request
		# But we can mark it as cancelled and ignore the result
		job.state = LoadingState.FAILED
		job.error_code = ERR_FILE_CANT_READ
		current_jobs.erase(resource_path)
		
		# Remove from queue if not started yet
		var queue_index = loading_queue.find(job)
		if queue_index != -1:
			loading_queue.remove_at(queue_index)
		
		loading_failed.emit(ERR_FILE_CANT_READ, resource_path)
		return true
	
	return false

## Clear all completed jobs (memory management)
func cleanup_completed_jobs() -> void:
	var to_remove: Array[String] = []
	
	for path in current_jobs.keys():
		var job = current_jobs[path]
		if job.state == LoadingState.COMPLETED or job.state == LoadingState.FAILED:
			to_remove.append(path)
	
	for path in to_remove:
		current_jobs.erase(path)
	
	print("LoadingManager: Cleaned up ", to_remove.size(), " completed jobs")

## Get memory usage info for loaded resources
func get_loading_stats() -> Dictionary:
	var stats = {
		"active_jobs": current_jobs.size(),
		"queued_jobs": loading_queue.size(),
		"completed_jobs": 0,
		"loading_jobs": 0,
		"failed_jobs": 0,
		"cached_resources": 0
	}
	
	for job in current_jobs.values():
		match job.state:
			LoadingState.COMPLETED:
				stats.completed_jobs += 1
			LoadingState.LOADING:
				stats.loading_jobs += 1
			LoadingState.FAILED:
				stats.failed_jobs += 1
	
	return stats

# Private methods

func _update_loading_jobs():
	var start_time = Time.get_ticks_msec()
	
	for resource_path in current_jobs.keys():
		var job = current_jobs[resource_path]
		
		if job.state == LoadingState.LOADING:
			var progress_array: Array = []
			var status = ResourceLoader.load_threaded_get_status(resource_path, progress_array)
			
			# Update progress
			if progress_array.size() > 0:
				job.progress = progress_array[0]
				loading_progress_changed.emit(job.progress, resource_path)
			
			# Check completion status
			match status:
				ResourceLoader.THREAD_LOAD_LOADED:
					var loaded_resource = ResourceLoader.load_threaded_get(resource_path)
					if loaded_resource:
						job.state = LoadingState.COMPLETED
						job.loaded_resource = loaded_resource
						job.progress = 1.0
						loading_completed.emit(loaded_resource, resource_path)
						print("LoadingManager: Successfully loaded: ", resource_path)
					else:
						job.state = LoadingState.FAILED
						job.error_code = ERR_FILE_CANT_READ
						loading_failed.emit(job.error_code, resource_path)
						print("LoadingManager: Failed to get loaded resource: ", resource_path)
				
				ResourceLoader.THREAD_LOAD_FAILED:
					job.state = LoadingState.FAILED
					job.error_code = ERR_FILE_CANT_READ
					loading_failed.emit(job.error_code, resource_path)
					print("LoadingManager: Loading failed: ", resource_path)
				
				ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
					job.state = LoadingState.FAILED
					job.error_code = ERR_FILE_CORRUPT
					loading_failed.emit(job.error_code, resource_path)
					print("LoadingManager: Invalid resource: ", resource_path)
		
		# Mobile performance: limit time spent per frame
		if Time.get_ticks_msec() - start_time > frame_time_limit_ms * 0.5:  # Use 50% of frame time for loading updates
			break

func _process_loading_queue():
	if loading_queue.is_empty():
		return
	
	# Count currently active loading jobs
	var active_loads = 0
	for job in current_jobs.values():
		if job.state == LoadingState.LOADING:
			active_loads += 1
	
	# Start new loading jobs if under the limit
	while active_loads < max_concurrent_loads and not loading_queue.is_empty():
		var job = loading_queue.pop_front()
		
		# Start threaded loading
		var error = ResourceLoader.load_threaded_request(
			job.resource_path, 
			job.type_hint, 
			job.use_sub_threads, 
			job.cache_mode
		)
		
		if error == OK:
			job.state = LoadingState.LOADING
			loading_started.emit(job.resource_path)
			active_loads += 1
			print("LoadingManager: Started loading: ", job.resource_path)
		else:
			job.state = LoadingState.FAILED
			job.error_code = error
			loading_failed.emit(error, job.resource_path)
			print("LoadingManager: Failed to start loading: ", job.resource_path, " Error: ", error)

func _show_loading_screen():
	# Try to instantiate loading screen UI
	var loading_screen_path = "res://scenes/UI/loading_screen.tscn"
	if not ResourceLoader.exists(loading_screen_path):
		print("LoadingManager: Loading screen scene not found, using simple print feedback")
		return
	
	var loading_scene = load(loading_screen_path)
	if not loading_scene:
		print("LoadingManager: Could not load loading screen scene")
		return
	
	var loading_screen = loading_scene.instantiate()
	if not loading_screen:
		print("LoadingManager: Could not instantiate loading screen")
		return
	
	loading_screen.name = "LoadingScreen"
	
	# Create a CanvasLayer to ensure loading screen appears above all UI
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100  # High layer value to appear above everything
	canvas_layer.name = "LoadingScreenLayer"
	
	# Add CanvasLayer to root, then loading screen to the layer
	get_tree().root.add_child(canvas_layer)
	canvas_layer.add_child(loading_screen)
	
	# Call show method if it exists
	if loading_screen.has_method("show_loading_screen"):
		loading_screen.show_loading_screen()
	else:
		loading_screen.show()
	
	print("LoadingManager: Showing loading screen UI")

func _hide_loading_screen():
	# Find and remove loading screen CanvasLayer
	var loading_layer = get_tree().root.get_node_or_null("LoadingScreenLayer")
	if loading_layer:
		var loading_screen = loading_layer.get_node_or_null("LoadingScreen")
		if loading_screen:
			# Call hide method if it exists
			if loading_screen.has_method("hide_loading_screen"):
				loading_screen.hide_loading_screen()
				# Wait for fade out
				await get_tree().create_timer(0.5).timeout
			else:
				loading_screen.hide()
		
		# Clean up the entire CanvasLayer
		if is_instance_valid(loading_layer):
			loading_layer.queue_free()
	
	print("LoadingManager: Hiding loading screen UI")

func _on_scene_loading_completed(resource: Resource, resource_path: String):
	if not is_transitioning or resource_path != target_scene_path:
		return
	
	if resource is PackedScene:
		print("LoadingManager: Scene loaded successfully, enforcing minimum loading time...")
		
		# Ensure progress bar shows 100% completion
		loading_progress_changed.emit(1.0, resource_path)
		
		# Always wait for the minimum loading time to ensure smooth UX
		print("LoadingManager: Waiting %.2f seconds for minimum loading time" % minimum_loading_time)
		await get_tree().create_timer(minimum_loading_time).timeout
		
		print("LoadingManager: Changing scene to: ", resource_path)
		
		# Hide loading screen before scene change (don't await here)
		_hide_loading_screen()
		
		# Small delay to let loading screen fade out
		await get_tree().create_timer(0.1).timeout
		
		# Change to the new scene
		var error = get_tree().change_scene_to_packed(resource)
		if error != OK:
			print("LoadingManager: Failed to change scene: ", error)
			loading_failed.emit(error, resource_path)
		else:
			current_scene_path = resource_path
		
		# Reset transition state
		is_transitioning = false
		target_scene_path = ""
		
		# Disconnect to avoid memory leaks
		if loading_completed.is_connected(_on_scene_loading_completed):
			loading_completed.disconnect(_on_scene_loading_completed)
	else:
		print("LoadingManager: Loaded resource is not a PackedScene: ", resource_path)
		loading_failed.emit(ERR_INVALID_DATA, resource_path)
		is_transitioning = false

# Debug and utility methods

func print_loading_status():
	print("=== LoadingManager Status ===")
	print("Current scene: ", current_scene_path)
	print("Is transitioning: ", is_transitioning)
	print("Target scene: ", target_scene_path)
	print("Active jobs: ", current_jobs.size())
	print("Queued jobs: ", loading_queue.size())
	
	for path in current_jobs.keys():
		var job = current_jobs[path]
		print("  ", path, " - State: ", LoadingState.keys()[job.state], " - Progress: ", job.progress)

## Reset transition state (debug/emergency use)
func reset_transition_state():
	is_transitioning = false
	target_scene_path = ""
	if loading_completed.is_connected(_on_scene_loading_completed):
		loading_completed.disconnect(_on_scene_loading_completed)
	print("LoadingManager: Transition state reset")

## Preload common game resources for better performance
func preload_common_resources():
	var common_resources: Array[String] = [
		# Car models that might be loaded frequently
		"res://MyCars/Delorian/delorian.tscn",
		# UI elements that exist
		"res://Shared/UI/end_race_menu.tscn",
		# Audio that might be used across scenes
		"res://MyAssets/sounds/check.wav",
		# Common materials or meshes
		"res://MyMeshes/road_array_mesh.tres"
	]
	
	# Filter to only existing resources
	var existing_resources: Array[String] = []
	for resource_path in common_resources:
		if ResourceLoader.exists(resource_path):
			existing_resources.append(resource_path)
	
	if existing_resources.size() > 0:
		print("LoadingManager: Preloading ", existing_resources.size(), " common resources...")
		preload_resources(existing_resources, 2)  # Mobile-friendly batch size
	else:
		print("LoadingManager: No common resources found to preload")
