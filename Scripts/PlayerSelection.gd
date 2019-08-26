extends HBoxContainer

onready var globals = get_tree().get_root().get_node("/root/globals")

onready var darkController = get_node("Dark/Controller")
onready var lightController = get_node("Light/Controller")

onready var darkStoneViewer = get_node("Dark/Score/StoneContainer/StoneViewer")
onready var lightStoneViewer = get_node("Light/Score/StoneContainer/StoneViewer")

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
	
	darkSelectionDirection.text = "TAP FOR\n" + opposite_of(darkController.text)
	lightSelectionDirection.text = "TAP FOR\n" + opposite_of(lightController.text)
	
	darkStoneViewer.set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	lightStoneViewer.set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	
	var darkStoneImage = darkStoneViewer.get_texture().get_data()
	var lightStoneImage = lightStoneViewer.get_texture().get_data()
	
	darkStoneImage.flip_y()
	lightStoneImage.flip_y()
	
	darkStoneImage.save_png("res://Sprites/DarkStone.png")
	lightStoneImage.save_png("res://Sprites/LightStone.png")
	
func change_dark_controller():
	match darkController.text:
		"PLAYER":
			darkController.text = "CPU"
			globals.darkAI = true
		"CPU": 
			darkController.text = "PLAYER"
			globals.darkAI = false
	
	darkSelectionDirection.text = "TAP FOR\n" + opposite_of(darkController.text)

func change_light_controller():
	match lightController.text:
		"PLAYER": 
			lightController.text = "CPU"
			globals.lightAI = true
		"CPU": 
			lightController.text = "PLAYER"
			globals.lightAI = false
	
	lightSelectionDirection.text = "TAP FOR\n" + opposite_of(lightController.text)

func play_game():
	get_tree().change_scene_to(globals.gamePlay)
