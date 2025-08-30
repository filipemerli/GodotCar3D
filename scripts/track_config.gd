extends Resource
class_name TrackConfig

# Track identification
@export var track_name: String = "Test Track"
@export var track_id: String = "test_track_01"

# Time settings
@export var time_limit: float = 30.5  # Time limit in seconds
@export var warning_threshold: float = 10.0  # When to show warning (seconds remaining)
@export var critical_threshold: float = 5.0   # When to show critical warning

# Track properties
@export_enum("Easy", "Medium", "Hard", "Expert") var difficulty: String = "Easy"
@export var best_time: float = 0.0  # Best completion time (0 = no record)
@export var target_time: float = 25.0  # Target time for good completion

# Statistics tracking
@export var attempts: int = 0  # Total number of attempts
@export var completions: int = 0  # Number of successful completions

# Bonus/Penalty settings
@export var checkpoint_bonus_time: float = 0.0  # Bonus time per checkpoint (if any)
@export var wrong_direction_penalty: float = 2.0  # Time penalty for wrong direction

# Track description
@export_multiline var description: String = "A test track for racing."

func save_best_time(new_time: float) -> bool:
	"""Save a new best time if it's better than current"""
	if best_time == 0.0 or new_time < best_time:
		best_time = new_time
		return true
	return false

func get_time_grade(completion_time: float) -> String:
	"""Get grade based on completion time"""
	if completion_time <= target_time:
		return "S"  # Excellent
	elif completion_time <= target_time * 1.1:
		return "A"  # Great
	elif completion_time <= target_time * 1.2:
		return "B"  # Good
	elif completion_time <= target_time * 1.3:
		return "C"  # OK
	else:
		return "D"  # Needs improvement

func get_success_rate() -> float:
	"""Get success rate as percentage (0.0 to 100.0)"""
	if attempts == 0:
		return 0.0
	return (float(completions) / float(attempts)) * 100.0

func is_new_record(completion_time: float) -> bool:
	"""Check if completion time is a new record"""
	return best_time == 0.0 or completion_time < best_time

func update_best_time(completion_time: float) -> bool:
	"""Update best time if this is a new record. Returns true if new record was set."""
	attempts += 1
	completions += 1
	
	if is_new_record(completion_time):
		best_time = completion_time
		print("TrackConfig: NEW RECORD! ", get_formatted_time(completion_time))
		return true
	else:
		print("TrackConfig: Completed in ", get_formatted_time(completion_time), " (Best: ", get_formatted_time(best_time), ")")
		return false

func record_failed_attempt():
	"""Record a failed attempt (time expired, crash, etc.)"""
	attempts += 1
	print("TrackConfig: Failed attempt recorded. Total attempts: ", attempts, " Success rate: ", "%.1f%%" % get_success_rate())

func get_formatted_time(time_seconds: float) -> String:
	"""Format time as MM:SS.ms"""
	var total_seconds = int(time_seconds)
	var minutes = total_seconds / 60.0
	var seconds = total_seconds % 60
	var milliseconds = int((time_seconds - total_seconds) * 100)
	return "%02d:%02d.%02d" % [int(minutes), seconds, milliseconds]
