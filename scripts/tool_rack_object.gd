extends Node2D

enum SlotState {
	BOTH,
	TAPE_ONLY,
	BUCKET_ONLY,
	NONE,
}

const RACK_WIDTH: float = 130.0
const RACK_HEIGHT: float = 170.0
const RACK_BASE: Color = Color(0.180392, 0.121569, 0.0784314, 1.0)
const RACK_TRIM: Color = Color(0.580392, 0.419608, 0.243137, 1.0)
const RACK_SHADOW: Color = Color(0.0, 0.0, 0.0, 0.55)
const HOOK_COLOR: Color = Color(0.345098, 0.235294, 0.137255, 1.0)
const TAPE_COLOR: Color = Color(0.937255, 0.870588, 0.682353, 1.0)
const TAPE_STRIPE: Color = Color(0.717647, 0.623529, 0.392157, 1.0)
const TAPE_HOLE: Color = Color(0.227451, 0.156863, 0.0980392, 1.0)
const BUCKET_COLOR: Color = Color(0.654902, 0.654902, 0.694118, 1.0)
const BUCKET_RIM: Color = Color(0.388235, 0.388235, 0.423529, 1.0)
const STICKER_BG: Color = Color(0.945098, 0.901961, 0.811765, 1.0)
const STICKER_TEXT: Color = Color(0.180392, 0.117647, 0.0784314, 1.0)

var state: int = SlotState.BOTH


func _ready() -> void:
	z_index = 3
	queue_redraw()


func set_state(new_state: int) -> void:
	if state == new_state:
		return
	state = new_state
	queue_redraw()


func _draw() -> void:
	var origin: Vector2 = Vector2(-RACK_WIDTH * 0.5, -RACK_HEIGHT * 0.5)
	# Shadow behind rack
	draw_rect(Rect2(origin + Vector2(4.0, 6.0), Vector2(RACK_WIDTH, RACK_HEIGHT)), RACK_SHADOW, true)
	# Rack board
	draw_rect(Rect2(origin, Vector2(RACK_WIDTH, RACK_HEIGHT)), RACK_BASE, true)
	# Trim
	draw_rect(Rect2(origin + Vector2(4.0, 4.0), Vector2(RACK_WIDTH - 8.0, RACK_HEIGHT - 8.0)), Color(0.247059, 0.172549, 0.0980392, 1.0), true)
	# Hooks (drawn as small horizontal nails)
	var hook_y_tape: float = origin.y + 38.0
	var hook_y_bucket: float = origin.y + 108.0
	draw_line(Vector2(origin.x + 12.0, hook_y_tape), Vector2(origin.x + RACK_WIDTH - 12.0, hook_y_tape), HOOK_COLOR, 2.0, true)
	draw_line(Vector2(origin.x + 12.0, hook_y_bucket), Vector2(origin.x + RACK_WIDTH - 12.0, hook_y_bucket), HOOK_COLOR, 2.0, true)
	# Tape on its hook
	if state == SlotState.BOTH or state == SlotState.TAPE_ONLY:
		_draw_tape_roll(Vector2(0.0, origin.y + 58.0))
	else:
		_draw_empty_label(Vector2(0.0, origin.y + 58.0), "ماخوذ")
	# Bucket on its hook
	if state == SlotState.BOTH or state == SlotState.BUCKET_ONLY:
		_draw_bucket(Vector2(0.0, origin.y + 132.0))
	else:
		_draw_empty_label(Vector2(0.0, origin.y + 132.0), "ماخوذ")
	# Bureaucratic top sticker
	_draw_sticker(Vector2(0.0, origin.y + 16.0), Vector2(96.0, 18.0), 0.04, "أدوات المناوبة")


func _draw_tape_roll(center: Vector2) -> void:
	draw_circle(center + Vector2(2.0, 3.0), 22.0, RACK_SHADOW)
	draw_circle(center, 22.0, TAPE_COLOR)
	draw_circle(center, 10.0, TAPE_STRIPE)
	draw_circle(center, 5.0, TAPE_HOLE)
	draw_arc(center, 16.0, 0.0, TAU, 24, TAPE_STRIPE, 1.4, true)


func _draw_bucket(center: Vector2) -> void:
	var top_left: Vector2 = center + Vector2(-22.0, -16.0)
	var top_right: Vector2 = center + Vector2(22.0, -16.0)
	var bottom_left: Vector2 = center + Vector2(-15.0, 18.0)
	var bottom_right: Vector2 = center + Vector2(15.0, 18.0)
	var shadow_offset: Vector2 = Vector2(3.0, 4.0)
	draw_colored_polygon(PackedVector2Array([top_left + shadow_offset, top_right + shadow_offset, bottom_right + shadow_offset, bottom_left + shadow_offset]), RACK_SHADOW)
	draw_colored_polygon(PackedVector2Array([top_left, top_right, bottom_right, bottom_left]), BUCKET_COLOR)
	draw_line(top_left, top_right, BUCKET_RIM, 3.0, true)
	draw_line(top_left, bottom_left, BUCKET_RIM, 1.5, true)
	draw_line(top_right, bottom_right, BUCKET_RIM, 1.5, true)
	draw_line(bottom_left, bottom_right, BUCKET_RIM, 1.5, true)
	# Handle
	draw_arc(center + Vector2(0.0, -16.0), 18.0, PI * 1.05, PI * 1.95, 16, BUCKET_RIM, 1.8, true)


func _draw_empty_label(center: Vector2, text: String) -> void:
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 12
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size)
	var rect_size: Vector2 = Vector2(text_size.x + 16.0, 22.0)
	var rect: Rect2 = Rect2(center - rect_size * 0.5, rect_size)
	draw_rect(rect, Color(0.117647, 0.0784314, 0.0509804, 0.9), true)
	draw_rect(rect, Color(0.580392, 0.419608, 0.243137, 1.0), false, 1.2)
	draw_string(font, Vector2(-text_size.x * 0.5, float(font_size) * 0.3), text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size, Color(0.580392, 0.419608, 0.243137, 1.0))


func _draw_sticker(center_position: Vector2, sticker_size: Vector2, angle: float, text: String) -> void:
	var transform: Transform2D = Transform2D(angle, center_position)
	draw_set_transform_matrix(transform)
	var rect: Rect2 = Rect2(-sticker_size * 0.5, sticker_size)
	draw_rect(Rect2(rect.position + Vector2(1.5, 2.0), rect.size), Color(0.0, 0.0, 0.0, 0.4), true)
	draw_rect(rect, STICKER_BG, true)
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 11
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size)
	draw_string(font, Vector2(-text_size.x * 0.5, float(font_size) * 0.32), text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size, STICKER_TEXT)
	draw_set_transform_matrix(Transform2D.IDENTITY)
