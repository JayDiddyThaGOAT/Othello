extends Node

var darkAI : bool = true
var lightAI : bool = true

var darkDifficulty : int = 1
var lightDifficulty : int = 1

onready var mainMenu = preload("res://Scenes/StartScene.tscn")
onready var gamePlay = preload("res://Scenes/GamePlay.tscn")
onready var legalMove = preload("res://Scenes/LegalMove.tscn")
onready var stone = preload("res://Scenes/Stone.tscn")

onready var normSpaceTexture = preload("res://Sprites/Space.png")
onready var darkSpaceTexture = preload("res://Sprites/DarkSpace.png")