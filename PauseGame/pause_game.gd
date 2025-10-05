extends Control


func _on_close_button_pressed() -> void:
	visible = false


func _on_continue_button_pressed() -> void:
	visible = false
	#Pause game

func _on_end_race_button_pressed() -> void:
	visible = false
	LoadingManager.change_scene_async("res://scenes/car_selection.tscn", true)
