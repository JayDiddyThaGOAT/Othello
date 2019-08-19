extends MeshInstance

const SIZE = 8

onready var stoneInstance = preload("res://Scenes/Stone.tscn")
onready var legalMoveInstance = preload("res://Scenes/LegalMove.tscn")

onready var normSpaceTexture = preload("res://Sprites/Space.png")
onready var darkSpaceTexture = preload("res://Sprites/DarkSpace.png")

onready var darkScore = get_parent().get_node("Scores/Dark")
onready var lightScore = get_parent().get_node("Scores/Light")

var gameBoard : Array = []

var currentPlayer : String

func get_stone_on(row : int, col : int, board):
	if row < 0 or row > SIZE or col < 0 or col > SIZE:
		return
	
	for stone in board:
		if stone.row == row and stone.col == col:
			return stone

func place_stone(row : int, col : int, sideUp : String, board):
	var stone = get_stone_on(row, col, board)
	
	stone.sideUp = sideUp
	match sideUp:
		"Dark": stone.set_rotation_degrees(Vector3(0, 0, 0))
		"Light": stone.set_rotation_degrees(Vector3(-180, 0, 0))
	
	stone.set_translation(Vector3(col - 3.5, 0, row - 3.5))
	add_child(stone)
	return stone

func neighbors_of(stone, board):
	var neighbors = {}

	if stone.row - 1 >= 0: neighbors["NORTH"] = get_stone_on(stone.row - 1, stone.col, board)
	if stone.row + 1 < SIZE: neighbors["SOUTH"] = get_stone_on(stone.row + 1, stone.col, board)
	if stone.col - 1 >= 0: neighbors["WEST"] = get_stone_on(stone.row, stone.col - 1, board)
	if stone.col + 1 < SIZE: neighbors["EAST"] = get_stone_on(stone.row, stone.col + 1, board)
	
	
	if stone.row - 1 >= 0 and stone.col - 1 >= 0: neighbors["NORTHWEST"] = get_stone_on(stone.row - 1, stone.col - 1, board)
	if stone.row - 1 >= 0 and stone.col + 1 < SIZE: neighbors["NORTHEAST"] = get_stone_on(stone.row - 1, stone.col + 1, board)
	if stone.row + 1 < SIZE and stone.col - 1 >= 0: neighbors["SOUTHWEST"] = get_stone_on(stone.row + 1, stone.col - 1, board)
	if stone.row + 1 < SIZE and stone.col + 1 < SIZE: neighbors["SOUTHEAST"] = get_stone_on(stone.row + 1, stone.col + 1, board)
	
	return neighbors

func create_legal_move(row : int, col : int):
	var legalMove = legalMoveInstance.instance()
	legalMove.row = row
	legalMove.col = col
	legalMove.set_translation(Vector3(col - 3.5, 0, row - 3.5))
	return legalMove

func found_move(move, legalMoves):
	for legalMove in legalMoves:
		if move.row == legalMove.row and move.col == legalMove.col:
			return true
	
	return false

func get_legal_moves_for(player : String, board):
	var legalMoves = []
	var directions = ["NORTH", "SOUTH", "WEST", "EAST", "NORTHWEST", "NORTHEAST", "SOUTHWEST", "SOUTHEAST"]
	for stone in board:
		if stone.sideUp == player:
			for direction in directions:
				var search = search_for_move(direction, stone, board)
				if search != null and not found_move(search, legalMoves):
					legalMoves.append(search)
	
	return legalMoves

func search_for_move(direction : String, rootStone : MeshInstance, var board):
	var surroundingStones = neighbors_of(rootStone, board)
	if not surroundingStones.has(direction):
		return
	
	var surroundingStone = surroundingStones[direction]
	if surroundingStone.sideUp == enemy_of(rootStone.sideUp):
		var nextStones = neighbors_of(surroundingStone, board)
		if not nextStones.has(direction):
			return
		
		while nextStones[direction].sideUp == enemy_of(rootStone.sideUp):
			var otherSurroundingStones = neighbors_of(nextStones[direction], board)
			if not otherSurroundingStones.has(direction): return
			nextStones[direction] = otherSurroundingStones[direction]
		
		if nextStones[direction].sideUp == "":
			return create_legal_move(nextStones[direction].row, nextStones[direction].col)

func enemy_of(player : String):
	match player:
		"Dark": return "Light"
		"Light": return "Dark"

func count(player : String, board):
	var total = 0
	for stone in board:
		if stone.sideUp == player:
			total += 1
	return total

func get_winner_from(board):
	var blackCount = count("Dark", board)
	var whiteCount = count("Light", board)
	
	if blackCount > whiteCount:
		return "Dark"
	elif blackCount < whiteCount:
		return "Light"

func begin_turn(player : String):
	darkScore.get_node("Score/Number").text = String(count("Dark", gameBoard))
	lightScore.get_node("Score/Number").text = String(count("Light", gameBoard))
	
	var repeatedTurn = false
	
	currentPlayer = player
	var currentLegalMoves = get_legal_moves_for(currentPlayer, gameBoard)
	if currentLegalMoves.size() <= 0:
		currentLegalMoves = get_legal_moves_for(enemy_of(currentPlayer), gameBoard)
		if currentLegalMoves.size() <= 0:
			match get_winner_from(gameBoard):
				"Dark":
					darkScore.get_node("Score/Space").texture = darkSpaceTexture
					lightScore.get_node("Score/Space").texture = normSpaceTexture
					
					darkScore.get_node("Turn Summary").text = "WINNER\n"
					lightScore.get_node("Turn Summary").text = "LOSER\n"
				"Light":
					lightScore.get_node("Score/Space").texture = darkSpaceTexture
					darkScore.get_node("Score/Space").texture = normSpaceTexture
					
					lightScore.get_node("Turn Summary").text = "WINNER\n"
					darkScore.get_node("Turn Summary").text = "LOSER\n"
					
			return
		else:
			currentPlayer = enemy_of(player)
			repeatedTurn = true
	
	match currentPlayer:
		"Dark":
			darkScore.get_node("Score/Space").texture = darkSpaceTexture
			lightScore.get_node("Score/Space").texture = normSpaceTexture
			
			if not repeatedTurn: darkScore.get_node("Turn Summary").text = "YOUR TURN\n"
			else: darkScore.get_node("Turn Summary").text = "YOUR TURN\nAGAIN"
			
			lightScore.get_node("Turn Summary").text = "\n"
		"Light":
			lightScore.get_node("Score/Space").texture = darkSpaceTexture
			darkScore.get_node("Score/Space").texture = normSpaceTexture
			
			if not repeatedTurn: lightScore.get_node("Turn Summary").text = "YOUR TURN\n"
			else: lightScore.get_node("Turn Summary").text = "YOUR TURN\nAGAIN"
			
			darkScore.get_node("Turn Summary").text = "\n"
	
	place_legal_moves(currentLegalMoves)

func place_legal_moves(moves):
	for move in moves:
		add_child(move)

func calculate_score(player, board):
	var score = 0
	
	#Evaulate disc count
	score += count(player, board) / 100
	score -= count(enemy_of(player), board) / 100
	
	#Evaulate legal moves
	score += len(get_legal_moves_for(player, board))
	score -= len(get_legal_moves_for(enemy_of(player), board))
	
	#Evaulate corners captured
	var corners = [	get_stone_on(0, 0, board), 
					get_stone_on(0, SIZE - 1, board), 
					get_stone_on(SIZE - 1, 0, board), 
					get_stone_on(SIZE - 1, SIZE - 1, board)]
	var playerCornersCount = 0
	var enemyCornersCount = 0
	for corner in corners:
		if corner.sideUp == player:
			playerCornersCount += 1
		elif corner.sideUp == enemy_of(player):
			enemyCornersCount += 1
	
	score += 10 * playerCornersCount
	score -= 10 * enemyCornersCount
	
	return score



func _ready():
	for row in range(SIZE):
		for col in range(SIZE):
			var stone = stoneInstance.instance()
			stone.row = row
			stone.col = col
			stone.sideUp = ""
			gameBoard.append(stone)
	
	place_stone(3, 3, "Light", gameBoard)
	place_stone(4, 4, "Light", gameBoard)
	place_stone(3, 4, "Dark", gameBoard)
	place_stone(4, 3, "Dark", gameBoard)
	
	begin_turn("Dark")