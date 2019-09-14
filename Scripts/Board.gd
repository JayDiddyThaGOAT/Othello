	extends MeshInstance

signal up_to_date

const SIZE : int = 8
const DIRECTIONS = ["NORTH", "SOUTH", "WEST", "EAST", "NORTHWEST", "NORTHEAST", "SOUTHWEST", "SOUTHEAST"]

onready var globals = get_tree().get_root().get_node("/root/globals")

onready var darkScore = get_parent().get_node("Players/Dark")
onready var lightScore = get_parent().get_node("Players/Light")

onready var darkController = darkScore.get_node("Controller/Name")
onready var lightController = lightScore.get_node("Controller/Name")

onready var darkInstruction = get_parent().get_node("Dark Instruction")
onready var lightInstruction = get_parent().get_node("Light Instruction")

onready var darkTurnSummary = get_parent().get_node("Dark Turn Summary")
onready var lightTurnSummary = get_parent().get_node("Light Turn Summary")

var gameBoard : Array = []

var currentPlayer : String = "Dark"
var currentLegalMoves : Array = []

func _ready():
	randomize()
	for row in range(SIZE):
		gameBoard.append([])
# warning-ignore:unused_variable
		for col in range(SIZE):
			gameBoard[row].append(null)
	
	place_stone(3, 3, "Light", gameBoard)
	place_stone(4, 4, "Light", gameBoard)
	place_stone(3, 4, "Dark", gameBoard)
	place_stone(4, 3, "Dark", gameBoard)
	
	update_hud(currentPlayer)
	
	if globals.lightAI:
		lightController.text = "CPU"
		set_ai_difficulty()
	else:
		lightController.text = "PLAYER"
	
	if globals.darkAI:
		darkController.text = "CPU"
		set_ai_difficulty()
	else:
		darkController.text = "PLAYER"
	
	darkInstruction.add_color_override("font_color", Color.black)
	lightInstruction.add_color_override("font_color", Color.white)
	
	if globals.darkAI:
		yield(get_tree().create_timer(currentLegalMoves[0].get_node("AI").wait_time), "timeout")
	
	begin_turn()

func restart_game():
	if !("WINNER" in darkTurnSummary.text or "LOSER" in darkTurnSummary and "WINNER" in lightTurnSummary.text or "LOSER" in darkTurnSummary.text or "TIE" in darkTurnSummary and "TIE" in lightTurnSummary):
		globals.aiLosses = 0
		set_ai_difficulty()
	else:
		globals.currentRound += 1
	
# warning-ignore:return_value_discarded
	get_tree().reload_current_scene()

func go_back_to_main_menu():
	globals.aiLosses = 0
	globals.currentRound = 0
	set_ai_difficulty()
# warning-ignore:return_value_discarded
	get_tree().change_scene_to(globals.mainMenu)
	
func up_next(nextPlayer : String, board : Array):
	var nextEnemyLegalMoves = get_legal_moves_from(enemy_of(nextPlayer), board)
	if nextEnemyLegalMoves.size() > 0:
		currentLegalMoves = nextEnemyLegalMoves
		return enemy_of(nextPlayer)
	else:
		var nextPlayerLegalMoves = get_legal_moves_from(nextPlayer, board)
		if nextPlayerLegalMoves.size() > 0:
			currentLegalMoves = nextPlayerLegalMoves
			return nextPlayer
		else:
			currentLegalMoves = []
			return null

func update_hud(player : String):
	var repeatedTurn : bool = false
	
	var darkStones : int = 0
	var lightStones : int = 0
# warning-ignore:unused_variable
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
		if not globals.darkAI:
			darkInstruction.add_color_override("font_color", Color.yellow)
			darkInstruction.text = "TAP A BUTTON"
		
		if not globals.lightAI:
			lightInstruction.add_color_override("font_color", Color.yellow)
			lightInstruction.text = "TAP A BUTTON"
		
		match get_player_with_most_discs(gameBoard):
			"Dark":
				if not globals.darkAI and globals.lightAI:
					globals.aiLosses += 1
				
				darkScore.get_node("Score/Space").texture = globals.darkSpaceTexture
				lightScore.get_node("Score/Space").texture = globals.normSpaceTexture
				
				darkTurnSummary.text = "WINNER\n"
				lightTurnSummary.text = "LOSER\n"
			"Light":
				if not globals.lightAI and globals.darkAI:
					globals.aiLosses += 1
				
				lightScore.get_node("Score/Space").texture = globals.darkSpaceTexture
				darkScore.get_node("Score/Space").texture = globals.normSpaceTexture
				
				lightScore.get_node("Score/Number").text = String(lightStones)
				
				lightTurnSummary.text = "WINNER\n"
				darkTurnSummary.text = "LOSER\n"
			"Tie":
				darkScore.get_node("Score/Space").texture = globals.darkSpaceTexture
				lightScore.get_node("Score/Space").texture = globals.darkSpaceTexture
				
				darkScore.get_node("Score/Number").text = String(darkStones)
				lightScore.get_node("Score/Number").text = String(lightStones)
				
				darkTurnSummary.text = "TIE\n"
				lightTurnSummary.text = "TIE\n"
		
		emit_signal("up_to_date")
		return
	
	repeatedTurn = currentPlayer == nextPlayer and not darkStones == 2 and not lightStones == 2
	currentPlayer = nextPlayer
	match currentPlayer:
		"Dark":
			lightInstruction.text = ""
			if globals.darkAI:
				darkInstruction.text = ""
			else:
				if globals.currentRound == 1:
					darkInstruction.text = "TAP A SPACE"
			
			darkScore.get_node("Score/Space").texture = globals.darkSpaceTexture
			lightScore.get_node("Score/Space").texture = globals.normSpaceTexture
			
			if not repeatedTurn: darkTurnSummary.text = darkController.text + " GOES\n"
			else: darkTurnSummary.text = darkController.text + " GOES\nAGAIN"
			
			lightTurnSummary.text = ""
		"Light":
			darkInstruction.text = ""
			if globals.lightAI:
				lightInstruction.text = ""
			else:
				if globals.currentRound == 1:
					lightInstruction.text = "TAP A SPACE"
				
			lightScore.get_node("Score/Space").texture = globals.darkSpaceTexture
			darkScore.get_node("Score/Space").texture = globals.normSpaceTexture
			
			if not repeatedTurn: lightTurnSummary.text = lightController.text + " GOES\n"
			else: lightTurnSummary.text = lightController.text + " GOES\nAGAIN"
			
			darkTurnSummary.text = ""
	
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

func set_ai_difficulty():
	if globals.aiLosses == 0:
		if not globals.aiFlags[0]:
			globals.aiFlags[0] = true
			globals.aiFlags[1] = false
			globals.aiFlags[2] = false
	elif globals.aiLosses == 2:
		if not globals.aiFlags[1]:
			if globals.lightAI:
				lightInstruction.text = "+1 AWARENESS"
			elif globals.darkAI:
				darkInstruction.text = "+1 AWARENESS"
		
			globals.aiFlags[0] = true
			globals.aiFlags[1] = true
			globals.aiFlags[2] = false
		
	elif globals.aiLosses == 4:
		if not globals.aiFlags[2]:
			if globals.lightAI:
				lightInstruction.text = "+1 DEFENSE"
			elif globals.darkAI:
				darkInstruction.text = "+1 DEFENSE"
			
			globals.aiFlags[0] = true
			globals.aiFlags[1] = true
			globals.aiFlags[2] = true

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
	
	var parity : float
	if globals.aiFlags[0]:
		parity = float(100 * (playerStones - enemyStones)) / float((playerStones + enemyStones))
	else:
		parity = 0
	
	var weights : float
	if globals.aiFlags[1] and playerPositionScore + enemyPositionScore != 0:
		weights = 100 * (playerPositionScore - enemyPositionScore) / (playerPositionScore + enemyPositionScore)
	else:
		weights = 0
	
	var mobility : float
	if globals.aiFlags[2] and playerMobility + enemyMobility != 0:
		mobility = 100 * (playerMobility - enemyMobility) / (enemyMobility + playerMobility)
	else:
		mobility = 0
	
	return (0.1 * parity) + weights + (10 * mobility)