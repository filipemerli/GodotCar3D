extends Resource
class_name CarData

# Car properties
@export var car_name: String = "Default Car"
@export var scene_path: String = "res://MyCars/SimpleCar/delorian.tscn"
@export var description: String = "A standard racing vehicle."

# Performance stats
@export var max_speed: float = 890.0
@export var acceleration: int = 550
@export var steering_speed: float = 1.1
@export var handling: float = 5.0
@export var braking: float = 7.0

# Additional customization options (if needed)
@export var engine_sound_path: String = "res://MyAssets/sounds/carengine.wav"
#@export var exhaust_particle_path: String = "res://assets/particles/default_exhaust.tscn"
