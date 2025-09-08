extends Control

## WelcomeScreen - Main entry point for the game
## Clean base for adding welcome UI elements

func _ready():
	print("Welcome screen loaded - ready for UI elements")

func _input(event):
	# Placeholder for navigation input
	if event.is_action_pressed("ui_accept"):
		print("Welcome screen: Accept pressed - ready for navigation logic")
	
	if event.is_action_pressed("ui_cancel"):
		print("Welcome screen: Cancel pressed - ready for exit logic")
