extends Node

## GameManager - Global game state and progression system
## Singleton that manages save/load, car unlocks, and track records

signal car_unlocked(car_name: String)
signal track_record_updated(track_name: String, new_time: float)
signal game_data_loaded()
signal disable_car_control(disabled: bool)  # For compatibility with existing car system

# Current session state
var current_car: String = "delorean"
var current_track: String = ""
var is_loading: bool = false
var isPlaying: bool = false  # For compatibility with existing car control system

# Player progression data
var player_data: Dictionary = {
	"unlocked_cars": ["delorean"],  # Start with DeLorean unlocked
	"track_records": {},             # Best times per track
	"completed_challenges": [],      # Challenge IDs completed
	"total_play_time": 0.0,         # Total game time
	"games_played": 0,              # Number of races
	"settings": {
		"sfx_volume": 1.0,
		"music_volume": 0.8,
		"vibration_enabled": true,
		"control_sensitivity": 1.0
	}
}

# Car unlock requirements - defines progression system
var car_unlock_requirements: Dictionary = {
	"sports_car": ["track_01", "track_02"],      # Beat Desert Loop + City Circuit
	"muscle_car": ["track_03", "track_04"],      # Beat Mountain Pass + Speedway  
	"super_car": ["track_01", "track_02", "track_03", "track_04"]  # Beat all 4 tracks
}

# Track challenge times - target times to beat for unlocks
var track_target_times: Dictionary = {
	"track_01": 30.5,  # Desert Loop (your current test track)
	"track_02": 28.0,  # City Circuit
	"track_03": 35.0,  # Mountain Pass
	"track_04": 25.5,  # Speedway
	"final_track": 22.0  # Ultimate Challenge
}

# Car display names
var car_names: Dictionary = {
	"delorean": "DeLorean DMC-12",
	"sports_car": "Thunder Bolt",
	"muscle_car": "Road Warrior", 
	"super_car": "Apex Predator"
}

const SAVE_FILE_PATH = "user://game_save.dat"

func _ready():
	# Make this node a singleton
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_game_data()

## Save System
func save_game_data():
	print("[GameManager] Saving game data...")
	var save_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if save_file == null:
		print("[GameManager] ERROR: Could not open save file for writing")
		return false
		
	var save_data = {
		"version": "1.0",
		"timestamp": Time.get_unix_time_from_system(),
		"player_data": player_data
	}
	
	save_file.store_string(JSON.stringify(save_data))
	save_file.close()
	print("[GameManager] Game saved successfully")
	return true

func load_game_data():
	print("[GameManager] Loading game data...")
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("[GameManager] No save file found, using default data")
		game_data_loaded.emit()
		return
		
	var save_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if save_file == null:
		print("[GameManager] ERROR: Could not open save file for reading")
		game_data_loaded.emit()
		return
		
	var save_data_text = save_file.get_as_text()
	save_file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(save_data_text)
	
	if parse_result != OK:
		print("[GameManager] ERROR: Could not parse save data")
		game_data_loaded.emit()
		return
		
	var save_data = json.data
	if save_data.has("player_data"):
		player_data = save_data.player_data
		print("[GameManager] Save data loaded successfully")
	
	game_data_loaded.emit()

## Car Management
func is_car_unlocked(car_name: String) -> bool:
	return car_name in player_data.unlocked_cars

func unlock_car(car_name: String) -> bool:
	if is_car_unlocked(car_name):
		return false  # Already unlocked
		
	player_data.unlocked_cars.append(car_name)
	car_unlocked.emit(car_name)
	save_game_data()
	print("[GameManager] Car unlocked: ", car_names.get(car_name, car_name))
	return true

func get_unlocked_cars() -> Array:
	return player_data.unlocked_cars.duplicate()

func check_car_unlock_requirements(car_name: String) -> bool:
	if not car_unlock_requirements.has(car_name):
		return false
		
	var required_tracks = car_unlock_requirements[car_name]
	for track in required_tracks:
		if not is_track_completed(track):
			return false
			
	return true

## Track Records & Progression
func update_track_record(track_name: String, race_time: float) -> bool:
	var current_best = get_track_record(track_name)
	var is_new_record = false
	
	if current_best == 0.0 or race_time < current_best:
		player_data.track_records[track_name] = race_time
		track_record_updated.emit(track_name, race_time)
		is_new_record = true
		print("[GameManager] New record on %s: %.2fs" % [track_name, race_time])
		
		# Check if this completes a challenge
		if race_time <= track_target_times.get(track_name, 999.0):
			complete_track_challenge(track_name)
	
	# Always update games played counter
	player_data.games_played += 1
	save_game_data()
	return is_new_record

func get_track_record(track_name: String) -> float:
	return player_data.track_records.get(track_name, 0.0)

func is_track_completed(track_name: String) -> bool:
	return track_name in player_data.completed_challenges

func complete_track_challenge(track_name: String):
	if track_name in player_data.completed_challenges:
		return  # Already completed
		
	player_data.completed_challenges.append(track_name)
	print("[GameManager] Track challenge completed: ", track_name)
	
	# Check for car unlocks
	check_and_unlock_cars()

func check_and_unlock_cars():
	for car_name in car_unlock_requirements.keys():
		if not is_car_unlocked(car_name) and check_car_unlock_requirements(car_name):
			unlock_car(car_name)

func get_track_target_time(track_name: String) -> float:
	return track_target_times.get(track_name, 30.0)

## Game Session
func start_race(track_name: String, car_name: String):
	current_track = track_name
	current_car = car_name
	print("[GameManager] Starting race: %s with %s" % [track_name, car_names.get(car_name, car_name)])

func end_race(race_time: float) -> Dictionary:
	var result = {
		"race_time": race_time,
		"is_new_record": false,
		"challenge_completed": false,
		"cars_unlocked": []
	}
	
	if current_track != "":
		result.is_new_record = update_track_record(current_track, race_time)
		result.challenge_completed = race_time <= get_track_target_time(current_track)
		
		# Track any cars that might have been unlocked
		var cars_before = get_unlocked_cars()
		check_and_unlock_cars()
		var cars_after = get_unlocked_cars()
		
		for car in cars_after:
			if car not in cars_before:
				result.cars_unlocked.append(car)
	
	return result

## Settings
func update_setting(key: String, value):
	player_data.settings[key] = value
	save_game_data()

func get_setting(key: String, default_value = null):
	return player_data.settings.get(key, default_value)

## Debug & Utility
func reset_all_progress():
	print("[GameManager] RESETTING ALL PROGRESS!")
	player_data = {
		"unlocked_cars": ["delorean"],
		"track_records": {},
		"completed_challenges": [],
		"total_play_time": 0.0,
		"games_played": 0,
		"settings": player_data.settings  # Keep settings
	}
	save_game_data()

func get_completion_percentage() -> float:
	var total_cars = car_unlock_requirements.size() + 1  # +1 for starting car
	var unlocked_count = player_data.unlocked_cars.size()
	return (float(unlocked_count) / float(total_cars)) * 100.0

## Debug functions for testing
func _unhandled_key_input(event):
	if OS.is_debug_build():
		if event.pressed and event.keycode == KEY_F1:
			unlock_car("sports_car")  # Debug unlock
		elif event.pressed and event.keycode == KEY_F2:
			reset_all_progress()  # Debug reset
