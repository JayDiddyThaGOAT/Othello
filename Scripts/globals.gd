extends Node

# warning-ignore:unused_class_variable
var currentRound : int = 1

# warning-ignore:unused_class_variable
var darkAI : bool = false
# warning-ignore:unused_class_variable
var lightAI : bool = true
# warning-ignore:unused_class_variable
var aiLosses : int = 0
# warning-ignore:unused_class_variable
onready var aiFlags = [true, false, false]
# warning-ignore:unused_class_variable
onready var values =  [[ 120, -20,  20,  5,  5, -20,  20, 120],
					   [ -20, -40,  -5, -5, -5,  -5, -40, -20],
					   [  20,  -5,  15,  3,  3,  15,  -5,  20],
					   [   5,  -5,   3,  3,  3,   3,  -5,   5],
					   [   5,  -5,   3,  3,  3,   3,  -5,   5],
					   [  20,  -5,  15,  3,  3,  15,  -5,  20],
					   [ -20, -40,  -5, -5, -5,  -5, -40, -20],
					   [ 120, -20,  20,  5,  5, -20,  20, 120]]

# warning-ignore:unused_class_variable
onready var mainMenu = preload("res://Scenes/StartScene.tscn")
# warning-ignore:unused_class_variable
onready var gamePlay = preload("res://Scenes/GamePlay.tscn")
# warning-ignore:unused_class_variable
onready var legalMove = preload("res://Scenes/LegalMove.tscn")
# warning-ignore:unused_class_variable
onready var stone = preload("res://Scenes/Stone.tscn")

# warning-ignore:unused_class_variable
onready var normSpaceTexture = preload("res://Sprites/Space.png")
# warning-ignore:unused_class_variable
onready var darkSpaceTexture = preload("res://Sprites/DarkSpace.png")