extends Node2D

# Walls, server-room shell and fixed industrial detailing. The floor itself is
# rendered by the concrete_floor shader on the FloorShader ColorRect beneath
# this node, so nothing here paints the open floor.

const ROOM_WIDTH: float = 1280.0
const ROOM_HEIGHT: float = 720.0
const WALL_THICKNESS: float = 30.0

const WALL_CONCRETE: Color = Color(0.223529, 0.235294, 0.262745, 1.0)
const WALL_CONCRETE_DARK: Color = Color(0.152941, 0.164706, 0.188235, 1.0)
const WALL_BLOCK_LINE: Color = Color(0.117647, 0.125490, 0.145098, 0.85)
const WALL_TRIM_METAL: Color = Color(0.380392, 0.403922, 0.443137, 1.0)
const WALL_HIGHLIGHT: Color = Color(0.298039, 0.313726, 0.349020, 1.0)
const INNER_SHADOW: Color = Color(0.0, 0.0, 0.0, 0.40)
const PIPE_BODY: Color = Color(0.337255, 0.356863, 0.388235, 1.0)
const PIPE_SHADE: Color = Color(0.184314, 0.196078, 0.219608, 1.0)
const PIPE_HIGHLIGHT: Color = Color(0.521569, 0.549020, 0.592157, 1.0)
const PANEL_METAL: Color = Color(0.270588, 0.286275, 0.317647, 1.0)
const PANEL_DARK: Color = Color(0.152941, 0.164706, 0.184314, 1.0)
const HAZARD_YELLOW: Color = Color(0.847059, 0.658824, 0.180392, 1.0)
const SIGN_BG: Color = Color(0.901961, 0.847059, 0.690196, 0.96)
const SIGN_TEXT: Color = Color(0.137255, 0.105882, 0.070588, 1.0)
const WARN_SIGN_BG: Color = Color(0.831373, 0.231373, 0.180392, 0.95)
const WARN_SIGN_TEXT: Color = Color(0.964706, 0.945098, 0.894118, 1.0)
const DETAIL_SEED: int = 9931


func _ready() -> void:
	z_index = -10
	queue_redraw()


func _draw() -> void:
	_draw_walls()
	_draw_wall_pipes()
	_draw_electrical_panel()
	_draw_safety_signs()
	_draw_floor_outlets()


func _draw_walls() -> void:
	var rects: Array[Rect2] = [
		Rect2(Vector2(0.0, 0.0), Vector2(ROOM_WIDTH, WALL_THICKNESS)),
		Rect2(Vector2(0.0, ROOM_HEIGHT - WALL_THICKNESS), Vector2(ROOM_WIDTH, WALL_THICKNESS)),
		Rect2(Vector2(0.0, 0.0), Vector2(WALL_THICKNESS, ROOM_HEIGHT)),
		Rect2(Vector2(ROOM_WIDTH - WALL_THICKNESS, 0.0), Vector2(WALL_THICKNESS, ROOM_HEIGHT)),
	]
	for wall_rect: Rect2 in rects:
		draw_rect(wall_rect, WALL_CONCRETE, true)
	_draw_wall_block_texture()
	# Metal skirting trim on the inner edge.
	var inner: Rect2 = Rect2(Vector2(WALL_THICKNESS, WALL_THICKNESS), Vector2(ROOM_WIDTH - WALL_THICKNESS * 2.0, ROOM_HEIGHT - WALL_THICKNESS * 2.0))
	draw_rect(inner, WALL_TRIM_METAL, false, 2.0)
	# Soft inner shadow so the floor feels recessed.
	var s: float = 7.0
	draw_rect(Rect2(inner.position, Vector2(inner.size.x, s)), INNER_SHADOW, true)
	draw_rect(Rect2(inner.position, Vector2(s, inner.size.y)), INNER_SHADOW, true)
	draw_rect(Rect2(Vector2(inner.position.x + inner.size.x - s, inner.position.y), Vector2(s, inner.size.y)), INNER_SHADOW, true)
	draw_rect(Rect2(Vector2(inner.position.x, inner.position.y + inner.size.y - s), Vector2(inner.size.x, s)), INNER_SHADOW, true)


func _draw_wall_block_texture() -> void:
	# Cinder-block seams along each wall band, plus a little grime variance.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = DETAIL_SEED
	var block_w: float = 80.0
	# Top + bottom horizontal walls
	for band_top: float in [0.0, ROOM_HEIGHT - WALL_THICKNESS]:
		var x: float = 0.0
		while x < ROOM_WIDTH:
			draw_line(Vector2(x, band_top), Vector2(x, band_top + WALL_THICKNESS), WALL_BLOCK_LINE, 1.0, true)
			x += block_w
		draw_line(Vector2(0.0, band_top + WALL_THICKNESS * 0.5), Vector2(ROOM_WIDTH, band_top + WALL_THICKNESS * 0.5), WALL_BLOCK_LINE, 1.0, true)
	# Left + right vertical walls
	for band_left: float in [0.0, ROOM_WIDTH - WALL_THICKNESS]:
		var y: float = 0.0
		while y < ROOM_HEIGHT:
			draw_line(Vector2(band_left, y), Vector2(band_left + WALL_THICKNESS, y), WALL_BLOCK_LINE, 1.0, true)
			y += block_w
		draw_line(Vector2(band_left + WALL_THICKNESS * 0.5, 0.0), Vector2(band_left + WALL_THICKNESS * 0.5, ROOM_HEIGHT), WALL_BLOCK_LINE, 1.0, true)
	# Grime speckles
	for _i: int in range(120):
		var gx: float = rng.randf_range(0.0, ROOM_WIDTH)
		var gy: float = rng.randf_range(0.0, ROOM_HEIGHT)
		if gx > WALL_THICKNESS and gx < ROOM_WIDTH - WALL_THICKNESS and gy > WALL_THICKNESS and gy < ROOM_HEIGHT - WALL_THICKNESS:
			continue
		draw_circle(Vector2(gx, gy), rng.randf_range(0.6, 1.8), Color(0.0, 0.0, 0.0, rng.randf_range(0.10, 0.30)))


func _draw_wall_pipes() -> void:
	# Two horizontal pipes running along the top wall.
	for pipe_y: float in [9.0, 19.0]:
		draw_line(Vector2(40.0, pipe_y), Vector2(820.0, pipe_y), PIPE_SHADE, 6.0, true)
		draw_line(Vector2(40.0, pipe_y - 1.0), Vector2(820.0, pipe_y - 1.0), PIPE_BODY, 4.0, true)
		draw_line(Vector2(40.0, pipe_y - 2.0), Vector2(820.0, pipe_y - 2.0), PIPE_HIGHLIGHT, 1.0, true)
		# Brackets
		var bx: float = 80.0
		while bx < 820.0:
			draw_rect(Rect2(Vector2(bx - 3.0, pipe_y - 5.0), Vector2(6.0, 10.0)), PIPE_SHADE, true)
			bx += 150.0
	# Vertical drop pipe down the right wall toward the server room.
	draw_line(Vector2(ROOM_WIDTH - 14.0, 30.0), Vector2(ROOM_WIDTH - 14.0, 180.0), PIPE_SHADE, 7.0, true)
	draw_line(Vector2(ROOM_WIDTH - 15.0, 30.0), Vector2(ROOM_WIDTH - 15.0, 180.0), PIPE_BODY, 4.0, true)


func _draw_electrical_panel() -> void:
	# Grey metal breaker box on the left wall.
	var box: Rect2 = Rect2(Vector2(6.0, 250.0), Vector2(20.0, 110.0))
	draw_rect(Rect2(box.position + Vector2(2.0, 3.0), box.size), Color(0.0, 0.0, 0.0, 0.4), true)
	draw_rect(box, PANEL_METAL, true)
	draw_rect(box, PANEL_DARK, false, 1.5)
	# Breaker rows
	for row: int in range(5):
		var ry: float = box.position.y + 10.0 + float(row) * 19.0
		draw_rect(Rect2(Vector2(box.position.x + 4.0, ry), Vector2(12.0, 12.0)), PANEL_DARK, true)
		var lit: Color = HAZARD_YELLOW if row % 2 == 0 else Color(0.345098, 0.572549, 0.443137, 1.0)
		draw_rect(Rect2(Vector2(box.position.x + 6.0, ry + 3.0), Vector2(4.0, 6.0)), lit, true)


func _draw_safety_signs() -> void:
	# General night-shift building signage.
	_draw_sign(Vector2(150.0, 48.0), Vector2(180.0, 26.0), "التشغيل الليلي — الطابق -3", SIGN_BG, SIGN_TEXT)
	_draw_sign(Vector2(1100.0, 48.0), Vector2(150.0, 26.0), "مخرج طوارئ", WARN_SIGN_BG, WARN_SIGN_TEXT)
	_draw_sign(Vector2(ROOM_WIDTH - 70.0, 360.0), Vector2(96.0, 24.0), "إدارة", SIGN_BG, SIGN_TEXT)


func _draw_floor_outlets() -> void:
	# A couple of wall power outlets for detail.
	for outlet_pos: Vector2 in [Vector2(360.0, 40.0), Vector2(640.0, 40.0)]:
		draw_rect(Rect2(outlet_pos - Vector2(7.0, 6.0), Vector2(14.0, 12.0)), PANEL_DARK, true)
		draw_circle(outlet_pos + Vector2(-3.0, 0.0), 1.6, WALL_HIGHLIGHT)
		draw_circle(outlet_pos + Vector2(3.0, 0.0), 1.6, WALL_HIGHLIGHT)


func _draw_sign(center: Vector2, sign_size: Vector2, text: String, bg: Color, text_color: Color) -> void:
	var rect: Rect2 = Rect2(center - sign_size * 0.5, sign_size)
	draw_rect(Rect2(rect.position + Vector2(2.0, 3.0), rect.size), Color(0.0, 0.0, 0.0, 0.45), true)
	draw_rect(rect, bg, true)
	draw_rect(rect, text_color, false, 1.5)
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 14
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size)
	draw_string(font, rect.position + Vector2((rect.size.x - text_size.x) * 0.5, sign_size.y * 0.5 + float(font_size) * 0.35), text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size, text_color)
