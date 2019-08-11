extends Area

onready var switchTimer = get_node("Timer")
onready var game = get_parent()
onready var gameBoard = game.gameBoard
onready var currentPlayer = game.currentPlayer

var stoneInstance = preload("res://Scenes/Stone.tscn")
var row : int
var col : int

var flank = []

func _ready():
	pass
	

func apply_move(camera, event, click_position, click_normal, shape_idx):
	if event is InputEventMouseButton:
		for legalMove in get_parent().get_children():
			if legalMove.get_class() == "Area":
				legalMove.queue_free()
		
		var chosenStone = gameBoard[row][col]
		game.flip_stones_by(chosenStone, currentPlayer, gameBoard)