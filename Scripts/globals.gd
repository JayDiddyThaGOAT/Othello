extends Node

var darkAI : bool = false
var lightAI : bool = false

var aiDifficulty : int = 2

onready var mainMenu = preload("res://Scenes/StartScene.tscn")
onready var gamePlay = preload("res://Scenes/GamePlay.tscn")
onready var legalMove = preload("res://Scenes/LegalMove.tscn")
onready var stone = preload("res://Scenes/Stone.tscn")

onready var normSpaceTexture = preload("res://Sprites/Space.png")
onready var darkSpaceTexture = preload("res://Sprites/DarkSpace.png")