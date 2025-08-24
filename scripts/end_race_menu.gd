extends Control

@onready var winner: CanvasLayer = $Winner
@onready var looser: CanvasLayer = $Looser
@onready var time_label: Label = $Winner/VBoxContainerW/timeLabel

func showWin(time: float):
	winner.visible = true
	call_deferred("updateTimeLabel", time)
	await get_tree().create_timer(4.8).timeout
	get_tree().change_scene_to_file("res://scenes/car_selection.tscn")
	
func showLoose():
	looser.visible = true

func _on_try_again_btn_pressed() -> void:
	get_tree().reload_current_scene()

func updateTimeLabel(time: float):
	time_label.text = "Your time: " + str("%.4f" % time)
