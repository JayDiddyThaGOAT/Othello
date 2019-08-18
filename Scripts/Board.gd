extends Spatial

const PositiveInfinity = 3.402823e+38
const NegativeInfinity = -2.802597e-45

export var blackAI = false
export var whiteAI = true
export var aiWaitTime = 0.5

# warning-ignore:unused_class_variable
export var flipDuration = 0.3
# warning-ignore:unused_class_variable
export var flipHeight = 2

var stoneInstance = preload("res://Scenes/Stone.tscn")
var legalMoveInstance = preload("res://Scenes/LegalMove.tscn")

var spaceTexture = preload("res://Sprites/Space.png")
var darkSpaceTexture = preload("res://Sprites/DarkSpace.png")

onready var turnSummary = get_parent().get_node("Turn Summary")

onready var blackScore = get_parent().get_node("Scores/Black Disc/Score")
onready var whiteScore = get_parent().get_node("Scores/White Disc/Score")

var gameBoard = []
const SIZE = 8;

var currentPlayer = "Black"
var currentLegalMoves = []

var selectedMove : Area
var selectedStone : MeshInstance

func place_stone_at(row : int, col : int, sideUp : String, board):
	if currentLegalMoves.size() > 0:
		currentLegalMoves.clear()
		for legalMove in get_children():
			if legalMove.get_class() == "Area":
				legalMove.queue_free()
	
	var stone = board[row][col]
	stone.set_translation(Vector3(col - 3.5, 0, row - 3.5))
	stone.sideUp = sideUp
	if sideUp == "White": stone.set_rotation_degrees(Vector3(-180, 0, 0))
	add_child(stone)
	
	return stone

func create_board():
	var board = []
	for row in range(SIZE):
		board.append([])
		for col in range(SIZE):
			var stone = stoneInstance.instance()
			stone.row = row
			stone.col = col
			board[row].append(stone)
	
	return board
func _ready():
	gameBoard = create_board()
	
	place_stone_at(3, 3, "White", gameBoard)
	place_stone_at(4, 4, "White", gameBoard)
	place_stone_at(3, 4, "Black", gameBoard)
	place_stone_at(4, 3, "Black", gameBoard)
	
	randomize()
	
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

func create_legal_move(location):
	var legalMove = legalMoveInstance.instance()
	legalMove.row = location.row
	legalMove.col = location.col
	legalMove.set_translation(Vector3(location.col - 3.5, 0, location.row - 3.5))
		
	if currentPlayer == "Black":
		legalMove.selectable = not blackAI
	elif currentPlayer == "White":
		legalMove.selectable = not whiteAI
		
	add_child(legalMove)
	
	return legalMove

func show_legal_moves(moves):
	for move in moves:
		create_legal_move(move)

func get_winner(board):
	var blackDiscs = count("Black", board)
	var whiteDiscs = count("White", board)
	
	if blackDiscs > whiteDiscs:
		return "Black"
	elif blackDiscs < whiteDiscs:
		return "White"
	
	return "Tie"

func go_to_turn(player : String):
	selectedStone = null
	
	currentPlayer = player
	currentLegalMoves = get_legal_moves(currentPlayer, gameBoard)
	var repeatedTurn = false
	if currentLegalMoves.size() <= 0:
		var enemyLegalMoves = get_legal_moves(enemy_of(currentPlayer), gameBoard)
		if enemyLegalMoves.size() <= 0:
			var winner = get_winner(gameBoard)
			turnSummary.text = winner.to_upper() + " WON"
			match winner:
				"Black": turnSummary.add_color_override("font_color", Color.black)
				"White": turnSummary.add_color_override("font_color", Color.white)
			return
		else:
			repeatedTurn = true
			currentPlayer = enemy_of(currentPlayer)
			currentLegalMoves = enemyLegalMoves
			
			turnSummary.text = currentPlayer.to_upper() + "'S TURN\nAGAIN"
	else:
		turnSummary.text = currentPlayer.to_upper() + "'S TURN"
	
	var playerScore = null
	var enemyScore = null
	if currentPlayer == "Black":
		playerScore = blackScore
		enemyScore = whiteScore
		turnSummary.add_color_override("font_color", Color.black)
	elif currentPlayer == "White":
		playerScore = whiteScore
		enemyScore = blackScore
		turnSummary.add_color_override("font_color", Color.white)
	
		
	playerScore.get_node("Space").texture = darkSpaceTexture
	enemyScore.get_node("Space").texture = spaceTexture
	
	blackScore.get_node("Number").text = String(count("Black", gameBoard))
	whiteScore.get_node("Number").text = String(count("White", gameBoard))
	
	if blackAI and currentPlayer == "Black" or whiteAI and currentPlayer == "White":
		var selectingMove = Timer.new()
		selectingMove.wait_time = aiWaitTime
		selectingMove.one_shot = true
		add_child(selectingMove)
		selectingMove.start()
		selectingMove.connect("timeout", self, "find_ai_move")
		yield(selectingMove, "timeout")
		selectingMove.queue_free()
	else:
		show_legal_moves(currentLegalMoves)

func calculate_score(player, board):
	var score = 0
	
	#Evaulate disc count
	score += count(player, board) / 100
	score -= count(enemy_of(player), board) / 100
	
	#Evaulate legal moves
	score += len(get_legal_moves(player, board))
	score -= len(get_legal_moves(enemy_of(player), board))
	
	#Evaulate corners captured
	var corners = [board[0][0], board[0][SIZE - 1], board[SIZE - 1][0], board[SIZE - 1][SIZE - 1]]
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
	
func mini_max(board, depth=3, alpha=NegativeInfinity, beta=PositiveInfinity, maxPlayer=true):
	var moves
	if maxPlayer == true:
		moves = get_legal_moves(currentPlayer, board)
	else:
		moves = get_legal_moves(enemy_of(currentPlayer), board)
	
	if depth == 0 or moves.size() <= 0:
		return calculate_score(currentPlayer, board)
	
	var value = 0
	if maxPlayer:
		value = NegativeInfinity
		for move in moves:
			var futureBoard = board.duplicate(true)
			futureBoard[move.row][move.col].sideUp = currentPlayer
			
			value = max(value, mini_max(futureBoard, depth - 1, alpha, beta, false))
			alpha = max(alpha, value)
			
			if alpha >= beta:
				break
		return value
	else:
		value = PositiveInfinity
		for move in moves:
			var futureBoard = board.duplicate(true)
			futureBoard[move.row][move.col].sideUp = enemy_of(currentPlayer)
			
			value = min(value, mini_max(futureBoard, depth - 1, alpha, beta, true))
			beta = min(beta, value)
			
			if alpha >= beta:
				break
		
		return value

func pick_best_move(moves, board):
	var bestMove = moves[randi() % moves.size()]
	var bestValue = NegativeInfinity
	
	for move in moves:
		var futureBoard = board.duplicate(true)
		futureBoard[move.row][move.col].sideUp = currentPlayer
		
		var value = mini_max(futureBoard)
		if bestValue > value:
			bestMove = move
			value = bestValue
	
	return bestMove

func find_ai_move():
	selectedMove = create_legal_move(pick_best_move(currentLegalMoves, gameBoard))
	
	var placeStone = Timer.new()
	placeStone.wait_time = aiWaitTime
	placeStone.one_shot = true
	add_child(placeStone)
	placeStone.start()
	placeStone.connect("timeout", self, "apply_ai_move")
	yield(placeStone, "timeout")
	placeStone.queue_free()

func apply_ai_move():
	selectedStone = place_stone_at(selectedMove.row, selectedMove.col, currentPlayer, gameBoard)
	for stone in selectedStone.flipStones:
		stone.flip()
	
	#Recreating the board with updated stones because 'board.duplicate(true)' doesn't deep copy it
	gameBoard = create_board()
	for stone in get_children():
		if stone.get_class() == "MeshInstance":
			gameBoard[stone.row][stone.col] = stone

func count(player : String, board):
	var total = 0
	for i in range(SIZE):
		for j in range(SIZE):
			if board[i][j].sideUp == player:
				total += 1
	
	return total

# warning-ignore:unused_argument
func _process(delta):
	if selectedStone != null:
		for stone in selectedStone.flipStones:
			if not stone.flipped:
				return
		
		go_to_turn(enemy_of(currentPlayer))