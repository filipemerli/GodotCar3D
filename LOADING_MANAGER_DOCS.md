# LoadingManager Documentation

## Overview

The LoadingManager is a comprehensive, mobile-optimized async resource loading system for Godot 4.4. It provides non-blocking scene transitions, progress feedback, and efficient memory management for racing games and other resource-intensive applications.

## Features

- **Async Loading**: Uses Godot 4.4's `ResourceLoader.load_threaded_request()` for non-blocking resource loading
- **Mobile Optimized**: Limits concurrent loads and frame time usage to maintain 60fps on mobile devices
- **Progress Tracking**: Real-time loading progress with visual feedback
- **Scene Transitions**: Smooth scene changes with loading screens
- **Memory Management**: Automatic cleanup and cache optimization
- **Queue System**: Intelligent loading queue with priority handling
- **Error Handling**: Comprehensive error reporting and recovery

## Installation

1. Add the LoadingManager script to your project:
   ```
   res://scripts/loading_manager.gd
   ```

2. Add LoadingManager as an autoload in Project Settings:
   ```
   LoadingManager="*res://scripts/loading_manager.gd"
   ```

3. Optionally add the loading screen UI:
   ```
   res://scenes/UI/loading_screen.tscn
   res://scripts/loading_screen.gd
   ```

## Basic Usage

### Loading Resources Asynchronously

```gdscript
# Load a single resource
var job = LoadingManager.load_resource_async("res://MyCars/delorian.tscn", "PackedScene")

# Check if resource is loading
if LoadingManager.is_loading("res://MyCars/delorian.tscn"):
    print("Still loading...")

# Get loading progress (0.0 to 1.0)
var progress = LoadingManager.get_loading_progress("res://MyCars/delorian.tscn")
```

### Scene Transitions with Loading Screen

```gdscript
# Change scene with automatic loading screen
LoadingManager.change_scene_async("res://Level2/level_2.tscn", true)

# Change scene without loading screen
LoadingManager.change_scene_async("res://scenes/car_selection.tscn", false)
```

### Preloading Multiple Resources

```gdscript
var resources_to_preload = [
    "res://MyCars/delorian.tscn",
    "res://MyCars/challenger.tscn",
    "res://MyAssets/sounds/engine_sound.ogg"
]

# Preload with mobile-friendly batch size
LoadingManager.preload_resources(resources_to_preload, 2)
```

## Advanced Usage

### Waiting for Resource Completion

```gdscript
func load_and_use_resource():
    # Start loading
    LoadingManager.load_resource_async("res://MyCars/delorian.tscn")
    
    # Wait for completion
    while LoadingManager.is_loading("res://MyCars/delorian.tscn"):
        await get_tree().process_frame
    
    # Use the loaded resource
    var job = LoadingManager.current_jobs["res://MyCars/delorian.tscn"]
    if job.state == 2:  # COMPLETED
        var car_scene = job.loaded_resource
        var car_instance = car_scene.instantiate()
        # Use the car instance
```

### Progress Monitoring

```gdscript
func monitor_loading_progress():
    LoadingManager.loading_progress_changed.connect(_on_progress_changed)
    LoadingManager.loading_completed.connect(_on_loading_completed)
    
    # Start loading
    LoadingManager.preload_resources(["res://large_level.tscn"])

func _on_progress_changed(progress: float, resource_path: String):
    print("Loading ", resource_path.get_file(), ": ", int(progress * 100), "%")

func _on_loading_completed(resource: Resource, resource_path: String):
    print("Finished loading: ", resource_path.get_file())
```

### Integration with Existing Systems

```gdscript
# Integration with CarManager
func load_and_spawn_car(car_name: String):
    var car_path = "res://MyCars/" + car_name + "/" + car_name.to_lower() + ".tscn"
    
    # Load asynchronously
    var job = LoadingManager.load_resource_async(car_path, "PackedScene", true)
    
    # Wait for loading
    await LoadingManager.loading_completed
    
    # Spawn using existing CarManager
    if job.state == 2:  # COMPLETED
        CarManager.instantiate_car(job.loaded_resource)
```

## Signals

The LoadingManager emits the following signals:

- `loading_started(resource_path: String)` - When a resource starts loading
- `loading_progress_changed(progress: float, resource_path: String)` - Progress updates
- `loading_completed(resource: Resource, resource_path: String)` - When loading completes
- `loading_failed(error_code: Error, resource_path: String)` - When loading fails

## Configuration

### Mobile Performance Settings

```gdscript
# Adjust concurrent loading limit (default: 2 for mobile)
LoadingManager.max_concurrent_loads = 3  # Higher for desktop

# Adjust frame time limit (default: 16.67ms for 60fps)
LoadingManager.frame_time_limit_ms = 8.33  # For 120fps targets
```

### Cache Management

```gdscript
# Clean up completed jobs to free memory
LoadingManager.cleanup_completed_jobs()

# Check loading statistics
var stats = LoadingManager.get_loading_stats()
print("Active jobs: ", stats.active_jobs)
print("Completed jobs: ", stats.completed_jobs)
```

## Loading Screen UI

The included loading screen provides:

- Animated progress bar
- Status messages
- Spinning indicator
- Fade in/out transitions
- Automatic integration with LoadingManager

### Custom Loading Screen

```gdscript
# Show custom loading message
var loading_screen = preload("res://scenes/UI/loading_screen.tscn").instantiate()
get_tree().root.add_child(loading_screen)
loading_screen.show_with_message("Loading race level...")

# Update progress manually
loading_screen.update_progress(0.5, "Loading textures...")
```

## Performance Considerations

### Mobile Optimization

- Default concurrent loading limit: 2
- Frame time budget: 8.33ms (50% of 16.67ms target)
- Uses sub-threads for large resources like scenes
- Cache-first loading to avoid redundant operations

### Memory Management

- Automatic cleanup of completed jobs
- Cache awareness to reuse loaded resources
- Progress tracking without memory leaks
- Proper signal disconnection

### Best Practices

1. **Preload Early**: Load common resources during splash screen or menu
2. **Batch Loading**: Use `preload_resources()` for multiple files
3. **Monitor Progress**: Connect to signals for user feedback
4. **Clean Up**: Call `cleanup_completed_jobs()` periodically
5. **Cache Friendly**: Don't reload resources unnecessarily

## Troubleshooting

### Common Issues

**LoadingManager not found**
- Ensure it's added as autoload in Project Settings
- Check the script path in autoload settings

**Resources not loading**
- Verify file paths with `ResourceLoader.exists()`
- Check console for error messages
- Ensure resources are properly imported

**Performance issues**
- Reduce `max_concurrent_loads` for weaker devices
- Increase `frame_time_limit_ms` for better loading speed
- Use `cleanup_completed_jobs()` to free memory

**Loading screen not showing**
- Ensure loading_screen.tscn exists in scenes/UI/
- Check if font file exists in MyAssets/fonts/
- Verify LoadingManager is properly autoloaded

### Debug Functions

```gdscript
# Print detailed loading status
LoadingManager.print_loading_status()

# Get loading statistics
var stats = LoadingManager.get_loading_stats()

# Check current jobs
for path in LoadingManager.current_jobs:
    var job = LoadingManager.current_jobs[path]
    print(path, " - State: ", job.state, " - Progress: ", job.progress)
```

## Example Projects

See `loading_manager_example.gd` for comprehensive usage examples including:

- Scene transitions with loading screens
- Car model preloading
- Progress monitoring
- Integration with existing systems
- Error handling
- Performance optimization

## API Reference

### LoadingManager Methods

- `load_resource_async(path, type_hint, use_sub_threads)` - Start async loading
- `change_scene_async(scene_path, show_loading_screen)` - Change scene with loading
- `preload_resources(paths, batch_size)` - Preload multiple resources
- `is_loading(path)` - Check if resource is loading
- `get_loading_progress(path)` - Get progress for specific resource
- `get_overall_progress()` - Get overall progress for all jobs
- `cancel_loading(path)` - Cancel loading a specific resource
- `cleanup_completed_jobs()` - Clean up completed jobs
- `get_loading_stats()` - Get loading statistics

### LoadingJob Properties

- `resource_path` - Path to the resource
- `state` - Current loading state (0=IDLE, 1=LOADING, 2=COMPLETED, 3=FAILED)
- `progress` - Loading progress (0.0 to 1.0)
- `loaded_resource` - The loaded resource (when completed)
- `error_code` - Error code if loading failed

### LoadingScreen Methods

- `show_loading_screen()` - Show with fade in
- `hide_loading_screen()` - Hide with fade out
- `update_progress(progress, message)` - Update progress bar
- `set_loading_message(message)` - Set status message
- `show_with_message(message)` - Show with custom message
