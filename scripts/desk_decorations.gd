extends Control

const TAPE_LIGHT: Color = Color(0.937255, 0.870588, 0.682353, 0.78)
const TAPE_DARK: Color = Color(0.717647, 0.62353, 0.392157, 0.55)
const TAPE_EDGE: Color = Color(0.443137, 0.345098, 0.180392, 0.45)
const DEFAULT_VIEWPORT_SIZE: Vector2 = Vector2(1280.0, 720.0)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var draw_size: Vector2 = size
	if draw_size.x < 1.0 or draw_size.y < 1.0:
		draw_size = DEFAULT_VIEWPORT_SIZE
	_draw_corner_tape(draw_size)
	_draw_margin_tape(draw_size)


func _draw_corner_tape(draw_size: Vector2) -> void:
	var strips: Array[Dictionary] = [
		{
			"center": Vector2(34.0, 34.0),
			"size": Vector2(96.0, 22.0),
			"angle": -PI * 0.25,
		},
		{
			"center": Vector2(draw_size.x - 34.0, 34.0),
			"size": Vector2(96.0, 22.0),
			"angle": PI * 0.25,
		},
		{
			"center": Vector2(34.0, draw_size.y - 54.0),
			"size": Vector2(88.0, 20.0),
			"angle": PI * 0.28,
		},
		{
			"center": Vector2(draw_size.x - 34.0, draw_size.y - 54.0),
			"size": Vector2(88.0, 20.0),
			"angle": -PI * 0.28,
		},
	]
	for strip: Dictionary in strips:
		_draw_tape_strip(strip["center"] as Vector2, strip["size"] as Vector2, float(strip["angle"]))


func _draw_margin_tape(draw_size: Vector2) -> void:
	var strips: Array[Dictionary] = [
		{
			"center": Vector2(10.0, draw_size.y * 0.5),
			"size": Vector2(58.0, 16.0),
			"angle": PI * 0.5 + 0.08,
		},
		{
			"center": Vector2(draw_size.x - 10.0, draw_size.y * 0.42),
			"size": Vector2(58.0, 16.0),
			"angle": PI * 0.5 - 0.06,
		},
	]
	for strip: Dictionary in strips:
		_draw_tape_strip(strip["center"] as Vector2, strip["size"] as Vector2, float(strip["angle"]))


func _draw_tape_strip(center: Vector2, strip_size: Vector2, angle: float) -> void:
	var transform: Transform2D = Transform2D(angle, center)
	draw_set_transform_matrix(transform)
	var rect: Rect2 = Rect2(-strip_size * 0.5, strip_size)
	draw_rect(rect, TAPE_LIGHT, true)
	var stripe_height: float = strip_size.y * 0.42
	var stripe_rect: Rect2 = Rect2(
		Vector2(-strip_size.x * 0.5, -stripe_height * 0.5),
		Vector2(strip_size.x, stripe_height)
	)
	draw_rect(stripe_rect, TAPE_DARK, true)
	var edge_a_start: Vector2 = Vector2(-strip_size.x * 0.5, -strip_size.y * 0.5)
	var edge_a_end: Vector2 = Vector2(strip_size.x * 0.5, -strip_size.y * 0.5)
	var edge_b_start: Vector2 = Vector2(-strip_size.x * 0.5, strip_size.y * 0.5)
	var edge_b_end: Vector2 = Vector2(strip_size.x * 0.5, strip_size.y * 0.5)
	draw_line(edge_a_start, edge_a_end, TAPE_EDGE, 1.0, true)
	draw_line(edge_b_start, edge_b_end, TAPE_EDGE, 1.0, true)
	draw_set_transform_matrix(Transform2D.IDENTITY)
