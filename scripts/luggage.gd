extends Area2D
class_name Luggage

signal pressed(luggage: Luggage)

const COLOR_MAP := {
	"red": Color(0.93, 0.31, 0.29),
	"blue": Color(0.34, 0.56, 0.93),
	"green": Color(0.39, 0.82, 0.48),
	"yellow": Color(0.96, 0.82, 0.24),
	"purple": Color(0.63, 0.43, 0.94),
}

const TEXTURE_MAP := {
	"red": preload("res://assets/luggage_red.png"),
	"blue": preload("res://assets/luggage_blue.png"),
	"green": preload("res://assets/luggage_green.png"),
	"yellow": preload("res://assets/luggage_yellow.png"),
	"purple": preload("res://assets/luggage_purple.png"),
}

@onready var suitcase_body: Sprite2D = $VisualRoot/SuitcaseBody

var row: int = 0
var col: int = 0
var color: String = "red"
var direction: String = "right"
var board_size: int = 6
var collected: bool = false

func _ready() -> void:
	input_event.connect(_on_input_event)
	_apply_texture()
	queue_redraw()


func _apply_texture() -> void:
	if suitcase_body == null:
		return

	var texture: Texture2D = TEXTURE_MAP.get(color, null)
	if texture != null:
		suitcase_body.texture = texture
		suitcase_body.scale = Vector2(0.04, 0.04)
		suitcase_body.centered = true
		suitcase_body.offset = Vector2.ZERO
		return

	suitcase_body.texture = null


func _draw() -> void:
	if collected:
		return
	if suitcase_body != null and suitcase_body.texture != null:
		return
	var size := 30.0
	var base_color: Color = COLOR_MAP.get(color, Color.WHITE)
	draw_rect(Rect2(-size * 0.5, -size * 0.5, size, size), base_color)
	draw_rect(Rect2(-size * 0.5 + 4.0, -size * 0.5 + 4.0, size - 8.0, size - 8.0), Color(0.96, 0.96, 0.96, 0.15))

	var dir_vector := direction_to_vector(direction)
	var tip := dir_vector * 9.0
	var start := Vector2.ZERO
	draw_line(start, start + tip, Color(1, 1, 1, 0.9), 4.0)
	var left := Vector2(-3.0, 0.0)
	var right := Vector2(3.0, 0.0)
	if direction == "up":
		left = Vector2(-3.0, 0.0)
		right = Vector2(3.0, 0.0)
	elif direction == "down":
		left = Vector2(3.0, 0.0)
		right = Vector2(-3.0, 0.0)
	elif direction == "left":
		left = Vector2(0.0, -3.0)
		right = Vector2(0.0, 3.0)
	elif direction == "right":
		left = Vector2(0.0, 3.0)
		right = Vector2(0.0, -3.0)
	var wing_a := start + tip + left
	var wing_b := start + tip + right
	draw_line(start + tip, wing_a, Color(1, 1, 1, 0.9), 3.0)
	draw_line(start + tip, wing_b, Color(1, 1, 1, 0.9), 3.0)


func _on_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit(self)


func direction_to_vector(dir_name: String) -> Vector2:
	match dir_name:
		"up":
			return Vector2(0, -1)
		"down":
			return Vector2(0, 1)
		"left":
			return Vector2(-1, 0)
		"right":
			return Vector2(1, 0)
		_:
			return Vector2(0, -1)
