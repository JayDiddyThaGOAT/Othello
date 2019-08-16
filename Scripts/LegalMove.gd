extends Area

onready var game = get_parent()
onready var gameBoard = game.gameBoard
onready var currentPlayer = game.currentPlayer

onready var meshForModel = get_node("Model")
onready var material = meshForModel.mesh.surface_get_material(0).duplicate()

var row : int
var col : int
var selectable : bool
var stone

func _ready():
	stone = gameBoard[row][col]
	stone.flipStones.clear()
	
	var flankDirections = stone.flankDirections
	while len(stone.flankDirections) > 0:
		var currentDirection = stone.flankDirections.pop_front()
		var	nextStone = game.neighbors_of(stone, gameBoard)[currentDirection]
		while nextStone.sideUp == game.enemy_of(currentPlayer):
			stone.flipStones.append(nextStone)
			
			var surroundingStones = game.neighbors_of(nextStone, gameBoard)
			if not surroundingStones.has(currentDirection):
				break
			
			nextStone = game.neighbors_of(nextStone, gameBoard)[currentDirection]
	
	material.albedo_color = Color(0, 0, 0, material.albedo_color.a + ((stone.flipStones.size() - 1) * 0.1))
	meshForModel.set_surface_material(0, material)
	
# warning-ignore:unused_argument
# warning-ignore:unused_argument
# warning-ignore:unused_argument
# warning-ignore:unused_argument
func apply_move(camera, event, click_position, click_normal, shape_idx):
	if event is InputEventMouseButton and selectable:
		game.selectedStone = game.place_stone_at(stone.row, stone.col, game.currentPlayer, gameBoard)
		for stone in game.selectedStone.flipStones:
			stone.flip()