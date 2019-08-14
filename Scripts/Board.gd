extends Spatial

# warning-ignore:unused_class_variable
export var flipDuration = 0.3
# warning-ignore:unused_class_variable
export var flipHeight = 2

var stoneInstance = preload("res://Scenes/Stone.tscn")
var legalMoveInstance = preload("res://Scenes/LegalMove.tscn")

onready var blackScore = get_parent().get_node("Scores/Black Score/Number")
onready var whiteScore = get_parent().get_node("Scores/White Score/Number")

var gameBoard = []
const SIZE = 8;

var currentPlayer = "Black"
var currentLegalMoves = []
var currentFlippedStones = []

func place_stone_at(row : int, col : int, sideUp : String, board):
	var stone = board[row][col]
	stone.set_translation(Vector3(col - 3.5, 0, row - 3.5))
	stone.sideUp = sideUp
	if sideUp == "White": stone.set_rotation_degrees(Vector3(180, 0, 0))
	add_child(stone)
	
	return stone

func _ready():
	for row in range(SIZE):
		gameBoard.append([])
		for col in range(SIZE):
			var stone = stoneInstance.instance()
			stone.row = row
			stone.col = col
			gameBoard[row].append(stone)
	
	place_stone_at(3, 3, "White", gameBoard)
	place_stone_at(4, 4, "White", gameBoard)
	place_stone_at(3, 4, "Black", gameBoard)
	place_stone_at(4, 3, "Black", gameBoard)
	
	go_to_turn(currentPlayer)

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

func enemy_of(player : String):
	match player:
		"Black": return "White"
		"White": return "Black"

func search_for_move(direction : String, rootStone : MeshInstance, var board):
	var surroundingStones = neighbors_of(rootStone, board)
	if not surroundingStones.has(direction):
		return
	
	var enemy = ""
	match rootStone.sideUp:
		"Black": enemy = "White"
		"White": enemy = "Black"
	
	var surroundingStone = surroundingStones[direction]
	if surroundingStone.sideUp == enemy:
		var nextStones = neighbors_of(surroundingStone, board)
		if not nextStones.has(direction):
			return
		
		while nextStones[direction].sideUp == enemy:
			var otherSurroundingStones = neighbors_of(nextStones[direction], board)
			if not otherSurroundingStones.has(direction): return
			nextStones[direction] = otherSurroundingStones[direction]
		
		if nextStones[direction].sideUp == "":
			var oppositeDirection = ""
			match direction:
				"NORTH": oppositeDirection = "SOUTH"
				"SOUTH": oppositeDirection = "NORTH"
				"WEST": oppositeDirection = "EAST"
				"EAST": oppositeDirection = "WEST"
				"NORTHWEST": oppositeDirection = "SOUTHEAST"
				"SOUTHEAST": oppositeDirection = "NORTHWEST"
				"NORTHEAST": oppositeDirection = "SOUTHWEST"
				"SOUTHWEST": oppositeDirection = "NORTHEAST"
			
			nextStones[direction].flankDirections.append(oppositeDirection)
			return nextStones[direction]
	
func get_legal_moves(player : String, board):
	var stones = []
	for i in range(SIZE):
		for j in range(SIZE):
			if board[i][j].sideUp == player:
				stones.append(board[i][j])
		
	var directions = ["NORTH", "SOUTH", "WEST", "EAST", "NORTHWEST", "NORTHEAST", "SOUTHWEST", "SOUTHEAST"]
	var legalMoves = []
	for stone in stones:
		for direction in directions:
			var search = search_for_move(direction, stone, board)
			if search != null and not legalMoves.has(search):
				legalMoves.append(search)
		
	return legalMoves

func show_legal_moves(moves):
	for move in moves:
		var legalMove = legalMoveInstance.instance()
		legalMove.row = move.row
		legalMove.col = move.col
		legalMove.set_translation(Vector3(legalMove.col - 3.5, 0, legalMove.row - 3.5))
		
		add_child(legalMove)

func go_to_turn(player : String):
	currentFlippedStones.clear()
	
	blackScore.text = String(count("Black", gameBoard))
	whiteScore.text = String(count("White", gameBoard))
	
	currentPlayer = player
	currentLegalMoves = get_legal_moves(currentPlayer, gameBoard)
	show_legal_moves(currentLegalMoves)

func count(player : String, board):
	var total = 0
	for i in range(SIZE):
		for j in range(SIZE):
			if board[i][j].sideUp == player:
				total += 1
	
	return total

# warning-ignore:unused_argument
func _process(delta):
	if len(currentFlippedStones) > 0:
		for stone in currentFlippedStones:
			if not stone.flipped:
				return
		go_to_turn(enemy_of(currentPlayer))