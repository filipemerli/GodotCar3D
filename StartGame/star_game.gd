extends Control

func _on_play_button_pressed() -> void:
	LoadingManager.change_scene_async("res://scenes/car_selection.tscn", true)
