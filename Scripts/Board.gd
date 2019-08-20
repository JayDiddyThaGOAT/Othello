extends MeshInstance

const SIZE = 8
const DIRECTIONS = ["NORTH", "SOUTH", "WEST", "EAST", "NORTHWEST", "NORTHEAST", "SOUTHWEST", "SOUTHEAST"]

export var darkAI = false
export var lightAI = true

onready var stoneInstance = preload("res://Scenes/Stone.tscn")
onready var legalMoveInstance = preload("res://Scenes/LegalMove.tscn")

onready var normSpaceTexture = preload("res://Sprites/Space.png")
onready var darkSpaceTexture = preload("res://Sprites/DarkSpace.png")

onready var darkScore = get_parent().get_node("Scores/Dark")
onready var lightScore = get_parent().get_node("Scores/Light")

var gameBoard : Array = []
var currentPlayer : String = "Dark"

var scoreThread

func _ready():
	for row in range(SIZE):
		gameBoard.append([])
		for col in range(SIZE):
			gameBoard[row].append(null)
	
	place_stone(3, 3, "Light", gameBoard)
	place_stone(4, 4, "Light", gameBoard)
	place_stone(3, 4, "Dark", gameBoard)
	place_stone(4, 3, "Dark", gameBoard)
	
	update_scores()
	begin_turn(currentPlayer)

func create_board_based_on(board : Array):
	var copy : Array = []
	for row in range(SIZE):
		copy.append([])
		for col in range(SIZE):
			if board[row][col] == null:
				copy[row].append(null)
			else:
				copy[row].append(board[row][col])
	
	return copy

func update_scores():
	darkScore.get_node("Score/Number").text = String(count("Dark", gameBoard))
	lightScore.get_node("Score/Number").text = String(count("Light", gameBoard))

func calculate_score(player, board):
	var score = 0
	
	#Evaulate disc count
	score += count(player, board) / 100
	score -= count(enemy_of(player), board) / 100
	
	#Evaulate legal moves
	score += len(get_legal_moves_from(player, board))
	score -= len(get_legal_moves_from(enemy_of(player), board))
	
	#Evaulate corners captured
	var corners = [	board[0][0], board[0][SIZE - 1], board[SIZE - 1][0], board[SIZE - 1][SIZE - 1]	]
	var playerCornersCount = 0
	var enemyCornersCount = 0
	for corner in corners:
		if corner == null:
			continue
		
		if corner.sideUp == player:
			playerCornersCount += 1
		elif corner.sideUp == enemy_of(player):
			enemyCornersCount += 1
	
	score += 10 * playerCornersCount
	score -= 10 * enemyCornersCount
	
	return score

func count(player : String, board):
	var total = 0
	for row in range(SIZE):
		for col in range(SIZE):
			var stone = board[row][col]
			if stone == null:
				continue
			
			if stone.sideUp == player:
				total += 1
	return total

func enemy_of(player : String):
	match player:
		"Dark" : return "Light"
		"Light": return "Dark"

func get_winner_from(board):
	var blackCount = count("Dark", board)
	var whiteCount = count("Light", board)
	
	if blackCount > whiteCount:
		return "Dark"
	elif blackCount < whiteCount:
		return "Light"
	else:
		return "Tie"

func place_stone(row : int, col : int, sideUp : String, board : Array):
	board[row][col] = stoneInstance.instance()
	board[row][col].row = row
	board[row][col].col = col
	board[row][col].set_translation(Vector3(col - 3.5, 0, row - 3.5))
	
	board[row][col].sideUp = sideUp
	match board[row][col].sideUp:
		"Dark": board[row][col].set_rotation_degrees(Vector3(0, 0, 0))
		"Light": board[row][col].set_rotation_degrees(Vector3(-180, 0, 0))
	
	add_child(board[row][col])
	return board[row][col]

func neighbors_at(row : int, col : int, board : Array):
	var neighbors = {}

	if row - 1 >= 0: neighbors["NORTH"] = board[row - 1][col]
	if row + 1 < SIZE: neighbors["SOUTH"] = board[row + 1][col]
	if col - 1 >= 0: neighbors["WEST"] = board[row][col - 1]
	if col + 1 < SIZE: neighbors["EAST"] = board[row][col + 1]
	
	if row - 1 >= 0 and col - 1 >= 0: neighbors["NORTHWEST"] = board[row - 1][col - 1]
	if row - 1 >= 0 and col + 1 < SIZE: neighbors["NORTHEAST"] = board[row - 1][col + 1]
	if row + 1 < SIZE and col - 1 >= 0: neighbors["SOUTHWEST"] = board[row + 1][col - 1]
	if row + 1 < SIZE and col + 1 < SIZE: neighbors["SOUTHEAST"] = board[row + 1][col + 1]
	
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

func search_for_move_at(direction : String, rootStone : MeshInstance, board : Array):
	var surroundingStonesAtRoot = neighbors_at(rootStone.row, rootStone.col, board)
	if not surroundingStonesAtRoot.has(direction) or surroundingStonesAtRoot[direction] == null:
		return null
	
	if surroundingStonesAtRoot[direction].sideUp == enemy_of(rootStone.sideUp):
		var currentStone = surroundingStonesAtRoot[direction]
		var row = currentStone.row
		var col = currentStone.col
		while currentStone != null and currentStone.sideUp == enemy_of(rootStone.sideUp):
			var surroundingStonesAtCurrent = neighbors_at(currentStone.row, currentStone.col, board)
			if not surroundingStonesAtCurrent.has(direction):
				break
			
			match direction:
				"NORTH": 
					row -= 1
				"SOUTH":
					row += 1
				"WEST":
					col -= 1
				"EAST":
					col += 1
				"NORTHWEST":
					row -= 1
					col -= 1
				"NORTHEAST":
					row -= 1
					col += 1
				"SOUTHWEST":
					row += 1
					col -= 1
				"SOUTHEAST":
					row += 1
					col += 1
			
			currentStone = surroundingStonesAtCurrent[direction]
		
		if currentStone == null:
			return create_legal_move(row, col)

func get_legal_moves_from(player : String, board):
	var legalMoves = []
	
	for row in range(SIZE):
		for col in range(SIZE):
			var stone = board[row][col]
			if stone == null:
				continue
			
			if stone.sideUp == player:
				for direction in DIRECTIONS:
					var search = search_for_move_at(direction, stone, board)
					if search != null and not found_move(search, legalMoves):
						legalMoves.append(search)
	
	return legalMoves

func place_legal_moves(legalMoves):
	for move in legalMoves:
		add_child(move)
	
func mini_max(board : Array, depth : int = 2, alpha : float = -INF, beta : float = INF, maxPlayer : bool = true):
	var moves
	var player
	if maxPlayer:
		moves = get_legal_moves_from(currentPlayer, board)
		player = currentPlayer
	else:
		moves = get_legal_moves_from(enemy_of(currentPlayer), board)
		player = enemy_of(currentPlayer)
	
	if depth == 0 or moves.size() <= 0:
		return calculate_score(player, board)
	
	if maxPlayer:
		var value = -INF
		for move in moves:
			var futureBoard = create_board_based_on(board)
			var stone = stoneInstance.instance()
			stone.row = move.row
			stone.col = move.col
			stone.sideUp = currentPlayer
			futureBoard[move.row][move.col] = stone
			
			value = max(value, mini_max(futureBoard, depth - 1, alpha, beta, false))
			alpha = max(alpha, value)
			
			if alpha >= beta:
				break
		return value
	else:
		var value = INF
		for move in moves:
			var futureBoard = create_board_based_on(board)
			var stone = stoneInstance.instance()
			stone.row = move.row
			stone.col = move.col
			stone.sideUp = enemy_of(currentPlayer)
			futureBoard[move.row][move.col] = stone
			
			value = min(value, mini_max(futureBoard, depth - 1, alpha, beta, true))
			beta = min(beta, value)
			
			if alpha >= beta:
				break
		
		return value

func place_best_move(moves):
	var bestMove = moves[randi() % moves.size()]
	var bestValue = -INF
	for move in moves:
		var futureBoard = create_board_based_on(gameBoard)
		var stone = stoneInstance.instance()
		stone.row = move.row
		stone.col = move.col
		stone.sideUp = currentPlayer
		futureBoard[move.row][move.col] = stone
		
		var value = mini_max(futureBoard)
		if value > bestValue:
			bestMove = move
			bestValue = value
	
	add_child(bestMove)
	return bestMove

func begin_turn(player : String):
	var repeatedTurn = false
	
	currentPlayer = player
	var currentLegalMoves = get_legal_moves_from(currentPlayer, gameBoard)
	if currentLegalMoves.size() <= 0:
		currentLegalMoves = get_legal_moves_from(enemy_of(currentPlayer), gameBoard)
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
				"Tie":
					darkScore.get_node("Score/Space").texture = darkSpaceTexture
					lightScore.get_node("Score/Space").texture = darkSpaceTexture
					
					darkScore.get_node("Turn Summary").text = "TIE\n"
					lightScore.get_node("Turn Summary").text = "TIE	\n"
					
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
	
	update_scores()
	if currentPlayer == "Dark" and not darkAI or currentPlayer == "Light" and not lightAI:
		place_legal_moves(currentLegalMoves)
	else:
		yield(get_tree().create_timer(0.1), "timeout")
		var bestMove = place_best_move(currentLegalMoves)
		bestMove.AI.start()