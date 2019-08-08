extends Spatial

var stoneInstance = preload("res://Scenes/Stone.tscn")
var legalMoveInstance = preload("res://Scenes/LegalMove.tscn")

var gameBoard = []
const SIZE = 8;

var currentPlayer = "Black"
var currentLegalMoves = []

func place_stone_at(sideUp : String, row : int, col : int, board):
	var stone = board[row][col]
	stone.set_translation(Vector3(col - 3.5, 0, row - 3.5))
	stone.sideUp = sideUp
	if sideUp == "White":
		stone.set_rotation_degrees(Vector3(180, 0, 0))
	
	add_child(stone)

func _ready():
	for col in range(SIZE):
		gameBoard.append([])
		for row in range(SIZE):
			var stone = stoneInstance.instance()
			stone.row = row
			stone.col = col
			gameBoard[col].append(stone)
	
	place_stone_at("Black", 3, 3, gameBoard)
	place_stone_at("Black", 4, 4, gameBoard)
	place_stone_at("White", 3, 4, gameBoard)
	place_stone_at("White", 4, 3, gameBoard)
	
	currentLegalMoves = legal_moves(currentPlayer, gameBoard)
	for move in currentLegalMoves:
		var legalMove = legalMoveInstance.instance()
		legalMove.set_translation(Vector3(move.col - 3.5, 0.1, move.row - 3.5))
		add_child(legalMove)

func neighbors_of(stone : MeshInstance, board):
	var neighbors = {}
	if stone.row - 1 >= 0:
		neighbors["NORTH"] = board[stone.row - 1][stone.col]
	
	if stone.row + 1 < SIZE:
		neighbors["SOUTH"] = board[stone.row + 1][stone.col]
	
	if stone.col - 1 >= 0:
		neighbors["WEST"] = board[stone.row][stone.col - 1]
	
	if stone.col + 1 < SIZE:
		neighbors["EAST"] = board[stone.row][stone.col + 1]
	
	if stone.row - 1 >= 0 and stone.col - 1 >= 0:
		neighbors["NORTHWEST"] = board[stone.row - 1][stone.col - 1]
	
	if stone.row - 1 >= 0 and stone.col + 1 < SIZE:
		neighbors["NORTHEAST"] = board[stone.row - 1][stone.col + 1]
		
	if stone.row + 1 < SIZE and stone.col - 1 >= 0:
		neighbors["SOUTHWEST"] = board[stone.row + 1][stone.col - 1]
	
	if stone.row + 1 < SIZE and stone.col + 1 < SIZE:
		neighbors["SOUTHEAST"] = board[stone.row + 1][stone.col + 1]
	
	return neighbors;

func check_directions(direction_one : String, direction_two : String, player : String, stones, legalMoves):
	if not stones.has(direction_one) or not stones.has(direction_two):
		return
	
	if legalMoves.has(stones[direction_one]) or legalMoves.has(stones[direction_two]):
		return
	
	if stones[direction_one].sideUp == player:
		if stones[direction_two].sideUp == "":
			legalMoves.append(stones[direction_two])
			return
	
	if stones[direction_two].sideUp == player:
		if stones[direction_one].sideUp == "":
			legalMoves.append(stones[direction_one])
			return
		

func legal_moves(sideUp : String, board):
	var enemy = ""
	if sideUp == "Black":
		enemy = "White"
	elif sideUp == "White":
		enemy = "Black"
	
	var enemyStones = []
	for j in range(SIZE):
		for i in range(SIZE):
			if board[i][j].sideUp == enemy:
				enemyStones.append(board[i][j])
	
	var legalMoves = []
	for stone in enemyStones:
		var surroundingStones = neighbors_of(stone, board)
		check_directions("NORTH", "SOUTH", sideUp, surroundingStones, legalMoves)
		check_directions("WEST", "EAST", sideUp, surroundingStones, legalMoves)
		check_directions("NORTHWEST", "SOUTHEAST", sideUp, surroundingStones, legalMoves)
		check_directions("NORTHEAST", "SOUTHWEST", sideUp, surroundingStones, legalMoves)
	
	return legalMoves