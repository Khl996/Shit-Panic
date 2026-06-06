extends Node2D

const DOOR_WIDTH: float = 70.0
const DOOR_HEIGHT: float = 160.0
const DOOR_COLOR: Color = Color(0.301961, 0.180392, 0.0980392, 1.0)
const DOOR_TRIM: Color = Color(0.541176, 0.380392, 0.219608, 1.0)
const DOOR_PANEL: Color = Color(0.227451, 0.137255, 0.0745098, 1.0)
const HANDLE_COLOR: Color = Color(0.847059, 0.741176, 0.380392, 1.0)
const HANDLE_SHADOW: Color = Color(0.0, 0.0, 0.0, 0.6)
const SIGN_BG: Color = Color(0.901961, 0.866667, 0.745098, 1.0)
const SIGN_TEXT: Color = Color(0.180392, 0.117647, 0.0784314, 1.0)


func _ready() -> void:
	z_index = 4
	queue_redraw()


func _draw() -> void:
	var origin: Vector2 = Vector2(-DOOR_WIDTH * 0.5, -DOOR_HEIGHT * 0.5)
	# Door slab
	draw_rect(Rect2(origin + Vector2(2.0, 3.0), Vector2(DOOR_WIDTH, DOOR_HEIGHT)), Color(0.0, 0.0, 0.0, 0.5), true)
	draw_rect(Rect2(origin, Vector2(DOOR_WIDTH, DOOR_HEIGHT)), DOOR_COLOR, true)
	# Inner panels
	var panel_margin: float = 8.0
	var top_panel: Rect2 = Rect2(origin + Vector2(panel_margin, panel_margin), Vector2(DOOR_WIDTH - panel_margin * 2.0, DOOR_HEIGHT * 0.45 - panel_margin))
	var bottom_panel: Rect2 = Rect2(origin + Vector2(panel_margin, DOOR_HEIGHT * 0.5 + 4.0), Vector2(DOOR_WIDTH - panel_margin * 2.0, DOOR_HEIGHT * 0.5 - panel_margin - 4.0))
	draw_rect(top_panel, DOOR_PANEL, true)
	draw_rect(bottom_panel, DOOR_PANEL, true)
	draw_rect(top_panel, DOOR_TRIM, false, 1.2)
	draw_rect(bottom_panel, DOOR_TRIM, false, 1.2)
	# Frame
	draw_rect(Rect2(origin, Vector2(DOOR_WIDTH, DOOR_HEIGHT)), DOOR_TRIM, false, 1.5)
	# Handle on the right side
	var handle_center: Vector2 = origin + Vector2(DOOR_WIDTH - 12.0, DOOR_HEIGHT * 0.55)
	draw_circle(handle_center + Vector2(1.5, 1.5), 5.5, HANDLE_SHADOW)
	draw_circle(handle_center, 5.0, HANDLE_COLOR)
	# Sign nailed to top panel
	_draw_sign(origin + Vector2(DOOR_WIDTH * 0.5, panel_margin + 16.0))


func _draw_sign(center_position: Vector2) -> void:
	var sign_size: Vector2 = Vector2(56.0, 40.0)
	var transform: Transform2D = Transform2D(-0.04, center_position)
	draw_set_transform_matrix(transform)
	var rect: Rect2 = Rect2(-sign_size * 0.5, sign_size)
	draw_rect(Rect2(rect.position + Vector2(1.0, 2.0), rect.size), Color(0.0, 0.0, 0.0, 0.45), true)
	draw_rect(rect, SIGN_BG, true)
	draw_rect(rect, Color(0.443137, 0.34902, 0.196078, 1.0), false, 1.2)
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 11
	var lines: Array[String] = ["نائم", "لا تطرق"]
	for line_index: int in range(lines.size()):
		var line_text: String = lines[line_index]
		var text_size: Vector2 = font.get_string_size(line_text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size)
		var y_offset: float = -sign_size.y * 0.18 + float(line_index) * (float(font_size) + 2.0)
		draw_string(font, Vector2(-text_size.x * 0.5, y_offset), line_text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size, SIGN_TEXT)
	# Nail
	draw_circle(Vector2(0.0, -sign_size.y * 0.5 + 6.0), 2.0, Color(0.235, 0.156, 0.086, 1.0))
	draw_set_transform_matrix(Transform2D.IDENTITY)
