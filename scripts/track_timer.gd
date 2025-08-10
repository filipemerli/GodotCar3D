extends Node
class_name TrackTimer

signal time_warning_triggered(remaining_time: float)
signal time_expired
signal race_completed(final_time: float, passed: bool)

@export var track_config: Resource
@export var auto_start: bool = false
@export var show_debug: bool = false

var current_time: float = 0.0
var is_running: bool = false
var is_paused: bool = false
var race_started: bool = false
var race_finished: bool = false

# Warning system
var warning_triggered: bool = false
var warning_threshold: float = 10.0  # Warn when 10 seconds left

func _ready():
	if not track_config:
		push_warning("TrackTimer: No TrackConfig assigned!")
		return
	
	if show_debug:
		print("TrackTimer initialized for track: ", track_config.track_name)
		print("Time limit: ", track_config.get_formatted_time(track_config.time_limit))
	
	if auto_start:
		start_timer()

func _process(delta):
	if not is_running or is_paused or not track_config:
		return
	
	current_time += delta
	
	# Check warnings
	var remaining_time = get_remaining_time()
	if remaining_time <= warning_threshold and not warning_triggered:
		warning_triggered = true
		time_warning_triggered.emit(remaining_time)
		if show_debug:
			print("Timer warning: ", track_config.get_formatted_time(remaining_time), " remaining")
	
	# Check if time expired
	if current_time >= track_config.time_limit:
		_finish_race(false, "Time expired")

func start_timer():
	"""Start the race timer"""
	if not track_config:
		push_error("Cannot start timer without TrackConfig!")
		return
	
	current_time = 0.0
	is_running = true
	is_paused = false
	race_started = true
	race_finished = false
	warning_triggered = false
	
	if show_debug:
		print("Race timer started! Time limit: ", track_config.get_formatted_time(track_config.time_limit))

func pause_timer():
	"""Pause the timer"""
	is_paused = true
	if show_debug:
		print("Timer paused at: ", get_formatted_current_time())

func resume_timer():
	"""Resume the timer"""
	is_paused = false
	if show_debug:
		print("Timer resumed at: ", get_formatted_current_time())

func stop_timer():
	"""Stop the timer completely"""
	is_running = false
	is_paused = false
	if show_debug:
		print("Timer stopped at: ", get_formatted_current_time())

func complete_race():
	"""Mark the race as completed successfully"""
	if race_finished:
		return
	
	_finish_race(true, "Race completed")

func reset_timer():
	"""Reset timer to initial state"""
	current_time = 0.0
	is_running = false
	is_paused = false
	race_started = false
	race_finished = false
	warning_triggered = false
	
	if show_debug:
		print("Timer reset")

func _finish_race(success: bool, reason: String):
	"""Internal method to finish the race"""
	if race_finished:
		return
		
	race_finished = true
	is_running = false
	
	if show_debug:
		print("Race finished: ", reason)
		print("Final time: ", get_formatted_current_time())
		print("Time limit: ", track_config.get_formatted_time(track_config.time_limit))
		print("Result: ", "PASSED" if success else "FAILED")
	
	# Update statistics
	if success and track_config:
		track_config.update_best_time(current_time)
	elif not success and track_config:
		track_config.record_failed_attempt()
	
	# Emit signals
	if not success and current_time >= track_config.time_limit:
		time_expired.emit()
	
	race_completed.emit(current_time, success)

# Getter methods
func get_current_time() -> float:
	"""Get current elapsed time in seconds"""
	return current_time

func get_remaining_time() -> float:
	"""Get remaining time in seconds"""
	if not track_config:
		return 0.0
	return max(0.0, track_config.time_limit - current_time)

func get_formatted_current_time() -> String:
	"""Get formatted current time"""
	if not track_config:
		return "00:00.00"
	return track_config.get_formatted_time(current_time)

func get_formatted_remaining_time() -> String:
	"""Get formatted remaining time"""
	if not track_config:
		return "00:00.00"
	return track_config.get_formatted_time(get_remaining_time())

func get_progress_percentage() -> float:
	"""Get time progress as percentage (0.0 to 1.0)"""
	if not track_config or track_config.time_limit <= 0:
		return 0.0
	return min(1.0, current_time / track_config.time_limit)

func is_time_critical() -> bool:
	"""Check if remaining time is in critical range"""
	return get_remaining_time() <= warning_threshold

func is_timer_running() -> bool:
	"""Check if timer is currently running"""
	return is_running and not is_paused

func has_time_expired() -> bool:
	"""Check if time has expired"""
	return track_config and current_time >= track_config.time_limit

# Configuration methods
func set_track_config(config: Resource):
	"""Set a new track configuration"""
	track_config = config
	reset_timer()

func set_warning_threshold(seconds: float):
	"""Set the warning threshold in seconds"""
	warning_threshold = max(0.0, seconds)
