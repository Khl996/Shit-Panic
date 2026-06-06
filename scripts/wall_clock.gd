extends Node2D

const CLOCK_RADIUS: float = 36.0
const FRAME_COLOR: Color = Color(0.541176, 0.380392, 0.219608, 1.0)
const FACE_COLOR: Color = Color(0.937255, 0.901961, 0.811765, 1.0)
const TICK_COLOR: Color = Color(0.180392, 0.117647, 0.0784314, 1.0)
const HAND_COLOR: Color = Color(0.180392, 0.117647, 0.0784314, 1.0)
const HAND_ACCENT: Color = Color(0.788235, 0.247059, 0.180392, 1.0)
const SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.45)

var elapsed_fraction: float = 0.0  # 0 = full shift left, 1 = end


func _ready() -> void:
	z_index = 5
	queue_redraw()


func set_elapsed_fraction(fraction: float) -> void:
	elapsed_fraction = clampf(fraction, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	# Shadow
	draw_circle(Vector2(2.5, 4.0), CLOCK_RADIUS + 4.0, SHADOW_COLOR)
	# Frame
	draw_circle(Vector2.ZERO, CLOCK_RADIUS + 4.0, FRAME_COLOR)
	# Face
	draw_circle(Vector2.ZERO, CLOCK_RADIUS, FACE_COLOR)
	# Hour ticks
	for hour: int in range(12):
		var angle: float = float(hour) * (TAU / 12.0) - PI * 0.5
		var outer: Vector2 = Vector2(cos(angle), sin(angle)) * (CLOCK_RADIUS - 2.0)
		var inner: Vector2 = Vector2(cos(angle), sin(angle)) * (CLOCK_RADIUS - 8.0)
		var thickness: float = 2.4 if hour % 3 == 0 else 1.2
		draw_line(inner, outer, TICK_COLOR, thickness, true)
	# Minute hand sweeps through the full shift (one revolution per round)
	var minute_angle: float = elapsed_fraction * TAU - PI * 0.5
	var minute_tip: Vector2 = Vector2(cos(minute_angle), sin(minute_angle)) * (CLOCK_RADIUS - 6.0)
	draw_line(Vector2.ZERO, minute_tip, HAND_COLOR, 3.2, true)
	# Hour hand at 11 o'clock-ish for late-night vibe
	var hour_angle: float = -PI * 0.5 + TAU * (11.0 / 12.0)
	var hour_tip: Vector2 = Vector2(cos(hour_angle), sin(hour_angle)) * (CLOCK_RADIUS - 14.0)
	draw_line(Vector2.ZERO, hour_tip, HAND_COLOR, 4.0, true)
	# Center cap
	draw_circle(Vector2.ZERO, 3.5, HAND_ACCENT)
	# Bottom label
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 10
	var label: String = "آخر الليل"
	var text_size: Vector2 = font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size)
	draw_string(font, Vector2(-text_size.x * 0.5, CLOCK_RADIUS * 0.55), label, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size, TICK_COLOR)
