extends VehicleBody3D

const FORCE = 500

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	steering = move_toward(
		steering,
		Input.get_axis("ui_right", "ui_left"),
		delta * 1.1
	)
	var acc = Input.get_axis("ui_down", "ui_up")
	engine_force = acc * FORCE
