extends Node2D

enum LeakState {
	DRY,
	LEAKING,
	TAPE_PATCHED,
	BUCKET_PLACED,
	TAPE_FAILED,
}

const RACK_SIZE: Vector2 = Vector2(150.0, 190.0)
const RACK_BODY: Color = Color(0.105882, 0.121569, 0.133333, 1.0)
const RACK_SIDE: Color = Color(0.047059, 0.058824, 0.070588, 1.0)
const RACK_TRIM: Color = Color(0.243137, 0.317647, 0.313726, 1.0)
const SERVER_LIGHT: Color = Color(0.411765, 0.717647, 0.682353, 1.0)
const WARNING_COLOR: Color = Color(0.831373, 0.603922, 0.164706, 1.0)
const DANGER_COLOR: Color = Color(0.788235, 0.294118, 0.258824, 1.0)
const WATER_COLOR: Color = Color(0.321569, 0.674510, 0.831373, 0.82)
const WATER_DARK: Color = Color(0.125490, 0.309804, 0.447059, 0.55)
const TAPE_COLOR: Color = Color(0.937255, 0.870588, 0.682353, 1.0)
const BUCKET_COLOR: Color = Color(0.611765, 0.611765, 0.643137, 1.0)
const PAPER_COLOR: Color = Color(0.937255, 0.882353, 0.733333, 1.0)
const TEXT_COLOR: Color = Color(0.180392, 0.117647, 0.0784314, 1.0)

var state: int = LeakState.DRY
var _time: float = 0.0
var _label: String = "السيرفر"


func _ready() -> void:
	z_index = 4
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if state != LeakState.DRY:
		queue_redraw()


func set_state(new_state: int) -> void:
	if state == new_state:
		return
	state = new_state
	queue_redraw()


func set_label(text: String) -> void:
	_label = text
	queue_redraw()


func _draw() -> void:
	_draw_floor_zone()
	_draw_ac_unit()
	_draw_rack()
	_draw_state_overlay()
	_draw_label()


func _draw_floor_zone() -> void:
	var zone_color: Color = Color(0.078431, 0.101961, 0.105882, 0.58)
	var border_color: Color = Color(0.274510, 0.352941, 0.349020, 0.9)
	if state == LeakState.LEAKING or state == LeakState.TAPE_FAILED:
		var pulse: float = (sin(_time * 8.0) + 1.0) * 0.5
		border_color = WARNING_COLOR.lerp(DANGER_COLOR, pulse)
	draw_rect(Rect2(Vector2(-105.0, -138.0), Vector2(210.0, 284.0)), zone_color, true)
	draw_rect(Rect2(Vector2(-105.0, -138.0), Vector2(210.0, 284.0)), border_color, false, 3.0)


func _draw_ac_unit() -> void:
	var unit_rect: Rect2 = Rect2(Vector2(-78.0, -132.0), Vector2(156.0, 34.0))
	draw_rect(Rect2(unit_rect.position + Vector2(3.0, 4.0), unit_rect.size), Color(0, 0, 0, 0.35), true)
	draw_rect(unit_rect, Color(0.784314, 0.788235, 0.741176, 1.0), true)
	draw_rect(unit_rect, Color(0.349020, 0.349020, 0.321569, 1.0), false, 2.0)
	for index: int in range(5):
		var x: float = unit_rect.position.x + 18.0 + float(index) * 26.0
		draw_line(Vector2(x, unit_rect.position.y + 9.0), Vector2(x + 13.0, unit_rect.position.y + 23.0), Color(0.349020, 0.349020, 0.321569, 0.7), 2.0, true)
	if state == LeakState.LEAKING or state == LeakState.TAPE_FAILED:
		var drip_x: float = sin(_time * 5.0) * 10.0
		draw_circle(Vector2(drip_x, -88.0 + fmod(_time * 44.0, 36.0)), 3.5, WATER_COLOR)


func _draw_rack() -> void:
	var origin: Vector2 = -RACK_SIZE * 0.5
	draw_rect(Rect2(origin + Vector2(5.0, 8.0), RACK_SIZE), Color(0, 0, 0, 0.55), true)
	draw_rect(Rect2(origin, RACK_SIZE), RACK_BODY, true)
	draw_rect(Rect2(origin, Vector2(18.0, RACK_SIZE.y)), RACK_SIDE, true)
	draw_rect(Rect2(origin + Vector2(RACK_SIZE.x - 18.0, 0.0), Vector2(18.0, RACK_SIZE.y)), RACK_SIDE, true)
	draw_rect(Rect2(origin, RACK_SIZE), RACK_TRIM, false, 3.0)
	for shelf_index: int in range(5):
		var shelf_y: float = origin.y + 22.0 + float(shelf_index) * 31.0
		draw_rect(Rect2(Vector2(origin.x + 22.0, shelf_y), Vector2(RACK_SIZE.x - 44.0, 18.0)), Color(0.027451, 0.039216, 0.043137, 1.0), true)
		var blink: float = (sin(_time * 5.0 + float(shelf_index)) + 1.0) * 0.5
		var led_color: Color = SERVER_LIGHT.lerp(WARNING_COLOR, blink if state == LeakState.LEAKING else 0.0)
		if state == LeakState.TAPE_FAILED:
			led_color = DANGER_COLOR
		draw_circle(Vector2(origin.x + 34.0, shelf_y + 9.0), 3.0, led_color)
		draw_rect(Rect2(Vector2(origin.x + 46.0, shelf_y + 6.0), Vector2(46.0, 4.0)), Color(SERVER_LIGHT.r, SERVER_LIGHT.g, SERVER_LIGHT.b, 0.45), true)


func _draw_state_overlay() -> void:
	match state:
		LeakState.LEAKING:
			_draw_puddle(1.0)
			_draw_warning_burst("مويه!")
		LeakState.TAPE_PATCHED:
			_draw_tape_patch(false)
		LeakState.BUCKET_PLACED:
			_draw_bucket()
		LeakState.TAPE_FAILED:
			_draw_puddle(1.25)
			_draw_tape_patch(true)
			_draw_warning_burst("الشطرطون خان!")


func _draw_puddle(scale_amount: float) -> void:
	var center: Vector2 = Vector2(0.0, 112.0)
	_draw_ellipse(center, Vector2(62.0, 18.0) * scale_amount, WATER_DARK)
	_draw_ellipse(center + Vector2(-9.0, -3.0), Vector2(38.0, 10.0) * scale_amount, WATER_COLOR)
	for index: int in range(3):
		var drop_y: float = -62.0 + fmod((_time * 55.0) + float(index) * 22.0, 116.0)
		draw_circle(Vector2(-12.0 + float(index) * 12.0, drop_y), 2.2, WATER_COLOR)


func _draw_tape_patch(failed: bool) -> void:
	var center: Vector2 = Vector2(0.0, -88.0)
	var angle: float = -0.12 if not failed else 0.22
	var transform: Transform2D = Transform2D(angle, center)
	draw_set_transform_matrix(transform)
	var rect: Rect2 = Rect2(Vector2(-56.0, -9.0), Vector2(112.0, 18.0))
	draw_rect(rect, TAPE_COLOR, true)
	draw_rect(rect, Color(0.549020, 0.466667, 0.270588, 1.0), false, 1.6)
	if failed:
		draw_line(Vector2(-36.0, -9.0), Vector2(-18.0, 9.0), DANGER_COLOR, 3.0, true)
		draw_line(Vector2(22.0, -9.0), Vector2(38.0, 9.0), DANGER_COLOR, 3.0, true)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_bucket() -> void:
	var center: Vector2 = Vector2(0.0, 104.0)
	var top_left: Vector2 = center + Vector2(-24.0, -18.0)
	var top_right: Vector2 = center + Vector2(24.0, -18.0)
	var bottom_left: Vector2 = center + Vector2(-16.0, 18.0)
	var bottom_right: Vector2 = center + Vector2(16.0, 18.0)
	draw_colored_polygon(PackedVector2Array([top_left + Vector2(3, 4), top_right + Vector2(3, 4), bottom_right + Vector2(3, 4), bottom_left + Vector2(3, 4)]), Color(0, 0, 0, 0.4))
	draw_colored_polygon(PackedVector2Array([top_left, top_right, bottom_right, bottom_left]), BUCKET_COLOR)
	draw_line(top_left, top_right, Color(0.388235, 0.388235, 0.423529, 1), 3.0, true)
	draw_line(bottom_left, bottom_right, Color(0.388235, 0.388235, 0.423529, 1), 2.0, true)
	draw_arc(center + Vector2(0.0, -18.0), 19.0, PI * 1.05, PI * 1.95, 16, Color(0.388235, 0.388235, 0.423529, 1), 1.8, true)


func _draw_warning_burst(text: String) -> void:
	var pulse: float = (sin(_time * 9.0) + 1.0) * 0.5
	var rect_size: Vector2 = Vector2(146.0 + pulse * 8.0, 34.0 + pulse * 4.0)
	var rect: Rect2 = Rect2(Vector2(-rect_size.x * 0.5, -174.0), rect_size)
	draw_rect(rect, WARNING_COLOR.lerp(DANGER_COLOR, pulse), true)
	draw_rect(rect, Color(0.180392, 0.117647, 0.078431, 1.0), false, 2.0)
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 16
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size)
	draw_string(font, rect.position + Vector2((rect.size.x - text_size.x) * 0.5, 22.0), text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size, TEXT_COLOR)


func _draw_label() -> void:
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 13
	var text_size: Vector2 = font.get_string_size(_label, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size)
	var rect_size: Vector2 = Vector2(text_size.x + 22.0, 25.0)
	var rect: Rect2 = Rect2(Vector2(-rect_size.x * 0.5, 148.0), rect_size)
	draw_rect(Rect2(rect.position + Vector2(2.0, 2.0), rect.size), Color(0, 0, 0, 0.35), true)
	draw_rect(rect, PAPER_COLOR, true)
	draw_rect(rect, TEXT_COLOR, false, 1.3)
	draw_string(font, Vector2(-text_size.x * 0.5, 165.0), _label, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size, TEXT_COLOR)


func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for index: int in range(28):
		var angle: float = (float(index) / 28.0) * TAU
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
