extends HBoxContainer

onready var globals = get_tree().get_root().get_node("/root/globals")

onready var gamePlay = preload("res://Scenes/GamePlay.tscn")

onready var darkController = get_node("Dark/Controller")
onready var lightController = get_node("Light/Controller")

onready var darkSelectionDirection = get_node("Dark/Selection Direction")
onready var lightSelectionDirection = get_node("Light/Selection Direction")

func opposite_of(controller : String):
	match controller:
		"PLAYER": return "CPU"
		"CPU": return "PLAYER"

func _ready():
	if globals.darkAI:
		darkController.text = "CPU"
	else:
		darkController.text = "PLAYER"
	
	if globals.lightAI:
		lightController.text = "CPU"
	else:
		lightController.text = "PLAYER"
	
	darkSelectionDirection.text = "TAP BUTTON\nFOR\n" + opposite_of(darkController.text)
	lightSelectionDirection.text = "TAP BUTTON\nFOR\n" + opposite_of(lightController.text)
	
func change_dark_controller():
	match darkController.text:
		"PLAYER":
			darkController.text = "CPU"
			globals.darkAI = true
		"CPU": 
			darkController.text = "PLAYER"
			globals.darkAI = false
	
	darkSelectionDirection.text = "TAP BUTTON\nFOR\n" + opposite_of(darkController.text)

func change_light_controller():
	match lightController.text:
		"PLAYER": 
			lightController.text = "CPU"
			globals.lightAI = true
		"CPU": 
			lightController.text = "PLAYER"
			globals.lightAI = false
	
	lightSelectionDirection.text = "TAP BUTTON\nFOR\n" + opposite_of(lightController.text)

func play_game():
	get_tree().change_scene_to(gamePlay)
