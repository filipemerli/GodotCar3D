extends Control

## LoadingScreen - UI component for showing loading progress
## Works with LoadingManager to display progress and status

@onready var loading_label: Label = $CenterContainer/VBoxContainer/LoadingLabel
@onready var progress_bar: ProgressBar = $CenterContainer/VBoxContainer/ProgressBar
@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel
@onready var spinner: TextureRect = $CenterContainer/VBoxContainer/SpinnerContainer/Spinner

var loading_manager: Node
var is_active: bool = false
var current_progress: float = 0.0
var target_progress: float = 0.0

# Loading messages for different stages
var loading_messages = [
	"Preparing resources...",
	"Loading textures...",
	"Loading models...",
	"Loading audio...",
	"Initializing scene...",
	"Almost ready..."
]

var current_message_index: int = 0

func _ready():
	# Hide by default
	hide()
	
	# Connect to LoadingManager if available
	loading_manager = get_node_or_null("/root/LoadingManager")
	if loading_manager:
		_connect_to_loading_manager()
	
	# Setup spinner animation
	_setup_spinner_animation()

func _process(delta):
	if is_active:
		# Smooth progress bar animation
		if current_progress < target_progress:
			current_progress = move_toward(current_progress, target_progress, delta * 0.5)
			progress_bar.value = current_progress * 100.0
		
		# Update loading message based on progress
		_update_loading_message()

func show_loading_screen():
	"""Show the loading screen and start animations"""
	if is_active:
		return
	
	is_active = true
	current_progress = 0.0
	target_progress = 0.0
	current_message_index = 0
	
	show()
	
	# Fade in animation
	modulate = Color.TRANSPARENT
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	
	# Start spinner
	if spinner.has_method("play"):
		spinner.play()
	
	# Reset UI elements
	progress_bar.value = 0.0
	status_label.text = loading_messages[0]
	loading_label.text = "LOADING..."
	
	print("LoadingScreen: Showing loading screen")

func hide_loading_screen():
	"""Hide the loading screen with fade out"""
	if not is_active:
		return
	
	# Fade out animation
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.3)
	tween.tween_callback(_complete_hide)
	
	print("LoadingScreen: Hiding loading screen")

func update_progress(progress: float, message: String = ""):
	"""Update the loading progress (0.0 to 1.0)"""
	target_progress = clamp(progress, 0.0, 1.0)
	
	if message != "":
		status_label.text = message
	
	# If we've reached 100%, show completion message
	if target_progress >= 1.0:
		status_label.text = "Complete!"
		loading_label.text = "READY!"

func set_loading_message(message: String):
	"""Set a custom loading message"""
	status_label.text = message

func _complete_hide():
	"""Complete the hide process"""
	hide()
	is_active = false

func _connect_to_loading_manager():
	"""Connect to LoadingManager signals"""
	if not loading_manager:
		return
	
	# Connect to loading events
	if not loading_manager.loading_started.is_connected(_on_loading_started):
		loading_manager.loading_started.connect(_on_loading_started)
	
	if not loading_manager.loading_progress_changed.is_connected(_on_loading_progress_changed):
		loading_manager.loading_progress_changed.connect(_on_loading_progress_changed)
	
	if not loading_manager.loading_completed.is_connected(_on_loading_completed):
		loading_manager.loading_completed.connect(_on_loading_completed)
	
	if not loading_manager.loading_failed.is_connected(_on_loading_failed):
		loading_manager.loading_failed.connect(_on_loading_failed)

func _setup_spinner_animation():
	"""Create a spinning animation for the loading indicator"""
	if not spinner:
		return
	
	# Create rotation animation
	var tween = create_tween()
	tween.set_loops()  # Infinite loop
	tween.tween_property(spinner, "rotation", TAU, 2.0)  # Full rotation in 2 seconds
	tween.tween_callback(func(): pass)  # Keep the loop going

func _update_loading_message():
	"""Update loading message based on progress"""
	var progress_index = int(current_progress * (loading_messages.size() - 1))
	progress_index = clamp(progress_index, 0, loading_messages.size() - 1)
	
	if progress_index != current_message_index:
		current_message_index = progress_index
		if current_progress < 1.0:  # Don't change message if we're at 100%
			status_label.text = loading_messages[current_message_index]

# LoadingManager signal handlers

func _on_loading_started(resource_path: String):
	"""Called when loading starts"""
	if not is_active:
		show_loading_screen()
	
	# Extract filename for display
	var filename = resource_path.get_file()
	set_loading_message("Loading " + filename + "...")

func _on_loading_progress_changed(progress: float, _resource_path: String):
	"""Called when loading progress updates"""
	if loading_manager:
		# Get overall progress instead of individual resource progress
		var overall_progress = loading_manager.get_overall_progress()
		update_progress(overall_progress)
	else:
		update_progress(progress)

func _on_loading_completed(_resource: Resource, _resource_path: String):
	"""Called when a resource finishes loading"""
	# Check if all loading is complete
	if loading_manager:
		var overall_progress = loading_manager.get_overall_progress()
		update_progress(overall_progress)
		
		# If all loading complete, prepare to hide
		if overall_progress >= 1.0:
			# Wait a moment to show completion, then hide
			await get_tree().create_timer(0.5).timeout
			hide_loading_screen()
	else:
		update_progress(1.0)
		await get_tree().create_timer(0.5).timeout
		hide_loading_screen()

func _on_loading_failed(_error_code: Error, resource_path: String):
	"""Called when loading fails"""
	loading_label.text = "ERROR!"
	status_label.text = "Failed to load: " + resource_path.get_file()
	
	# Hide after showing error
	await get_tree().create_timer(3.0).timeout
	hide_loading_screen()

# Public utility methods

func show_with_message(message: String):
	"""Show loading screen with a specific message"""
	show_loading_screen()
	set_loading_message(message)

func show_indeterminate(message: String = "Loading..."):
	"""Show loading screen with indeterminate progress"""
	show_loading_screen()
	set_loading_message(message)
	
	# Hide progress bar for indeterminate loading
	progress_bar.hide()
	
	# Show progress bar again when hidden
	await visibility_changed
	if not visible:
		progress_bar.show()
