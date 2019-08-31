extends HBoxContainer

onready var darkController = get_node("Dark/Controller")
onready var lightController = get_node("Light/Controller")

onready var darkInstructions = get_node("Dark/Instructions")
onready var lightInstructions = get_node("Light/Instructions")

func _ready():
	if not globals.darkAI:
		darkController.text = "PLAYER"
		darkInstructions.text = "TAP " + darkController.text + "\nTO BE\nCPU"
		lightInstructions.visible = true
	else:
		darkController.text = "CPU"
		darkInstructions.text = "TAP " + darkController.text + "\nTO BE\nPLAYER"
		lightInstructions.visible = false
		
	if not globals.lightAI:
		lightController.text = "PLAYER"
		lightInstructions.text = "TAP " + lightController.text + "\nTO BE\nCPU"
		darkInstructions.visible = true
	else:
		lightController.text = "CPU"
		lightInstructions.text = "TAP " + lightController.text + "\nTO BE\nPLAYER"
		darkInstructions.visible = false
	
	darkController.disabled = lightController.text == "CPU"
	lightController.disabled = darkController.text == "CPU"

func play_game():
	get_tree().change_scene_to(globals.gamePlay)

func toggle_dark_player():
	globals.darkAI = not globals.darkAI
	
	if darkController.text == "PLAYER":
		darkController.text = "CPU"
		darkInstructions.text = "TAP " + darkController.text + "\nTO BE\nPLAYER"
		lightInstructions.visible = false
	elif darkController.text == "CPU":
		darkController.text = "PLAYER"
		darkInstructions.text = "TAP " + darkController.text + "\nTO BE\nCPU"
		lightInstructions.visible = true
	
	lightController.disabled = darkController.text == "CPU"

func toggle_light_player():
	globals.lightAI = not globals.lightAI
	
	var previousPlayer = lightController.text
	if lightController.text == "PLAYER":
		lightController.text = "CPU"
		lightInstructions.text = "TAP " + lightController.text + "\nTO BE\nPLAYER"
		darkInstructions.visible = false
	elif lightController.text == "CPU":
		lightController.text = "PLAYER"
		lightInstructions.text = "TAP " + lightController.text + "\nTO BE\nCPU"
		darkInstructions.visible = true
	
	darkController.disabled = lightController.text == "CPU"