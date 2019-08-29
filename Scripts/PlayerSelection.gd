extends HBoxContainer

onready var darkController = get_node("Dark/Controller")
onready var lightController = get_node("Light/Controller")

onready var darkDifficultyOptions = get_node("Dark/AI Difficulty/Options")
onready var lightDifficultyOptions = get_node("Light/AI Difficulty/Options")

onready var darkPlayerOptions = darkController.get_node("Options")
onready var lightPlayerOptions = lightController.get_node("Options")

onready var darkSlider = darkController.get_node("Slider")
onready var lightSlider = lightController.get_node("Slider")

onready var darkDifficultySilder = darkDifficultyOptions.get_parent().get_node("Slider")
onready var lightDifficultySlider = lightDifficultyOptions.get_parent().get_node("Slider")


var dark = Color(0, 0, 0)
var light = Color(1, 1, 1)

func _ready():
	if globals.darkAI:
		update_dark_player(1)
	else:
		update_light_player(0)
	
	if globals.lightAI:
		update_light_player(1)
	else:
		update_light_player(0)

func update_dark_player(to : int):
	if to == 0:
		globals.darkAI = false
		darkDifficultyOptions.get_parent().visible = false
		
		darkPlayerOptions.get_node("Player").add_color_override("font_color", dark)
		darkPlayerOptions.get_node("CPU").add_color_override("font_color", light)
	elif to == 1:
		globals.darkAI = true
		darkDifficultyOptions.get_parent().visible = true
		darkPlayerOptions.get_node("Player").add_color_override("font_color", light)
		darkPlayerOptions.get_node("CPU").add_color_override("font_color", dark)
	
	darkSlider.value = to

func update_light_player(to : int):
	lightSlider.value = to
	globals.lightDifficulty = to
	
	if to == 0:
		globals.lightAI = false
		lightDifficultyOptions.get_parent().visible = false
		
		lightPlayerOptions.get_node("Player").add_color_override("font_color", light)
		lightPlayerOptions.get_node("CPU").add_color_override("font_color", dark)
	elif to == 1:
		globals.lightAI = true
		lightDifficultyOptions.get_parent().visible = true
		
		lightPlayerOptions.get_node("Player").add_color_override("font_color", dark)
		lightPlayerOptions.get_node("CPU").add_color_override("font_color", light)
	

func update_dark_difficulty(to : int):
	if to == -1:
		darkDifficultyOptions.get_node("Easy").add_color_override("font_color", dark)
		darkDifficultyOptions.get_node("Hard").add_color_override("font_color", light)
	elif to == 0:
		darkDifficultyOptions.get_node("Easy").add_color_override("font_color", light)
		darkDifficultyOptions.get_node("Hard").add_color_override("font_color", dark)
	
	globals.darkDifficulty = to
	
func update_light_difficulty(to : int):
	if to == -1:
		lightDifficultyOptions.get_node("Easy").add_color_override("font_color", light)
		lightDifficultyOptions.get_node("Hard").add_color_override("font_color", dark)
	elif to == 0:
		lightDifficultyOptions.get_node("Easy").add_color_override("font_color", dark)
		lightDifficultyOptions.get_node("Hard").add_color_override("font_color", light)
	
	globals.lightDifficulty = to
	

func play_game():
	get_tree().change_scene_to(globals.gamePlay)