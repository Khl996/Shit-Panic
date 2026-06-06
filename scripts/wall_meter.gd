extends Node2D

const METER_RADIUS: float = 38.0
const FRAME_COLOR: Color = Color(0.494118, 0.34902, 0.196078, 1.0)
const FACE_COLOR: Color = Color(0.917647, 0.870588, 0.741176, 1.0)
const STABLE_COLOR: Color = Color(0.345098, 0.572549, 0.443137, 1.0)
const WARNING_COLOR: Color = Color(0.831373, 0.541176, 0.156863, 1.0)
const DANGER_COLOR: Color = Color(0.737255, 0.196078, 0.156863, 1.0)
const NEEDLE_COLOR: Color = Color(0.180392, 0.117647, 0.0784314, 1.0)
const NEEDLE_ACCENT: Color = Color(0.788235, 0.247059, 0.180392, 1.0)
const SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.45)
const LABEL_COLOR: Color = Color(0.180392, 0.117647, 0.0784314, 1.0)

const START_ANGLE: float = PI * 0.85
const END_ANGLE: float = PI * 0.15
const STABLE_RATIO: float = 0.5
const WARNING_RATIO: float = 0.78

var value: float = 50.0
var label: String = ""
var fault: bool = false


func _ready() -> void:
	z_index = 5
	queue_redraw()


func configure(meter_label: String) -> void:
	label = meter_label
	queue_redraw()


func set_value(new_value: float, sensor_fault: bool = false) -> void:
	value = clampf(new_value, 0.0, 100.0)
	fault = sensor_fault
	queue_redraw()


func _draw() -> void:
	# Shadow
	draw_circle(Vector2(2.0, 3.5), METER_RADIUS + 3.0, SHADOW_COLOR)
	# Frame
	draw_circle(Vector2.ZERO, METER_RADIUS + 3.0, FRAME_COLOR)
	# Face
	draw_circle(Vector2.ZERO, METER_RADIUS, FACE_COLOR)
	# Status arc bands
	_draw_band(STABLE_COLOR, 0.0, STABLE_RATIO)
	_draw_band(WARNING_COLOR, STABLE_RATIO, WARNING_RATIO)
	_draw_band(DANGER_COLOR, WARNING_RATIO, 1.0)
	# Tick marks
	var tick_count: int = 10
	for tick_index: int in range(tick_count + 1):
		var ratio: float = float(tick_index) / float(tick_count)
		var angle: float = lerp(START_ANGLE, START_ANGLE - (TAU * 0.7), ratio)
		var outer: Vector2 = Vector2(cos(angle), sin(angle)) * (METER_RADIUS - 4.0)
		var inner: Vector2 = Vector2(cos(angle), sin(angle)) * (METER_RADIUS - 9.0)
		draw_line(inner, outer, LABEL_COLOR, 1.2, true)
	# Needle
	var needle_ratio: float = clampf(value / 100.0, 0.0, 1.0)
	var needle_angle: float = lerp(START_ANGLE, START_ANGLE - (TAU * 0.7), needle_ratio)
	if fault:
		needle_angle += sin(Time.get_ticks_msec() * 0.025) * 0.18
	var needle_tip: Vector2 = Vector2(cos(needle_angle), sin(needle_angle)) * (METER_RADIUS - 7.0)
	var needle_base: Vector2 = Vector2(cos(needle_angle + PI), sin(needle_angle + PI)) * 6.0
	draw_line(needle_base, needle_tip, NEEDLE_COLOR, 2.6, true)
	draw_circle(Vector2.ZERO, 4.5, NEEDLE_ACCENT)
	# Label
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 11
	var text_size: Vector2 = font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size)
	draw_string(font, Vector2(-text_size.x * 0.5, METER_RADIUS - 4.0), label, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size, LABEL_COLOR)
	if fault:
		var fault_label: String = "؟!"
		var fault_size: Vector2 = font.get_string_size(fault_label, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size)
		draw_string(font, Vector2(-fault_size.x * 0.5, -METER_RADIUS * 0.2), fault_label, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size, DANGER_COLOR)


func _draw_band(color: Color, from_ratio: float, to_ratio: float) -> void:
	var from_angle: float = lerp(START_ANGLE, START_ANGLE - (TAU * 0.7), from_ratio)
	var to_angle: float = lerp(START_ANGLE, START_ANGLE - (TAU * 0.7), to_ratio)
	var radius: float = METER_RADIUS - 6.0
	draw_arc(Vector2.ZERO, radius, from_angle, to_angle, 24, color, 4.5, true)
