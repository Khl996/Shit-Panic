extends Node2D

const DESK_WIDTH: float = 360.0
const DESK_HEIGHT: float = 130.0
const DESK_BASE: Color = Color(0.231373, 0.156863, 0.0901961, 1.0)
const DESK_TOP: Color = Color(0.388235, 0.27451, 0.156863, 1.0)
const DESK_HIGHLIGHT: Color = Color(0.580392, 0.419608, 0.243137, 1.0)
const DESK_SHADOW: Color = Color(0.0784314, 0.0470588, 0.0235294, 0.85)
const CONSOLE_BG: Color = Color(0.0784314, 0.0588235, 0.0431373, 1.0)
const CONSOLE_FRAME: Color = Color(0.494118, 0.34902, 0.196078, 1.0)
const SCREEN_GLOW: Color = Color(0.121569, 0.282353, 0.176471, 1.0)
const SCREEN_TEXT: Color = Color(0.494118, 0.811765, 0.529412, 0.85)
const STICKER_YELLOW: Color = Color(0.949020, 0.831373, 0.345098, 1.0)
const STICKER_TEXT: Color = Color(0.227451, 0.176471, 0.117647, 1.0)


func _ready() -> void:
	z_index = 4
	queue_redraw()


func _draw() -> void:
	var origin: Vector2 = Vector2(-DESK_WIDTH * 0.5, -DESK_HEIGHT * 0.5)
	# Shadow under desk
	draw_rect(Rect2(origin + Vector2(6.0, 8.0), Vector2(DESK_WIDTH, DESK_HEIGHT)), DESK_SHADOW, true)
	# Desk base
	draw_rect(Rect2(origin, Vector2(DESK_WIDTH, DESK_HEIGHT)), DESK_BASE, true)
	# Desk top surface
	draw_rect(Rect2(origin + Vector2(8.0, 8.0), Vector2(DESK_WIDTH - 16.0, DESK_HEIGHT - 16.0)), DESK_TOP, true)
	# Highlights
	draw_line(origin + Vector2(8.0, 8.0), origin + Vector2(DESK_WIDTH - 8.0, 8.0), DESK_HIGHLIGHT, 2.0, true)
	draw_line(origin + Vector2(8.0, 8.0), origin + Vector2(8.0, DESK_HEIGHT - 8.0), DESK_HIGHLIGHT, 2.0, true)
	# Console screen embedded in desk
	var screen_rect: Rect2 = Rect2(origin + Vector2(40.0, 30.0), Vector2(DESK_WIDTH - 80.0, DESK_HEIGHT - 60.0))
	draw_rect(Rect2(screen_rect.position + Vector2(-3.0, -3.0), screen_rect.size + Vector2(6.0, 6.0)), CONSOLE_FRAME, true)
	draw_rect(screen_rect, CONSOLE_BG, true)
	draw_rect(screen_rect.grow(-4.0), SCREEN_GLOW, true)
	# Scanlines on the screen
	var scanline_color: Color = Color(0.0, 0.0, 0.0, 0.18)
	var sy: float = screen_rect.position.y + 4.0
	while sy < screen_rect.position.y + screen_rect.size.y - 4.0:
		draw_line(Vector2(screen_rect.position.x + 4.0, sy), Vector2(screen_rect.position.x + screen_rect.size.x - 4.0, sy), scanline_color, 1.0, true)
		sy += 4.0
	# Fake terminal text bars
	var bar_color: Color = SCREEN_TEXT
	for line_index: int in range(4):
		var bar_width: float = 60.0 + float((line_index * 17) % 80)
		var bar_y: float = screen_rect.position.y + 10.0 + float(line_index) * 12.0
		draw_rect(Rect2(Vector2(screen_rect.position.x + 8.0, bar_y), Vector2(bar_width, 4.0)), Color(bar_color.r, bar_color.g, bar_color.b, 0.55), true)
	# Bureaucratic sticker on corner of desk
	_draw_sticker(origin + Vector2(DESK_WIDTH - 80.0, DESK_HEIGHT - 28.0), Vector2(70.0, 22.0), -0.08, "نموذج 7-ج")


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
