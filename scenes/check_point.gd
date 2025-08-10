extends Node3D

signal did_check
const GROUP_NAME: String = "car"
var entered_front: bool = false
var entered_rear: bool = false

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group(GROUP_NAME) and entered_front and not entered_rear:
		did_check.emit()
		call_deferred("kill_me")

func kill_me():
	queue_free()

func _on_front_area_body_entered(body: Node3D) -> void:
	if not body.is_in_group(GROUP_NAME) or entered_front:
		return
	entered_front = true

func _on_back_area_body_entered(body: Node3D) -> void:
	if not body.is_in_group(GROUP_NAME) or entered_rear:
		return
	entered_rear = true

func _on_back_area_body_exited(body: Node3D) -> void:
	if not body.is_in_group(GROUP_NAME) or not entered_rear:
		return
	entered_rear = false

func _on_front_area_body_exited(body: Node3D) -> void:
	if not body.is_in_group(GROUP_NAME) or not entered_front:
		return
	entered_front = false
