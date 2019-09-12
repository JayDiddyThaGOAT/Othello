extends HBoxContainer

onready var darkController = get_node("Dark/Controller")
onready var lightController = get_node("Light/Controller")

onready var darkInstructions = get_parent().get_node("Dark Instruction")
onready var lightInstructions = get_parent().get_node("Light Instruction")

func _ready():
	if not globals.darkAI:
		darkController.text = "PLAYER"
		darkInstructions.text = "TAP FOR CPU"
		lightInstructions.visible = true
	else:
		darkController.text = "CPU"
		darkInstructions.text = "TAP FOR PLAYER"
		lightInstructions.visible = false
		
	if not globals.lightAI:
		lightController.text = "PLAYER"
		lightInstructions.text = "TAP FOR CPU"
		darkInstructions.visible = true
	else:
		lightController.text = "CPU"
		lightInstructions.text = "TAP FOR PLAYER"
		darkInstructions.visible = false
	
	darkController.disabled = lightController.text == "CPU"
	lightController.disabled = darkController.text == "CPU"
	
	for i in range(globals.aiFlags.size()):
		globals.aiFlags[i] = false

func play_game():
	get_tree().change_scene_to(globals.gamePlay)

func toggle_dark_player():
	globals.darkAI = not globals.darkAI
	
	if darkController.text == "PLAYER":
		darkController.text = "CPU"
		darkInstructions.text = "TAP FOR PLAYER"
		lightInstructions.visible = false
	elif darkController.text == "CPU":
		darkController.text = "PLAYER"
		darkInstructions.text = "TAP FOR CPU"
		lightInstructions.visible = true
	
	lightController.disabled = darkController.text == "CPU"

func toggle_light_player():
	globals.lightAI = not globals.lightAI
	
	var previousPlayer = lightController.text
	if lightController.text == "PLAYER":
		lightController.text = "CPU"
		lightInstructions.text = "TAP FOR PLAYER"
		darkInstructions.visible = false
	elif lightController.text == "CPU":
		lightController.text = "PLAYER"
		lightInstructions.text = "TAP FOR CPU"
		darkInstructions.visible = true
	
	darkController.disabled = lightController.text == "CPU"