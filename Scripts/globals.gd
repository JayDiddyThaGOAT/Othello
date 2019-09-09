extends Node

var darkAI : bool = false
var lightAI : bool = true
onready var values =  [[ 120, -20,  20,  5,  5, -20,  20, 120],
					   [ -20, -40,  -5, -5, -5,  -5, -40, -20],
					   [  20,  -5,  15,  3,  3,  15,  -5,  20],
					   [   5,  -5,   3,  3,  3,   3,  -5,   5],
					   [   5,  -5,   3,  3,  3,   3,  -5,   5],
					   [  20,  -5,  15,  3,  3,  15,  -5,  20],
					   [ -20, -40,  -5, -5, -5,  -5, -40, -20],
					   [ 120, -20,  20,  5,  5, -20,  20, 120]]

onready var mainMenu = preload("res://Scenes/StartScene.tscn")
onready var gamePlay = preload("res://Scenes/GamePlay.tscn")
onready var legalMove = preload("res://Scenes/LegalMove.tscn")
onready var stone = preload("res://Scenes/Stone.tscn")

onready var normSpaceTexture = preload("res://Sprites/Space.png")
onready var darkSpaceTexture = preload("res://Sprites/DarkSpace.png")