extends Control

@onready var winner: CanvasLayer = $Winner
@onready var looser: CanvasLayer = $Looser
@onready var time_label: Label = $Winner/VBoxContainerW/timeLabel

func showWin(time: float):
	winner.visible = true
	call_deferred("updateTimeLabel", time)
	await get_tree().create_timer(4.8).timeout
	get_tree().change_scene_to_file("res://scenes/car_selection.tscn")

func show_win_with_progression(race_time: float, target_time: float, challenge_completed: bool, is_new_record: bool, cars_unlocked: Array):
	winner.visible = true
	call_deferred("update_progression_display", race_time, target_time, challenge_completed, is_new_record, cars_unlocked)
	await get_tree().create_timer(6.0).timeout  # Give more time to read progression info
	get_tree().change_scene_to_file("res://scenes/car_selection.tscn")
	
func showLoose():
	looser.visible = true

func show_loose_with_target(target_time: float):
	looser.visible = true
	# Could enhance looser screen to show target time
	print("Target time was: %.2fs - Keep trying!" % target_time)

func _on_try_again_btn_pressed() -> void:
	get_tree().reload_current_scene()

func updateTimeLabel(time: float):
	time_label.text = "Your time: " + str("%.4f" % time)

func update_progression_display(race_time: float, target_time: float, challenge_completed: bool, is_new_record: bool, cars_unlocked: Array):
	var display_text = "Your time: " + str("%.2f" % race_time) + "s\n"
	display_text += "Target time: " + str("%.2f" % target_time) + "s\n"
	
	if challenge_completed:
		display_text += "🏆 CHALLENGE COMPLETED! 🏆\n"
	else:
		var time_diff = race_time - target_time
		display_text += "⏱️ %.2fs too slow for challenge\n" % time_diff
	
	if is_new_record:
		display_text += "🎯 NEW PERSONAL RECORD! 🎯\n"
	
	if cars_unlocked.size() > 0:
		display_text += "\n🚗 NEW CAR UNLOCKED! 🚗\n"
		for car in cars_unlocked:
			display_text += GameManager.car_names.get(car, car) + "\n"
	
	time_label.text = display_text
