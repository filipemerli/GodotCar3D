extends Control

@onready var start_lights: CanvasLayer = $startLights
@onready var red_one: TextureRect = $startLights/HBoxContainer/redOne
@onready var red_two: TextureRect = $startLights/HBoxContainer/redTwo
@onready var green_go: TextureRect = $startLights/HBoxContainer/greenGo
@onready var timer: Timer = $startLights/Timer
@onready var green_light_sound: AudioStreamPlayer = $startLights/greenLightSound
@onready var red_light_sound: AudioStreamPlayer = $startLights/redLightSound
@onready var timer_2: Timer = $Timer2
@onready var timer_label: Label = $TimerLabel

var green_on_texture = preload("res://scenes/UIControlNode/green_light_on_texture_2d.tres")
var red_on_texture = preload("res://scenes/UIControlNode/red_light_on_texture_2d.tres")
var green_off_texture = preload("res://scenes/UIControlNode/green_light_off_texture_2d.tres")
var red_off_texture = preload("res://scenes/UIControlNode/red_light_off_texture_2d.tres")

var countdown: int = 3
var should_show_time: bool = false
var timer_update_interval: float = 0.01
var last_timer_update_time: float = 0.0

signal end_timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect("end_timer", stop_timer)
	await get_tree().create_timer(.25).timeout
	start_lights.visible = true
	GameManager.isPlaying = false
	await get_tree().create_timer(2.5).timeout
	triggerStartLights()

func _process(delta: float) -> void:
	if should_show_time:
		if last_timer_update_time >= timer_update_interval:
			var time_passed := 120.0 - timer_2.time_left
			var seconds := int(floor(time_passed)) % 60
			var milliseconds := int((time_passed - floor(time_passed)) * 100)
			timer_label.text = "%02d:%02d" % [seconds, milliseconds]
			last_timer_update_time = 0.0
		last_timer_update_time += delta

func triggerStartLights():
	if countdown == 3:
		red_light_sound.play()
		red_one.texture = red_on_texture
		countdown -= 1
		timer.start()
	elif countdown == 2:
		red_two.texture = red_on_texture
		red_light_sound.play()
		countdown -= 1
		timer.start()
	elif countdown == 1:
		GameManager.isPlaying = true
		start_game_timer()
		green_light_sound.play()
		green_go.texture = green_on_texture
		red_two.texture = red_off_texture
		red_one.texture = red_off_texture
		timer.start()
		countdown -= 1
	else:
		green_go.texture = green_off_texture
		start_lights.visible = false
		countdown = 3

func _on_timer_timeout() -> void:
	triggerStartLights()

func start_game_timer():
	timer_2.start()
	should_show_time = true

func stop_timer():
	timer_2.stop()
