extends Node
class_name CheckpointManager

# Array to hold all checkpoint nodes in order
@export var checkpoints: Array[Node3D] = []

# Current checkpoint tracking
var current_checkpoint_index: int = 0
var total_checkpoints: int = 0

# Signals
signal checkpoint_reached(checkpoint_index: int)
signal lap_completed()
signal all_checkpoints_completed()

func _ready() -> void:
	_initialize_checkpoints()

func _initialize_checkpoints() -> void:
	total_checkpoints = checkpoints.size()
	
	if total_checkpoints == 0:
		print("Warning: No checkpoints assigned to CheckpointManager!")
		return
	
	# Hide all checkpoints except the first one
	for i in range(total_checkpoints):
		if checkpoints[i] == null:
			print("Warning: Checkpoint at index ", i, " is null!")
			continue
			
		checkpoints[i].visible = (i == 0)
		
		# Connect to checkpoint signals
		if checkpoints[i].has_signal("did_check"):
			if not checkpoints[i].is_connected("did_check", _on_checkpoint_reached):
				checkpoints[i].connect("did_check", _on_checkpoint_reached.bind(i))

func _on_checkpoint_reached(checkpoint_index: int) -> void:
	# Emit checkpoint reached signal
	emit_signal("checkpoint_reached", checkpoint_index)
	
	# Move to next checkpoint
	current_checkpoint_index += 1
	
	# Check if we've completed all checkpoints
	if current_checkpoint_index >= total_checkpoints:
		emit_signal("all_checkpoints_completed")
		_handle_lap_completion()
	else:
		# Activate next checkpoint
		_activate_next_checkpoint()

func _activate_next_checkpoint() -> void:
	if current_checkpoint_index < total_checkpoints:
		# Make sure the next checkpoint exists
		if checkpoints[current_checkpoint_index] != null:
			if (current_checkpoint_index + 1) != total_checkpoints:
				checkpoints[current_checkpoint_index].visible = true

func _handle_lap_completion() -> void:
	# You can customize this behavior:
	# Option A: Reset to first checkpoint for another lap
	# Option B: End the race
	# Option C: Continue to a new set of checkpoints
	
	emit_signal("lap_completed")
	
	# For now, let's reset to first checkpoint for another lap
	reset_to_first_checkpoint()

func reset_to_first_checkpoint() -> void:
	current_checkpoint_index = 0
	
	# Hide all checkpoints except the first
	for i in range(total_checkpoints):
		if checkpoints[i] != null:
			checkpoints[i].visible = (i == 0)

func get_current_checkpoint_index() -> int:
	return current_checkpoint_index

func get_total_checkpoints() -> int:
	return total_checkpoints

func get_progress_percentage() -> float:
	if total_checkpoints == 0:
		return 0.0
	return float(current_checkpoint_index) / float(total_checkpoints)
