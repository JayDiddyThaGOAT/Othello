	extends MeshInstance

signal up_to_date

const SIZE : int = 8
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
	
	var darkStones : int = 0
	var lightStones : int = 0
	var emptySpaces : int = 0
	
	for row in range(SIZE):
		for col in range(SIZE):
			var stone = gameBoard[row][col]
			if stone == null:
				emptySpaces += 1
			else:
				if stone.sideUp == "Dark": darkStones += 1
				elif stone.sideUp == "Light": lightStones += 1
	
	darkScore.get_node("Score/Number").text = String(darkStones)
	lightScore.get_node("Score/Number").text = String(lightStones)
	
	var nextPlayer = up_next(enemy_of(player), gameBoard)
	
	if nextPlayer == null:
		match get_player_with_most_discs(gameBoard):
			"Dark":
				darkScore.get_node("Score/Space").texture = globals.darkSpaceTexture
				lightScore.get_node("Score/Space").texture = globals.normSpaceTexture
				
				darkScore.get_node("Turn Summary").text = "WINNER"
				lightScore.get_node("Turn Summary").text = "LOSER"
			"Light":
				lightScore.get_node("Score/Space").texture = globals.darkSpaceTexture
				darkScore.get_node("Score/Space").texture = globals.normSpaceTexture
				
				lightScore.get_node("Score/Number").text = String(lightStones)
				
				lightScore.get_node("Turn Summary").text = "WINNER"
				darkScore.get_node("Turn Summary").text = "LOSER"
			"Tie":
				darkScore.get_node("Score/Space").texture = globals.darkSpaceTexture
				lightScore.get_node("Score/Space").texture = globals.darkSpaceTexture
				
				darkScore.get_node("Score/Number").text = String(darkStones)
				lightScore.get_node("Score/Number").text = String(lightStones)
				
				darkScore.get_node("Turn Summary").text = "TIE"
				lightScore.get_node("Turn Summary").text = "TIE"
		
		return
	
	currentPlayer = nextPlayer
	currentLegalMoves = get_legal_moves_from(currentPlayer, gameBoard)
	match currentPlayer:
		"Dark":
			darkScore.get_node("Score/Space").texture = globals.darkSpaceTexture
			lightScore.get_node("Score/Space").texture = globals.normSpaceTexture
			
			if not repeatedTurn: darkScore.get_node("Turn Summary").text = darkController.text + " GOES"
			else: darkScore.get_node("Turn Summary").text = darkController.text + " GOES AGAIN"
			
			lightScore.get_node("Turn Summary").text = ""
		"Light":
			lightScore.get_node("Score/Space").texture = globals.darkSpaceTexture
			darkScore.get_node("Score/Space").texture = globals.normSpaceTexture
			
			if not repeatedTurn: lightScore.get_node("Turn Summary").text = lightController.text + " GOES"
			else: lightScore.get_node("Turn Summary").text = lightController.text + " GOES AGAIN"
			
			darkScore.get_node("Turn Summary").text = ""
	
	emit_signal("up_to_date")

func begin_turn():
	if currentPlayer == "Dark" and not globals.darkAI or currentPlayer == "Light" and not globals.lightAI:
		place_legal_moves(currentLegalMoves)
	else:
		var move = place_best_move(currentLegalMoves)
		if move == null:
			return
		
		move.AI.start()


func enemy_of(player : String):
	match player:
		"Dark" : return "Light"
		"Light": return "Dark"

func get_player_with_most_discs(board):
	var darkCount : int = 0
	var lightCount : int = 0
	
	for row in range(SIZE):
		for col in range(SIZE):
			var stone = board[row][col]
			if stone == null:
				continue
			
			if stone.sideUp == "Dark": darkCount += 1
			elif stone.sideUp == "Light": lightCount += 1
	
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
	var playerStones : int = 0
	var enemyStones : int = 0
	for row in range(SIZE):
		for col in range(SIZE):
			var stone = board[row][col]
			if stone == null:
				continue
			
			if stone.sideUp == currentPlayer:
				playerStones += 1
			elif stone.sideUp == enemy_of(currentPlayer):
				enemyStones += 1
	
	if playerStones == 0 or enemyStones == 0:
		return []
	
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
	var playerStones : int = 0
	var enemyStones : int = 0
	for row in range(SIZE):
		for col in range(SIZE):
			var stone = gameBoard[row][col]
			if stone == null:
				continue
			
			if stone.sideUp == currentPlayer:
				playerStones += 1
			elif stone.sideUp == enemy_of(currentPlayer):
				enemyStones += 1
	
	if playerStones == 0 or enemyStones == 0:
		return
	
	for move in legalMoves:
		add_child(move)

func place_best_move(legalMoves):
	var bestMove : Area
	var bestValue : float = -INF
	for move in legalMoves:
		add_stone_on_board(move.row, move.col, currentPlayer, gameBoard)
		var flank = get_flipped_stones(move.row, move.col, currentPlayer, gameBoard)
		for stone in flank:
			stone.sideUp = currentPlayer
		
		var value = evaluate(gameBoard)
		
		gameBoard[move.row][move.col] = null
		for stone in flank:
			stone.sideUp = enemy_of(currentPlayer)
		
		if value > bestValue:
			bestMove = move
			bestValue = value
	
	if bestMove != null:
		add_child(bestMove)
		return bestMove
	else:
		return null

func evaluate(board : Array):
	var playerStones : int = 0
	var enemyStones : int = 0
	
	var playerMobility : float = 0
	var enemyMobility : float = 0
	
	var playerPositionScore : float = 0
	var enemyPositionScore : float = 0
	
	for row in range(SIZE):
		for col in range(SIZE):
			var stone = board[row][col]
			if stone == null:
				var surroundingStones = neighbors_at(row, col, board).values()
				for s in surroundingStones:
					if s == null:
						continue
					
					if s.sideUp == currentPlayer:
						enemyMobility += 1
					elif s.sideUp == enemy_of(currentPlayer):
						playerMobility += 1
			else:
				if stone.sideUp == currentPlayer:
					playerStones += 1
					playerPositionScore += globals.values[row][col]
				elif stone.sideUp == enemy_of(currentPlayer):
					enemyStones += 1
					enemyPositionScore += globals.values[row][col]
	
	var parity = 100 * (playerStones - enemyStones) / (playerStones + enemyStones)
	
	var mobility : float = 0
	if playerMobility + enemyMobility != 0:
		mobility = 100 * (playerMobility - enemyMobility) / (enemyMobility + playerMobility)
	
	var weights : float = 0
	if playerPositionScore + enemyPositionScore != 0:
		weights = 100 * (playerPositionScore - enemyPositionScore) / (playerPositionScore + enemyPositionScore)
	
	return (0.1 * parity) * mobility * (10 * weights)