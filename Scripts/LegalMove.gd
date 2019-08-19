extends Area

onready var board = get_parent()
onready var model = get_node("Model")
onready var material = model.mesh.surface_get_material(0).duplicate()

var row : int
var col : int

var flipStones = []

func to_string():
	return String(row) + "" + String(col)

func _ready():
	var flankDirections = board.neighbors_of(board.get_stone_on(row, col, board.gameBoard), board.gameBoard)
	for direction in flankDirections:
		var stones = []
		var stone = flankDirections[direction]
		while stone.sideUp == board.enemy_of(board.currentPlayer):
			stones.append(stone)
			var surroundingStones = board.neighbors_of(stone, board.gameBoard)
			if not surroundingStones.has(direction):
				break
				
			stone = surroundingStones[direction]
		
		if stone.sideUp == board.currentPlayer:
			for stone in stones:
				flipStones.append(stone)
	
	material.albedo_color = Color(0, 0, 0, material.albedo_color.a + ((flipStones.size() - 1) * 0.125))
	print(material.albedo_color)
	model.set_surface_material(0, material)

func run_player_move(camera, event, click_position, click_normal, shape_idx):
	if event is InputEventMouseButton:
		board.place_stone(row, col, board.currentPlayer, board.gameBoard)
		
		for move in board.get_children():
			if move.get_class() == "Area":
				if move == self:
					move.visible = false
				else:
					move.queue_free()
		
		for stone in flipStones:
			stone.flip()
		
func _process(delta):
	if not visible:
		for stone in flipStones:
			if not stone.flipped:
				return
		
		board.begin_turn(board.enemy_of(board.currentPlayer))
		queue_free()