extends Area

onready var globals = get_tree().get_root().get_node("/root/globals")

onready var board = get_parent()
onready var AI = get_node("AI")

onready var model = get_node("Model")
onready var material = model.mesh.surface_get_material(0).duplicate()

var row : int
var col : int

var flipStones = []

func to_string():
	return String(row) + "" + String(col)

func _ready():
	if not globals.darkAI and not globals.lightAI:
		AI.queue_free()
	
	material.albedo_color = Color(0, 0, 0, material.albedo_color.a + (flipStones.size() - 1) * 0.125)
	model.set_surface_material(0, material)

func run_player_move(camera, event, click_position, click_normal, shape_idx):
	if event is InputEventMouseButton:
		if board.currentPlayer == "Dark" and not globals.darkAI or board.currentPlayer == "Light" and not globals.lightAI:
			board.place_stone(row, col, board.currentPlayer, board.gameBoard)
			
			for move in board.get_children():
				if move.get_class() == "Area":
					if move == self:
						move.visible = false
					else:
						move.queue_free()
			
			for stone in flipStones:
				stone.flip()
			
			get_node("CollisionShape").visible = false

func run_ai_move():
	board.place_stone(row, col, board.currentPlayer, board.gameBoard)
	get_node("CollisionShape").visible = false
	yield(get_tree().create_timer(AI.wait_time), "timeout")
	visible = false
	for stone in flipStones:
		stone.flip()

func _process(delta):
	if not visible:
		if flipStones.size() > 0:
			for stone in flipStones: 
				if not stone.flipped:
					return
			
			board.update_hud(board.enemy_of(board.currentPlayer))
			flipStones.clear()
			yield(board, "up_to_date")
		else:
			board.begin_turn()
			queue_free()