extends Node2D

const DESK_WIDTH: float = 360.0
const DESK_HEIGHT: float = 130.0
const DESK_BASE: Color = Color(0.164706, 0.141176, 0.117647, 1.0)
const DESK_TOP: Color = Color(0.282353, 0.239216, 0.184314, 1.0)
const DESK_EDGE: Color = Color(0.435294, 0.360784, 0.262745, 1.0)
const DESK_SHADOW: Color = Color(0.0, 0.0, 0.0, 0.5)
const METAL_DARK: Color = Color(0.137255, 0.149020, 0.172549, 1.0)
const METAL_MID: Color = Color(0.231373, 0.247059, 0.282353, 1.0)
const METAL_EDGE: Color = Color(0.380392, 0.403922, 0.450980, 1.0)
const SCREEN_BG: Color = Color(0.027451, 0.043137, 0.039216, 1.0)
const SCREEN_GLOW: Color = Color(0.121569, 0.301961, 0.196078, 1.0)
const SCREEN_TEXT: Color = Color(0.494118, 0.870588, 0.564706, 0.9)
const KEY_COLOR: Color = Color(0.176471, 0.184314, 0.207843, 1.0)
const MUG_COLOR: Color = Color(0.717647, 0.270588, 0.227451, 1.0)
const LAMP_METAL: Color = Color(0.345098, 0.356863, 0.388235, 1.0)
const LAMP_GLOW: Color = Color(1.0, 0.831373, 0.494118, 0.30)
const PAPER_COLOR: Color = Color(0.901961, 0.870588, 0.776471, 1.0)
const STICKER_YELLOW: Color = Color(0.949020, 0.831373, 0.345098, 1.0)
const STICKER_TEXT: Color = Color(0.227451, 0.176471, 0.117647, 1.0)

var _time: float = 0.0


func _ready() -> void:
	z_index = 4
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var origin: Vector2 = Vector2(-DESK_WIDTH * 0.5, -DESK_HEIGHT * 0.5)
	# Shadow + desk body
	draw_rect(Rect2(origin + Vector2(6.0, 9.0), Vector2(DESK_WIDTH, DESK_HEIGHT)), DESK_SHADOW, true)
	draw_rect(Rect2(origin, Vector2(DESK_WIDTH, DESK_HEIGHT)), DESK_BASE, true)
	draw_rect(Rect2(origin + Vector2(6.0, 6.0), Vector2(DESK_WIDTH - 12.0, DESK_HEIGHT - 12.0)), DESK_TOP, true)
	draw_line(origin + Vector2(6.0, 6.0), origin + Vector2(DESK_WIDTH - 6.0, 6.0), DESK_EDGE, 2.0, true)
	draw_line(origin + Vector2(6.0, 6.0), origin + Vector2(6.0, DESK_HEIGHT - 6.0), DESK_EDGE, 1.5, true)
	# Wood grain hints on the surface
	for i: int in range(4):
		var gy: float = origin.y + 22.0 + float(i) * 26.0
		draw_line(Vector2(origin.x + 14.0, gy), Vector2(origin.x + DESK_WIDTH - 14.0, gy), Color(0.0, 0.0, 0.0, 0.07), 1.0, true)

	_draw_main_monitor(Vector2(-96.0, -8.0))
	_draw_side_monitor(Vector2(-12.0, -14.0))
	_draw_keyboard(Vector2(-92.0, 34.0))
	_draw_mouse(Vector2(-22.0, 40.0))
	_draw_papers(Vector2(96.0, 30.0))
	_draw_mug(Vector2(44.0, 40.0))
	_draw_desk_lamp(Vector2(128.0, -22.0))
	_draw_sticker(Vector2(150.0, 44.0), Vector2(64.0, 20.0), -0.1, "نموذج 7-ج")


func _draw_main_monitor(center: Vector2) -> void:
	# 3/4-view CRT facing the player: a chunky bezel with a glowing screen.
	var body: Rect2 = Rect2(center + Vector2(-52.0, -34.0), Vector2(104.0, 60.0))
	# Stand shadow on desk
	draw_rect(Rect2(center + Vector2(-20.0, 24.0), Vector2(40.0, 10.0)), Color(0.0, 0.0, 0.0, 0.35), true)
	# Bezel
	draw_rect(Rect2(body.position + Vector2(3.0, 5.0), body.size), Color(0.0, 0.0, 0.0, 0.4), true)
	draw_rect(body, METAL_MID, true)
	draw_rect(body, METAL_EDGE, false, 2.0)
	# Screen
	var screen: Rect2 = Rect2(body.position + Vector2(8.0, 7.0), body.size - Vector2(16.0, 16.0))
	draw_rect(screen, SCREEN_BG, true)
	draw_rect(screen.grow(-2.0), SCREEN_GLOW, true)
	# Scanlines
	var sy: float = screen.position.y + 3.0
	while sy < screen.position.y + screen.size.y - 2.0:
		draw_line(Vector2(screen.position.x + 2.0, sy), Vector2(screen.position.x + screen.size.x - 2.0, sy), Color(0.0, 0.0, 0.0, 0.16), 1.0, true)
		sy += 3.0
	# Terminal text bars (scrolling feel)
	for line_index: int in range(5):
		var bar_width: float = 30.0 + float((line_index * 23 + int(_time * 6.0)) % 50)
		var bar_y: float = screen.position.y + 6.0 + float(line_index) * 8.0
		draw_rect(Rect2(Vector2(screen.position.x + 5.0, bar_y), Vector2(bar_width, 3.0)), Color(SCREEN_TEXT.r, SCREEN_TEXT.g, SCREEN_TEXT.b, 0.6), true)
	# Power LED
	draw_circle(body.position + Vector2(body.size.x - 8.0, body.size.y - 6.0), 2.0, Color(0.4, 0.9, 0.5, 1.0))


func _draw_side_monitor(center: Vector2) -> void:
	var body: Rect2 = Rect2(center + Vector2(-30.0, -24.0), Vector2(60.0, 44.0))
	draw_rect(Rect2(body.position + Vector2(2.0, 4.0), body.size), Color(0.0, 0.0, 0.0, 0.35), true)
	draw_rect(body, METAL_DARK, true)
	draw_rect(body, METAL_EDGE, false, 1.5)
	var screen: Rect2 = Rect2(body.position + Vector2(5.0, 5.0), body.size - Vector2(10.0, 10.0))
	draw_rect(screen, SCREEN_BG, true)
	draw_rect(screen.grow(-1.5), Color(0.105882, 0.180392, 0.282353, 1.0), true)
	# A small wave/graph line
	var prev: Vector2 = Vector2(screen.position.x + 2.0, screen.position.y + screen.size.y * 0.5)
	for px: int in range(1, int(screen.size.x) - 2, 3):
		var nx: float = screen.position.x + float(px)
		var ny: float = screen.position.y + screen.size.y * 0.5 + sin(_time * 3.0 + float(px) * 0.3) * 6.0
		draw_line(prev, Vector2(nx, ny), Color(0.45, 0.78, 0.95, 0.85), 1.0, true)
		prev = Vector2(nx, ny)


func _draw_keyboard(center: Vector2) -> void:
	var body: Rect2 = Rect2(center + Vector2(-46.0, -12.0), Vector2(92.0, 30.0))
	draw_rect(Rect2(body.position + Vector2(2.0, 3.0), body.size), Color(0.0, 0.0, 0.0, 0.3), true)
	draw_rect(body, METAL_MID, true)
	draw_rect(body, METAL_EDGE, false, 1.0)
	for row: int in range(3):
		for col: int in range(10):
			var kx: float = body.position.x + 5.0 + float(col) * 8.4
			var ky: float = body.position.y + 4.0 + float(row) * 7.5
			draw_rect(Rect2(Vector2(kx, ky), Vector2(6.5, 5.5)), KEY_COLOR, true)


func _draw_mouse(center: Vector2) -> void:
	draw_rect(Rect2(center + Vector2(-5.0, -7.0), Vector2(12.0, 16.0)), METAL_MID, true)
	draw_line(center + Vector2(0.0, -6.0), center + Vector2(0.0, -1.0), METAL_DARK, 1.0, true)


func _draw_papers(center: Vector2) -> void:
	for i: int in range(3):
		var angle: float = (float(i) - 1.0) * 0.16
		var t: Transform2D = Transform2D(angle, center + Vector2(float(i) * 2.0, float(i) * 2.0))
		draw_set_transform_matrix(t)
		draw_rect(Rect2(Vector2(-22.0, -28.0), Vector2(44.0, 56.0)), Color(0.0, 0.0, 0.0, 0.2), true)
		draw_rect(Rect2(Vector2(-23.0, -29.0), Vector2(44.0, 56.0)), PAPER_COLOR, true)
		for line_i: int in range(5):
			draw_line(Vector2(-18.0, -20.0 + float(line_i) * 9.0), Vector2(16.0, -20.0 + float(line_i) * 9.0), Color(0.4, 0.4, 0.45, 0.5), 1.0, true)
		draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_mug(center: Vector2) -> void:
	draw_circle(center + Vector2(1.5, 2.0), 11.0, Color(0.0, 0.0, 0.0, 0.3))
	draw_circle(center, 11.0, MUG_COLOR)
	draw_circle(center, 7.5, Color(0.149020, 0.105882, 0.082353, 1.0))
	draw_arc(center + Vector2(11.0, 0.0), 5.0, -PI * 0.5, PI * 0.5, 10, MUG_COLOR, 3.0, true)
	# Rising steam
	for s: int in range(2):
		var base: Vector2 = center + Vector2(-3.0 + float(s) * 6.0, -8.0)
		var sway: float = sin(_time * 2.5 + float(s)) * 3.0
		draw_line(base, base + Vector2(sway, -10.0), Color(0.9, 0.9, 0.9, 0.18), 2.0, true)


func _draw_desk_lamp(center: Vector2) -> void:
	# Pool of warm light on the desk
	_draw_filled_circle(center + Vector2(-6.0, 30.0), 34.0, LAMP_GLOW)
	# Base
	draw_circle(center + Vector2(0.0, 34.0), 9.0, LAMP_METAL)
	# Arm
	draw_line(center + Vector2(0.0, 34.0), center + Vector2(-8.0, 6.0), LAMP_METAL, 3.0, true)
	draw_line(center + Vector2(-8.0, 6.0), center + Vector2(-14.0, -2.0), LAMP_METAL, 3.0, true)
	# Head
	draw_circle(center + Vector2(-14.0, -2.0), 6.0, LAMP_METAL)
	draw_circle(center + Vector2(-13.0, 0.0), 3.0, Color(1.0, 0.88, 0.6, 1.0))


func _draw_filled_circle(center: Vector2, radius: float, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for index: int in range(24):
		var angle: float = (float(index) / 24.0) * TAU
		points.append(center + Vector2(cos(angle) * radius, sin(angle) * radius * 0.85))
	draw_colored_polygon(points, color)


func _draw_sticker(center_position: Vector2, sticker_size: Vector2, angle: float, text: String) -> void:
	var transform: Transform2D = Transform2D(angle, center_position)
	draw_set_transform_matrix(transform)
	var rect: Rect2 = Rect2(-sticker_size * 0.5, sticker_size)
	draw_rect(Rect2(rect.position + Vector2(1.5, 2.0), rect.size), Color(0.0, 0.0, 0.0, 0.4), true)
	draw_rect(rect, STICKER_YELLOW, true)
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 11
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size)
	draw_string(font, Vector2(-text_size.x * 0.5, float(font_size) * 0.32), text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size, STICKER_TEXT)
	draw_set_transform_matrix(Transform2D.IDENTITY)
