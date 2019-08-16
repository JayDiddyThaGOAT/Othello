extends Area

onready var game = get_parent()
onready var gameBoard = game.gameBoard
onready var currentPlayer = game.currentPlayer

onready var meshForModel = get_node("Model")
onready var material = meshForModel.mesh.surface_get_material(0).duplicate()

var row : int
var col : int
var stone

var flipStones = []

func _ready():
	stone = gameBoard[row][col]
	while len(stone.flankDirections) > 0:
		var currentDirection = stone.flankDirections.pop_front()
		var	nextStone = game.neighbors_of(stone, gameBoard)[currentDirection]
		while nextStone.sideUp == game.enemy_of(currentPlayer):
			flipStones.append(nextStone)
			
			var surroundingStones = game.neighbors_of(nextStone, gameBoard)
			if not surroundingStones.has(currentDirection):
				break
			
			nextStone = game.neighbors_of(nextStone, gameBoard)[currentDirection]
	
	material.albedo_color = Color(0, 0, 0, material.albedo_color.a + ((flipStones.size() - 1) * 0.1))
	meshForModel.set_surface_material(0, material)
	
# warning-ignore:unused_argument
# warning-ignore:unused_argument
# warning-ignore:unused_argument
# warning-ignore:unused_argument
func apply_move(camera, event, click_position, click_normal, shape_idx):
	if event is InputEventMouseButton:
		for legalMove in get_parent().get_children():
			if legalMove.get_class() == "Area":
				legalMove.queue_free()
		
		var selectedStone = game.place_stone_at(row, col, game.currentPlayer, gameBoard)
		var stoneLight = game.stoneLightInstance.instance()
		stoneLight.set_translation(Vector3(selectedStone.get_translation().x, stoneLight.omni_range / 2, selectedStone.get_translation().z))
		selectedStone.light = stoneLight
		get_parent().add_child(stoneLight)
		
		game.currentFlippedStones = flipStones
		for stone in flipStones:
			stone.flip()