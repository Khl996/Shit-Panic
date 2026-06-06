extends Control

const DESK_BASE: Color = Color(0.180392, 0.117647, 0.0784314, 1.0)
const DESK_HIGHLIGHT: Color = Color(0.270588, 0.176471, 0.117647, 1.0)
const DESK_SHADOW: Color = Color(0.0901961, 0.0588235, 0.0392157, 1.0)
const GRAIN_LIGHT: Color = Color(0.290196, 0.196078, 0.137255, 0.55)
const GRAIN_DARK: Color = Color(0.0509804, 0.0313726, 0.0156863, 0.45)
const STAIN_COLOR: Color = Color(0.117647, 0.0666667, 0.0313726, 0.35)
const SCREW_HEAD: Color = Color(0.564706, 0.482353, 0.345098, 1.0)
const SCREW_SHADOW: Color = Color(0.137255, 0.0941176, 0.0509804, 1.0)
const NOTE_YELLOW: Color = Color(0.984314, 0.882353, 0.4, 1.0)
const NOTE_PINK: Color = Color(0.952941, 0.745098, 0.694118, 1.0)
const NOTE_GREEN: Color = Color(0.811765, 0.866667, 0.611765, 1.0)
const NOTE_TEXT: Color = Color(0.227451, 0.176471, 0.117647, 1.0)
const NOTE_SHADOW: Color = Color(0.0392157, 0.0235294, 0.0117647, 0.45)
const CABLE_COLOR: Color = Color(0.0431373, 0.0313726, 0.0235294, 0.85)
const CABLE_HIGHLIGHT: Color = Color(0.196078, 0.156863, 0.105882, 0.6)
const GRAIN_LINE_COUNT: int = 110
const GRAIN_SEED: int = 9123
const DEFAULT_VIEWPORT_SIZE: Vector2 = Vector2(1280.0, 720.0)


func _ready() -> void:
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var draw_size: Vector2 = size
	if draw_size.x < 1.0 or draw_size.y < 1.0:
		draw_size = DEFAULT_VIEWPORT_SIZE
	_draw_desk_surface(draw_size)
	_draw_wood_grain(draw_size)
	_draw_coffee_stains(draw_size)
	_draw_cable_clutter(draw_size)
	_draw_sticky_notes(draw_size)
	_draw_corner_screws(draw_size)


func _draw_desk_surface(draw_size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, draw_size), DESK_BASE, true)
	var highlight_rect: Rect2 = Rect2(
		Vector2(0.0, 0.0),
		Vector2(draw_size.x, draw_size.y * 0.42)
	)
	draw_rect(highlight_rect, DESK_HIGHLIGHT, true)
	var shadow_rect: Rect2 = Rect2(
		Vector2(0.0, draw_size.y * 0.72),
		Vector2(draw_size.x, draw_size.y * 0.28)
	)
	draw_rect(shadow_rect, DESK_SHADOW, true)


func _draw_wood_grain(draw_size: Vector2) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = GRAIN_SEED
	for line_index: int in range(GRAIN_LINE_COUNT):
		var y: float = rng.randf_range(0.0, draw_size.y)
		var sway: float = rng.randf_range(-6.0, 6.0)
		var thickness: float = rng.randf_range(0.4, 1.6)
		var color: Color = GRAIN_LIGHT if (line_index % 2 == 0) else GRAIN_DARK
		var start: Vector2 = Vector2(0.0, y)
		var mid: Vector2 = Vector2(draw_size.x * 0.5, y + sway)
		var stop: Vector2 = Vector2(draw_size.x, y + sway * 0.4)
		draw_line(start, mid, color, thickness, true)
		draw_line(mid, stop, color, thickness, true)


func _draw_coffee_stains(draw_size: Vector2) -> void:
	var stains: Array[Vector3] = [
		Vector3(draw_size.x * 0.18, draw_size.y * 0.34, 46.0),
		Vector3(draw_size.x * 0.78, draw_size.y * 0.62, 58.0),
		Vector3(draw_size.x * 0.46, draw_size.y * 0.83, 38.0),
	]
	for stain: Vector3 in stains:
		var center: Vector2 = Vector2(stain.x, stain.y)
		var radius: float = stain.z
		draw_circle(center, radius, STAIN_COLOR)
		draw_arc(center, radius * 0.92, 0.0, TAU, 48, Color(STAIN_COLOR.r, STAIN_COLOR.g, STAIN_COLOR.b, 0.55), 2.0, true)
		draw_arc(center, radius * 0.55, 0.0, TAU, 36, Color(STAIN_COLOR.r, STAIN_COLOR.g, STAIN_COLOR.b, 0.4), 1.5, true)


func _draw_cable_clutter(draw_size: Vector2) -> void:
	var cable_y: float = draw_size.y - 36.0
	var points: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, cable_y + 8.0),
		Vector2(draw_size.x * 0.15, cable_y - 14.0),
		Vector2(draw_size.x * 0.32, cable_y + 4.0),
		Vector2(draw_size.x * 0.52, cable_y - 22.0),
		Vector2(draw_size.x * 0.71, cable_y + 6.0),
		Vector2(draw_size.x * 0.88, cable_y - 12.0),
		Vector2(draw_size.x, cable_y + 10.0),
	])
	for index: int in range(points.size() - 1):
		draw_line(points[index], points[index + 1], CABLE_COLOR, 6.0, true)
		var highlight_offset: Vector2 = Vector2(0.0, -1.5)
		draw_line(points[index] + highlight_offset, points[index + 1] + highlight_offset, CABLE_HIGHLIGHT, 1.5, true)


func _draw_sticky_notes(draw_size: Vector2) -> void:
	var notes: Array[Dictionary] = [
		{
			"position": Vector2(draw_size.x * 0.04, draw_size.y * 0.55),
			"size": Vector2(96.0, 78.0),
			"color": NOTE_YELLOW,
			"angle": -0.12,
			"text": "المدير\nنايم",
		},
		{
			"position": Vector2(draw_size.x * 0.85, draw_size.y * 0.12),
			"size": Vector2(102.0, 70.0),
			"color": NOTE_PINK,
			"angle": 0.09,
			"text": "لا تنسى\nالشطرطون",
		},
		{
			"position": Vector2(draw_size.x * 0.02, draw_size.y * 0.18),
			"size": Vector2(86.0, 66.0),
			"color": NOTE_GREEN,
			"angle": 0.07,
			"text": "ابتسم\nانت مراقب",
		},
	]
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 13
	for note: Dictionary in notes:
		_draw_sticky_note(
			note["position"] as Vector2,
			note["size"] as Vector2,
			note["color"] as Color,
			float(note["angle"]),
			str(note["text"]),
			font,
			font_size
		)


func _draw_sticky_note(
	position_xy: Vector2,
	note_size: Vector2,
	color: Color,
	angle: float,
	text: String,
	font: Font,
	font_size: int
) -> void:
	var shadow_offset: Vector2 = Vector2(4.0, 6.0)
	var transform: Transform2D = Transform2D(angle, position_xy + note_size * 0.5)
	draw_set_transform_matrix(transform)
	var rect: Rect2 = Rect2(-note_size * 0.5, note_size)
	draw_rect(Rect2(-note_size * 0.5 + shadow_offset, note_size), NOTE_SHADOW, true)
	draw_rect(rect, color, true)
	var pin_center: Vector2 = Vector2(0.0, -note_size.y * 0.5 + 8.0)
	draw_circle(pin_center, 4.0, Color(0.235, 0.156, 0.0863, 1.0))
	draw_circle(pin_center + Vector2(-1.0, -1.0), 1.6, Color(0.96, 0.88, 0.62, 1.0))
	var lines: PackedStringArray = text.split("\n")
	var line_height: float = float(font_size) + 4.0
	var start_y: float = -((float(lines.size()) - 1.0) * line_height * 0.5) - float(font_size) * 0.25
	for line_index: int in range(lines.size()):
		var line_text: String = lines[line_index]
		var text_size: Vector2 = font.get_string_size(line_text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size)
		var draw_position: Vector2 = Vector2(-text_size.x * 0.5, start_y + float(line_index) * line_height)
		draw_string(
			font,
			draw_position,
			line_text,
			HORIZONTAL_ALIGNMENT_CENTER,
			-1.0,
			font_size,
			NOTE_TEXT
		)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_corner_screws(draw_size: Vector2) -> void:
	var inset: float = 28.0
	var screws: Array[Vector2] = [
		Vector2(inset, inset),
		Vector2(draw_size.x - inset, inset),
		Vector2(inset, draw_size.y - inset),
		Vector2(draw_size.x - inset, draw_size.y - inset),
	]
	for center: Vector2 in screws:
		draw_circle(center + Vector2(1.6, 1.6), 7.0, SCREW_SHADOW)
		draw_circle(center, 6.5, SCREW_HEAD)
		var slot_a_start: Vector2 = center + Vector2(-4.0, -1.5)
		var slot_a_end: Vector2 = center + Vector2(4.0, 1.5)
		draw_line(slot_a_start, slot_a_end, SCREW_SHADOW, 1.6, true)
