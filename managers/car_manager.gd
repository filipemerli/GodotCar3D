extends Node

# Array of all available car resources
var available_cars: Array = []

# Currently selected car data
var selected_car_data: CarData

# Loads all car resources from the specified directory
func _ready():
	load_all_cars()

func load_all_cars():
	var car_resources = [
		preload("res://resources/cars/delorian.tres"),
		preload("res://resources/cars/skyline.tres"),
		preload("res://resources/cars/nissan180nx.tres"),
		preload("res://resources/cars/challenger.tres")
	]
	# Filter the exported resources
	for car in car_resources:
		if car is CarData:
			available_cars.append(car)
	# Set default car if we have any cars available
	if available_cars.size() > 0:
		selected_car_data = available_cars[0]
	else:
		print("WARNING: No cars available!")

# Select a car by index
func select_car(index: int):
	if index >= 0 and index < available_cars.size():
		selected_car_data = available_cars[index]
		return true
	return false

# Instantiate the currently selected car
func instantiate_car() -> VehicleBody3D:
	if selected_car_data:
		# Load the base car template
		var car_scene = load(selected_car_data.scene_path)
		if car_scene:
			var car_instance = car_scene.instantiate() as VehicleBody3D
			# Apply car-specific properties
			car_instance.max_speed = selected_car_data.max_speed
			car_instance.acceleration = selected_car_data.acceleration
			car_instance.handling = selected_car_data.handling
			car_instance.braking = selected_car_data.braking

			# Load and set engine sound if specified
			#if selected_car_data.engine_sound_path != "":
				#var sound = load(selected_car_data.engine_sound_path)
				#if sound:
					#car_instance.get_node("EngineSound").stream = sound

			return car_instance
	return null
