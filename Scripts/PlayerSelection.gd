extends HBoxContainer

onready var darkController = get_node("Dark/Controller")
onready var lightController = get_node("Light/Controller")

onready var darkInstructions = get_node("Dark/Instructions")
onready var lightInstructions = get_node("Light/Instructions")

func _ready():
	if darkController.text == "PLAYER" and globals.darkAI or darkController.text == "CPU" and not globals.darkAI:
		toggle_dark_player()
	
	if lightController.text == "PLAYER" and globals.lightAI or lightController.text == "CPU" and not globals.lightAI:
		toggle_light_player() 

func play_game():
	get_tree().change_scene_to(globals.gamePlay)

func toggle_dark_player():
	globals.darkAI = not globals.darkAI
	
	var previousPlayer = darkController.text
	if darkController.text == "PLAYER":
		darkController.text = "CPU"
		darkInstructions.text = "TAP " + darkController.text + "\nTO BE\n" + previousPlayer
		lightInstructions.visible = false
	elif darkController.text == "CPU":
		darkController.text = "PLAYER"
		darkInstructions.text = "TAP " + darkController.text + "\nTO BE\n" + previousPlayer
		lightInstructions.visible = true
	
	lightController.disabled = darkController.text == "CPU"

	
func toggle_light_player():
	globals.lightAI = not globals.lightAI
	
	var previousPlayer = lightController.text
	if lightController.text == "PLAYER":
		lightController.text = "CPU"
		lightInstructions.text = "TAP " + lightController.text + "\nTO BE\n" + previousPlayer
		darkInstructions.visible = false
	elif lightController.text == "CPU":
		lightController.text = "PLAYER"
		lightInstructions.text = "TAP " + lightController.text + "\nTO BE\n" + previousPlayer
		darkInstructions.visible = true
	
	darkController.disabled = lightController.text == "CPU"