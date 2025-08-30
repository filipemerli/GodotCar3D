extends Control

@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var unlock_button: Button = $VBoxContainer/UnlockButton
@onready var reset_button: Button = $VBoxContainer/ResetButton
@onready var test_complete_button: Button = $VBoxContainer/TestCompleteButton

func _ready():
	unlock_button.pressed.connect(_on_unlock_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	test_complete_button.pressed.connect(_on_test_complete_pressed)
	
	# Connect to GameManager signals
	GameManager.car_unlocked.connect(_on_car_unlocked)
	GameManager.track_record_updated.connect(_on_track_record_updated)
	
	update_status()

func update_status():
	var text = "=== GAMEMANAGER DEBUG ===\n\n"
	
	text += "Unlocked Cars: %s\n" % str(GameManager.get_unlocked_cars())
	text += "Completion: %.1f%%\n\n" % GameManager.get_completion_percentage()
	
	text += "Track Records:\n"
	for track in GameManager.track_target_times.keys():
		var record = GameManager.get_track_record(track)
		var target = GameManager.get_track_target_time(track)
		var completed = GameManager.is_track_completed(track)
		text += "  %s: %.2fs / %.2fs %s\n" % [track, record, target, "✓" if completed else "✗"]
	
	text += "\nCar Requirements:\n"
	for car in GameManager.car_unlock_requirements.keys():
		var unlocked = GameManager.is_car_unlocked(car)
		var can_unlock = GameManager.check_car_unlock_requirements(car)
		text += "  %s: %s %s\n" % [GameManager.car_names[car], "UNLOCKED" if unlocked else "LOCKED", "✓" if can_unlock else "✗"]
	
	text += "\nGames Played: %d\n" % GameManager.player_data.games_played
	
	status_label.text = text

func _on_unlock_pressed():
	# Test unlock next car
	for car in GameManager.car_unlock_requirements.keys():
		if not GameManager.is_car_unlocked(car):
			GameManager.unlock_car(car)
			break

func _on_reset_pressed():
	GameManager.reset_all_progress()
	update_status()

func _on_test_complete_pressed():
	# Simulate completing track_01 in 28.5 seconds (beats the 30.5s target)
	var fake_time = 28.5
	GameManager.start_race("track_01", "delorean")
	var result = GameManager.end_race(fake_time)
	print("Test completion result: ", result)
	update_status()

func _on_car_unlocked(car_name: String):
	print("🚗 CAR UNLOCKED: ", GameManager.car_names.get(car_name, car_name))
	update_status()

func _on_track_record_updated(track_name: String, new_time: float):
	print("🏁 NEW RECORD on %s: %.2fs" % [track_name, new_time])
	update_status()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/car_selection.tscn")
