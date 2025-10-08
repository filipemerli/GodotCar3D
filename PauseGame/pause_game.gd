extends Control

func _on_continue_button_pressed() -> void:
	visible = false
	get_tree().paused = !get_tree().paused

func _on_end_race_button_pressed() -> void:
	get_tree().paused = !get_tree().paused
	LoadingManager.change_scene_async("res://scenes/car_selection.tscn", true)

func _on_button_pressed() -> void:
	visible = false
	get_tree().paused = !get_tree().paused
