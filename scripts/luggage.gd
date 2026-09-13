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
	if texture == null:
		suitcase_body.texture = null
		return

	suitcase_body.texture = texture
	var width := float(texture.get_width())
	var height := float(texture.get_height())
	var largest := max(width, height)
	if largest > 0.0:
		var factor := 44.0 / largest
		suitcase_body.scale = Vector2(factor, factor)
	suitcase_body.centered = true
	suitcase_body.offset = Vector2.ZERO


func _draw() -> void:
	if collected:
		return

	if suitcase_body == null or suitcase_body.texture == null:
		var size := 38.0
		var base_color: Color = COLOR_MAP.get(color, Color.WHITE)
		draw_rect(Rect2(-size * 0.5, -size * 0.5, size, size), base_color)

	var dir_vector := direction_to_vector(direction)
	var start := Vector2.ZERO
	var tip := dir_vector * 13.0
	draw_line(start, tip, Color(1, 1, 1, 0.95), 4.0, true)
	var perpendicular := Vector2(-dir_vector.y, dir_vector.x)
	draw_line(tip, tip - dir_vector * 5.0 + perpendicular * 4.0, Color(1, 1, 1, 0.95), 3.0, true)
	draw_line(tip, tip - dir_vector * 5.0 - perpendicular * 4.0, Color(1, 1, 1, 0.95), 3.0, true)


func _on_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit(self)
	elif event is InputEventScreenTouch and event.pressed:
		pressed.emit(self)


func direction_to_vector(dir_name: String) -> Vector2:
	match dir_name:
		"up": return Vector2(0, -1)
		"down": return Vector2(0, 1)
		"left": return Vector2(-1, 0)
		"right": return Vector2(1, 0)
		_: return Vector2(0, -1)


func direction_to_grid_vector(dir_name: String) -> Vector2i:
	match dir_name:
		"up": return Vector2i(-1, 0)
		"down": return Vector2i(1, 0)
		"left": return Vector2i(0, -1)
		"right": return Vector2i(0, 1)
		_: return Vector2i(-1, 0)
