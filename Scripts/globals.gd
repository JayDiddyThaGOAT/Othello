extends Node

var aiDifficulty : int = 2

var darkAI : bool = true
var lightAI : bool = true

onready var values =  [[ 4, -3,  2,  2,  2,  2, -3,  4],
					   [-3, -4, -1, -1, -1, -1, -4, -3],
					   [ 2, -1,  1,  0,  0,  1, -1,  2],
					   [ 2, -1,  0,  1,  1,  0, -1,  2],
					   [ 2, -1,  0,  1,  1,  0, -1,  2],
					   [ 2, -1,  1,  0,  0,  1, -1,  2],
					   [-3, -4, -1, -1, -1, -1, -4, -3],
					   [ 4, -3,  2,  2,  2,  2, -3,  4]]

onready var mainMenu = preload("res://Scenes/StartScene.tscn")
onready var gamePlay = preload("res://Scenes/GamePlay.tscn")
onready var legalMove = preload("res://Scenes/LegalMove.tscn")
onready var stone = preload("res://Scenes/Stone.tscn")

onready var normSpaceTexture = preload("res://Sprites/Space.png")
onready var darkSpaceTexture = preload("res://Sprites/DarkSpace.png")