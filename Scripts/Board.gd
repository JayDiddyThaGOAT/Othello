extends MeshInstance

signal up_to_date

const SIZE = 8
const DIRECTIONS = ["NORTH", "SOUTH", "WEST", "EAST", "NORTHWEST", "NORTHEAST", "SOUTHWEST", "SOUTHEAST"]

onready var globals = get_tree().get_root().get_node("/root/globals")

onready var darkScore = get_parent().get_node("Players/Dark")
onready var lightScore = get_parent().get_node("Players/Light")

onready var darkController = darkScore.get_node("Controller/Name")
onready var lightController = lightScore.get_node("Controller/Name")

var gameBoard : Array = []

var currentPlayer : String = "Dark"
var currentLegalMoves : Array = []

func _ready():
	randomize()

	for row in range(SIZE):
		gameBoard.append([])
		for col in range(SIZE):
			gameBoard[row].append(null)
	
	place_stone(3, 3, "Light", gameBoard)
	place_stone(4, 4, "Light", gameBoard)
	place_stone(3, 4, "Dark", gameBoard)
	place_stone(4, 3, "Dark", gameBoard)
	
	if globals.lightAI:
		lightController.text = "CPU"
	else:
		lightController.text = "PLAYER"
	
	if globals.darkAI:
		darkController.text = "CPU"
	else:
		darkController.text = "PLAYER"
	
	update_hud(currentPlayer)
	
	if globals.darkAI:
		yield(get_tree().create_timer(currentLegalMoves[0].get_node("AI").wait_time), "timeout")
	
	begin_turn()

func restart_game():
	get_tree().reload_current_scene()

func go_back_to_main_menu():
	get_tree().change_scene_to(globals.mainMenu)
	
func up_next(nextPlayer : String, board : Array):
	var nextEnemyLegalMoves = get_legal_moves_from(enemy_of(nextPlayer), board)
	if nextEnemyLegalMoves.size() > 0:
		return enemy_of(nextPlayer)
	else:
		var nextPlayerLegalMoves = get_legal_moves_from(nextPlayer, board)
		if nextPlayerLegalMoves.size() > 0:
			return nextPlayer
		else:
			return null

func update_hud(player : String):
	var repeatedTurn
	
	darkScore.get_node("Score/Number").text = String(count_all_stones("Dark", gameBoard))
	lightScore.get_node("Score/Number").text = String(count_all_stones("Light", gameBoard))
	
	var nextPlayer = up_next(enemy_of(player), gameBoard)
	
	if nextPlayer == null:
		match get_winner_from(gameBoard):
			"Dark":
				darkScore.get_node("Score/Space").texture = globals.darkSpaceTexture
				lightScore.get_node("Score/Space").texture = globals.normSpaceTexture
				
				darkScore.get_node("Score/Number").text = String(count_all_stones("Dark", gameBoard) + count_all_stones("", gameBoard))
				
				darkScore.get_node("Turn Summary").text = "WINNER\n"
				lightScore.get_node("Turn Summary").text = "LOSER\n"
			"Light":
				lightScore.get_node("Score/Space").texture = globals.darkSpaceTexture
				darkScore.get_node("Score/Space").texture = globals.normSpaceTexture
				
				lightScore.get_node("Score/Number").text = String(count_all_stones("Light", gameBoard) + count_all_stones("", gameBoard))
				
				lightScore.get_node("Turn Summary").text = "WINNER\n"
				darkScore.get_node("Turn Summary").text = "LOSER\n"
			"Tie":
				darkScore.get_node("Score/Space").texture = globals.darkSpaceTexture
				lightScore.get_node("Score/Space").texture = globals.darkSpaceTexture
				
				darkScore.get_node("Score/Number").text = String(count_all_stones("Dark", gameBoard) + count_all_stones("", gameBoard))
				lightScore.get_node("Score/Number").text = String(count_all_stones("Light", gameBoard) + count_all_stones("", gameBoard))
				
				darkScore.get_node("Turn Summary").text = "TIE\n"
				lightScore.get_node("Turn Summary").text = "TIE\n"
		
		return
	
	currentPlayer = nextPlayer
	currentLegalMoves = get_legal_moves_from(currentPlayer, gameBoard)
	match currentPlayer:
		"Dark":
			darkScore.get_node("Score/Space").texture = globals.darkSpaceTexture
			lightScore.get_node("Score/Space").texture = globals.normSpaceTexture
			
			if not repeatedTurn: darkScore.get_node("Turn Summary").text = darkController.text + " GOES\n"
			else: darkScore.get_node("Turn Summary").text = darkController.text + " GOES\nAGAIN"
			
			lightScore.get_node("Turn Summary").text = "\n"
		"Light":
			lightScore.get_node("Score/Space").texture = globals.darkSpaceTexture
			darkScore.get_node("Score/Space").texture = globals.normSpaceTexture
			
			if not repeatedTurn: lightScore.get_node("Turn Summary").text = lightController.text + " GOES\n"
			else: lightScore.get_node("Turn Summary").text = lightController.text + " GOES\nAGAIN"
			
			darkScore.get_node("Turn Summary").text = "\n"
	
	emit_signal("up_to_date")

func begin_turn():
	if currentPlayer == "Dark" and not globals.darkAI or currentPlayer == "Light" and not globals.lightAI:
		place_legal_moves(currentLegalMoves)
	else:
		var bestMove = place_best_move(currentLegalMoves)
		bestMove.AI.start()

func heuristic(player : String, board : Array):
	
	var stoneParityValue
	var stabilityValue
	
	var playerStones = 0
	var enemyStones = 0
	var playerFrontierStones = 0
	var enemyFrontierStones = 0
	
	for row in range(SIZE):
		for col in range(SIZE):
			if board[row][col] != null:
				if board[row][col].sideUp == player:
					playerStones += 1
				elif board[row][col].sideUp == player:
					enemyStones += 1
				
				var neighbors = neighbors_at(row, col, board).values()
				for stone in neighbors:
					if stone == null:
						if board[row][col].sideUp == player:
							playerFrontierStones += 1
						elif board[row][col].sideUp == enemy_of(player):
							enemyFrontierStones += 1
	
	stoneParityValue = 100 * (playerStones - enemyStones) / (playerStones + enemyStones)
	if playerFrontierStones + enemyFrontierStones == 0:
		stabilityValue = 0
	else:
		stabilityValue = 100 * (playerFrontierStones - enemyFrontierStones) / (playerFrontierStones + enemyFrontierStones)
	
	var mobilityValue
	var playerMobility = get_legal_moves_from(player, board).size()
	var enemyMobility = get_legal_moves_from(enemy_of(player), board).size()
	if playerMobility + enemyMobility == 0:
		mobilityValue = 0
	else:
		mobilityValue = 100 * (playerMobility - enemyMobility) / (playerMobility + enemyMobility)
	
	var cornersCapturedValue
	var playerCornersCaptured = 0
	var enemyCornersCaptured = 0
	
	var closeToCornersCapturedValue
	var closeToPlayerCorners = 0
	var closeToEnemyCorners = 0
	
	if board[0][0] == null:
		var neighbors = neighbors_at(0, 0, board).values()
		for stone in neighbors:
			if stone == null:
				continue
			
			if stone.sideUp == player:
				closeToPlayerCorners += 1
			elif stone.sideUp == enemy_of(player):
				closeToEnemyCorners += 1
	else:
		if board[0][0].sideUp == player:
			playerCornersCaptured += 1
		elif board[0][0].sideUp == enemy_of(player):
			enemyCornersCaptured += 1
	
	if board[0][SIZE - 1] == null:
		var neighbors = neighbors_at(0, SIZE - 1, board).values()
		for stone in neighbors:
			if stone == null:
				continue
			
			if stone.sideUp == player:
				closeToPlayerCorners += 1
			elif stone.sideUp == enemy_of(player):
				closeToEnemyCorners += 1
	else:
		if board[0][SIZE - 1].sideUp == player:
			playerCornersCaptured += 1
		elif board[0][SIZE - 1].sideUp == enemy_of(player):
			enemyCornersCaptured += 1
	
	if board[SIZE - 1][0] == null:
		var neighbors = neighbors_at(SIZE - 1, 0, board).values()
		for stone in neighbors:
			if stone == null:
				continue
			
			if stone.sideUp == player:
				closeToPlayerCorners += 1
			elif stone.sideUp == enemy_of(player):
				closeToEnemyCorners += 1
	else:
		if board[SIZE - 1][0].sideUp == player:
			playerCornersCaptured += 1
		elif board[SIZE - 1][0].sideUp == enemy_of(player):
			enemyCornersCaptured += 1
	
	if board[SIZE - 1][SIZE - 1] == null:
		var neighbors = neighbors_at(SIZE - 1, SIZE - 1, board).values()
		for stone in neighbors:
			if stone == null:
				continue
			
			if stone.sideUp == player:
				closeToPlayerCorners += 1
			elif stone.sideUp == enemy_of(player):
				closeToEnemyCorners += 1
	else:
		if board[SIZE - 1][SIZE - 1].sideUp == player:
			playerCornersCaptured += 1
		elif board[SIZE - 1][SIZE - 1].sideUp == enemy_of(player):
			enemyCornersCaptured += 1
		
	if closeToPlayerCorners + closeToEnemyCorners == 0:
		closeToCornersCapturedValue = 0
	else:
		closeToCornersCapturedValue = 100 * (closeToPlayerCorners - closeToEnemyCorners) / (closeToPlayerCorners + closeToEnemyCorners)
	
	if playerCornersCaptured + enemyCornersCaptured == 0:
		cornersCapturedValue = 0
	else:
		cornersCapturedValue = 100 * (playerCornersCaptured - enemyCornersCaptured) / (playerCornersCaptured + enemyCornersCaptured)
	
	return (10 * stoneParityValue)  + (74.936 * stabilityValue) + (78.922 * mobilityValue) + (801.724 * cornersCapturedValue) + (382.026 * closeToCornersCapturedValue)

func count_all_stones(player : String, board : Array):
	var total = 0
	for row in range(SIZE):
		for col in range(SIZE):
			var stone = board[row][col]
			if player == "":
				if stone == null:
					total += 1
			else:
				if stone == null:
					continue
			
				if stone.sideUp == player:
					total += 1
	return total

func count_corner_stones(player : String, board : Array):
	var total = 0
	if board[0][0] != null and board[0][0].sideUp == player:
		total += 1
	if board[0][SIZE - 1] != null and board[0][SIZE - 1].sideUp == player:
		total += 1
	if board[SIZE - 1][0] != null and board[SIZE - 1][0].sideUp == player:
		total += 1
	if board[SIZE - 1][SIZE - 1] != null and board[SIZE - 1][SIZE - 1].sideUp == player:
		total += 1
	
	return total

func enemy_of(player : String):
	match player:
		"Dark" : return "Light"
		"Light": return "Dark"

func get_winner_from(board):
	var darkCount = count_all_stones("Dark", board)
	var lightCount = count_all_stones("Light", board)
	
	if darkCount > lightCount:
		return "Dark"
	elif darkCount < lightCount:
		return "Light"
	else:
		return "Tie"

func add_stone_on_board(row : int, col : int, sideUp : String, board : Array):
	board[row][col] = globals.stone.instance()
	board[row][col].row = row
	board[row][col].col = col
	board[row][col].sideUp = sideUp
	
	return board[row][col]

func get_flipped_stones(row : int, col : int, sideUp : String, board : Array):
	var flankDirections = neighbors_at(row, col, board)
	var flipStones = []
	for direction in flankDirections:
		var stones = []
		var stone = flankDirections[direction]
		while stone != null and stone.sideUp == enemy_of(sideUp):
			stones.append(stone)
			var surroundingStones = neighbors_at(stone.row, stone.col, board)
			if not surroundingStones.has(direction):
				break
				
			stone = surroundingStones[direction]
		
		if stone != null and stone.sideUp == sideUp:
			for stone in stones:
				flipStones.append(stone)
	
	return flipStones

func place_stone(row : int, col : int, sideUp : String, board : Array):
	var stone = add_stone_on_board(row, col, sideUp, board)
	stone.set_translation(Vector3(col - 3.5, 0, row - 3.5))
	match stone.sideUp:
		"Dark": stone.set_rotation_degrees(Vector3(0, 0, 0))
		"Light": stone.set_rotation_degrees(Vector3(-180, 0, 0))
	
	add_child(stone)

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

func create_legal_move(row : int, col : int, player : String, board : Array):
	var legalMove = globals.legalMove.instance()
	legalMove.row = row
	legalMove.col = col
	legalMove.flipStones = get_flipped_stones(row, col, player, board)
	legalMove.set_translation(Vector3(col - 3.5, legalMove.get_translation().y, row - 3.5))
	
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
			return create_legal_move(row, col, rootStone.sideUp, board)

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
	if legalMoves.size() <= 0:
		return
	
	for move in legalMoves:
		add_child(move)

func max_turn(board : Array, depth : int = 0, alpha : float = -INF, beta : float = INF):
	var moves = get_legal_moves_from(currentPlayer, board)
	
	var maxDepth
	match currentPlayer:
		"Dark": maxDepth = globals.darkDifficulty
		"Light": maxDepth = globals.lightDifficulty
	
	if depth == maxDepth or moves.size() <= 0:
		return heuristic(currentPlayer, board)
	
	var value = -INF
	for move in moves:
		board[move.row][move.col] = add_stone_on_board(move.row, move.col, currentPlayer, board)
		var flipStones = get_flipped_stones(move.row, move.col, currentPlayer, board)
		
		value = max(value, min_turn(board, depth + 1, alpha, beta))
		alpha = max(alpha, value)
		
		board[move.row][move.col] = null
		for stone in flipStones:
			stone.sideUp = enemy_of(currentPlayer)
		flipStones.clear()
		
		if alpha >= beta:
			break
	
	return value
	
func min_turn(board : Array, depth : int = 0, alpha : float = -INF, beta : float = INF):
	var moves = get_legal_moves_from(enemy_of(currentPlayer), board)
	
	var maxDepth
	match currentPlayer:
		"Dark": maxDepth = globals.darkDifficulty
		"Light": maxDepth = globals.lightDifficulty
	
	if depth == maxDepth or moves.size() <= 0:
		return heuristic(currentPlayer, board)
	
	var value = INF
	for move in moves:
		board[move.row][move.col] = add_stone_on_board(move.row, move.col, enemy_of(currentPlayer), board)
		var flipStones = get_flipped_stones(move.row, move.col, enemy_of(currentPlayer), board)
		
		value = min(value, max_turn(board, depth + 1, alpha, beta))
		beta = min(beta, value)
		
		board[move.row][move.col] = null
		for stone in flipStones:
			stone.sideUp = currentPlayer
		flipStones.clear()
		
		if alpha >= beta:
			break
	
	return value

func place_best_move(moves):
	var bestMove = moves[randi() % moves.size()]
	
	var bestValue = -INF
	for move in moves:
		gameBoard[move.row][move.col] = add_stone_on_board(move.row, move.col, currentPlayer, gameBoard)
		var flipStones = get_flipped_stones(move.row, move.col, currentPlayer, gameBoard)
		
		var value = max_turn(gameBoard)
		
		gameBoard[move.row][move.col] = null
		for stone in flipStones:
			stone.sideUp = enemy_of(currentPlayer)
		flipStones.clear()
		
		if value > bestValue or value == bestValue and randf() < 0.5:
			bestMove = move
			bestValue = value
	
	add_child(bestMove)
	return bestMove