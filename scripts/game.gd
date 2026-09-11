extends Node2D

const CELL_SIZE := 52
const LUGGAGE_SCENE := preload("res://scenes/luggage.tscn")

@onready var board: Node2D = $Board
@onready var level_label: Label = $HUD/MarginContainer/VBoxContainer/TopBar/LevelLabel
@onready var coins_label: Label = $HUD/MarginContainer/VBoxContainer/TopBar/CoinsLabel
@onready var status_label: Label = $HUD/MarginContainer/VBoxContainer/StatusLabel
@onready var hint_button: Button = $HUD/MarginContainer/VBoxContainer/BottomBar/HintButton
@onready var shuffle_button: Button = $HUD/MarginContainer/VBoxContainer/BottomBar/ShuffleButton

var level_number: int = 1
var level_data: Dictionary = {}
var walls: Dictionary = {}
var luggages: Array[Luggage] = []
var save_data: Dictionary = {}
var collected_count: int = 0


func _ready() -> void:
	save_data = SaveManager.load_save()
	load_level(level_number)
	hint_button.pressed.connect(_on_hint_pressed)
	shuffle_button.pressed.connect(_on_shuffle_pressed)


func load_level(level_id: int) -> void:
	level_number = level_id
	level_data = LevelManager.load_level(level_id)
	level_label.text = "Level %d" % level_id
	coins_label.text = "Coins: %d" % save_data.get("coins", 0)
	status_label.text = "Ready"
	collected_count = 0
	walls.clear()
	luggages.clear()
	for child in board.get_children():
		child.queue_free()
	
	var board_size := int(level_data.get("size", 6))
	for row in range(board_size):
		for col in range(board_size):
			var tile_node := ColorRect.new()
			tile_node.color = Color(0.72, 0.61, 0.46, 0.12)
			tile_node.size = Vector2(CELL_SIZE, CELL_SIZE)
			tile_node.position = board_position_for(row, col) - Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.5)
			board.add_child(tile_node)
	for wall in level_data.get("walls", []):
		walls[Vector2i(int(wall["row"]), int(wall["col"]))] = true
		var wall_node := ColorRect.new()
		wall_node.color = Color(0.27, 0.29, 0.35, 1.0)
		wall_node.size = Vector2(CELL_SIZE, CELL_SIZE)
		wall_node.position = board_position_for(int(wall["row"]), int(wall["col"])) - Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.5)
		board.add_child(wall_node)

	for luggage_data in level_data.get("luggages", []):
		var luggage: Luggage = LUGGAGE_SCENE.instantiate()
		luggage.row = int(luggage_data.get("row", 0))
		luggage.col = int(luggage_data.get("col", 0))
		luggage.color = String(luggage_data.get("color", "red"))
		luggage.direction = String(luggage_data.get("direction", "right"))
		luggage.position = board_position_for(luggage.row, luggage.col)
		luggage.pressed.connect(_on_luggage_pressed)
		board.add_child(luggage)
		luggages.append(luggage)


func board_position_for(row: int, col: int) -> Vector2:
	return Vector2(col * CELL_SIZE + CELL_SIZE * 0.5, row * CELL_SIZE + CELL_SIZE * 0.5)


func _on_luggage_pressed(luggage: Luggage) -> void:
	if luggage.collected:
		return
	var current := Vector2i(luggage.row, luggage.col)
	var direction_vector := luggage.direction_to_vector(luggage.direction)
	var next := current + Vector2i(direction_vector)
	var step := 0
	while true:
		if next.x < 0 or next.x >= int(level_data.get("size", 6)) or next.y < 0 or next.y >= int(level_data.get("size", 6)):
			collect_luggage(luggage)
			return
		if walls.has(next):
			status_label.text = "Blocked"
			return
		if has_luggage_at(next.x, next.y):
			status_label.text = "Blocked"
			return
		luggage.row = next.x
		luggage.col = next.y
		luggage.position = board_position_for(luggage.row, luggage.col)
		step += 1
		if step >= 5:
			break
		next = Vector2i(luggage.row, luggage.col) + Vector2i(direction_vector)

	status_label.text = "Moved"


func has_luggage_at(row: int, col: int) -> bool:
	for luggage in luggages:
		if luggage.collected:
			continue
		if luggage.row == row and luggage.col == col:
			return true
	return false


func collect_luggage(luggage: Luggage) -> void:
	luggage.collected = true
	luggage.visible = false
	collected_count += 1
	status_label.text = "Luggage collected"
	if collected_count >= luggages.size():
		_on_level_cleared()


func _on_hint_pressed() -> void:
	status_label.text = "Hint: follow the arrow direction"


func _on_shuffle_pressed() -> void:
	for luggage in luggages:
		if luggage.collected:
			continue
		var directions := ["up", "down", "left", "right"]
		luggage.direction = directions[randi() % directions.size()]
		luggage.queue_redraw()
	status_label.text = "Board shuffled"


func _on_level_cleared() -> void:
	save_data["coins"] = int(save_data.get("coins", 0)) + 20
	save_data["highest_level"] = max(int(save_data.get("highest_level", 1)), level_number + 1)
	SaveManager.save(save_data)
	status_label.text = "LEVEL COMPLETE"
	var scene := load("res://scenes/level_complete.tscn")
	get_tree().change_scene_to_packed(scene)
