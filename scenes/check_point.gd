extends Node3D

signal did_check

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("car"):
		emit_signal("did_check")
		call_deferred("kill_me")

func kill_me():
	queue_free()
