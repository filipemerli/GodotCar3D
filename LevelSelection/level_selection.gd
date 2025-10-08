extends Control

var is_lvl_selected: bool = false
var current_selection: int = 1

func start_game_action():
	# Get LoadingManager dynamically to avoid autoload recognition issues
	var loading_manager = get_node_or_null("/root/LoadingManager")
	if loading_manager:
		if current_selection == 1:
			loading_manager.change_scene_async("res://Tests/test_scene.tscn", true)
		if current_selection == 2:
			loading_manager.change_scene_async("res://Level2/scene_for_lvl_2.tscn", true)
		if current_selection == 3:
			loading_manager.change_scene_async("res://level3/level_3.tscn", true)
		if current_selection == 4:
			loading_manager.change_scene_async("res://level5/level_5.tscn", true)
		if current_selection == 5:
			loading_manager.change_scene_async("res://level4/level_4.tscn", true)
	else:
		# Fallback to direct scene change if LoadingManager not available
		get_tree().change_scene_to_file("res://Tests/test_scene.tscn")

func _on_ok_btn_pressed() -> void:
	if is_lvl_selected:
		start_game_action()

func _on_lvl_1_btn_pressed() -> void:
	current_selection = 1
	is_lvl_selected = true
	start_game_action()

func _on_lvl_2_btn_pressed() -> void:
	current_selection = 2
	is_lvl_selected = true
	start_game_action()

func _on_lvl_3_btn_pressed() -> void:
	current_selection = 3
	is_lvl_selected = true
	start_game_action()

func _on_lvl_4_btn_pressed() -> void:
	current_selection = 4
	is_lvl_selected = true
	start_game_action()

func _on_lvl_5_btn_pressed() -> void:
	current_selection = 5
	is_lvl_selected = true
	start_game_action()
