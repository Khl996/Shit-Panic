extends Node2D

const RADIO_WIDTH: float = 64.0
const RADIO_HEIGHT: float = 44.0
const BODY_COLOR: Color = Color(0.231373, 0.121569, 0.0901961, 1.0)
const BODY_HIGHLIGHT: Color = Color(0.376471, 0.262745, 0.156863, 1.0)
const SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.5)
const GRILL_COLOR: Color = Color(0.117647, 0.0509804, 0.0392157, 1.0)
const KNOB_COLOR: Color = Color(0.541176, 0.380392, 0.219608, 1.0)
const KNOB_SHADOW: Color = Color(0.0, 0.0, 0.0, 0.65)
const LED_OFF: Color = Color(0.180392, 0.0823529, 0.0588235, 1.0)
const LED_ACTIVE: Color = Color(0.952941, 0.227451, 0.180392, 1.0)
const LED_GLOW: Color = Color(1.0, 0.5, 0.3, 0.4)

var _blink_active: bool = false
var _blink_time: float = 0.0


func _ready() -> void:
	z_index = 6
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	if _blink_active:
		_blink_time += delta
		queue_redraw()


func set_blink_active(active: bool) -> void:
	if _blink_active == active:
		return
	_blink_active = active
	if not active:
		_blink_time = 0.0
	queue_redraw()


func _draw() -> void:
	var origin: Vector2 = Vector2(-RADIO_WIDTH * 0.5, -RADIO_HEIGHT * 0.5)
	draw_rect(Rect2(origin + Vector2(2.5, 3.5), Vector2(RADIO_WIDTH, RADIO_HEIGHT)), SHADOW_COLOR, true)
	draw_rect(Rect2(origin, Vector2(RADIO_WIDTH, RADIO_HEIGHT)), BODY_COLOR, true)
	draw_line(origin, origin + Vector2(RADIO_WIDTH, 0.0), BODY_HIGHLIGHT, 1.5, true)
	# Grill
	var grill_rect: Rect2 = Rect2(origin + Vector2(6.0, 8.0), Vector2(RADIO_WIDTH * 0.55, RADIO_HEIGHT - 16.0))
	draw_rect(grill_rect, GRILL_COLOR, true)
	var grill_line_count: int = 6
	for index: int in range(grill_line_count):
		var line_y: float = grill_rect.position.y + 3.0 + float(index) * 4.0
		draw_line(Vector2(grill_rect.position.x + 3.0, line_y), Vector2(grill_rect.position.x + grill_rect.size.x - 3.0, line_y), Color(0.0, 0.0, 0.0, 0.55), 1.0, true)
	# Knob
	var knob_center: Vector2 = origin + Vector2(RADIO_WIDTH - 14.0, RADIO_HEIGHT * 0.5)
	draw_circle(knob_center + Vector2(1.0, 2.0), 8.0, KNOB_SHADOW)
	draw_circle(knob_center, 7.5, KNOB_COLOR)
	draw_line(knob_center, knob_center + Vector2(4.0, -3.0), Color(0.0, 0.0, 0.0, 0.85), 1.5, true)
	# LED
	var led_center: Vector2 = origin + Vector2(RADIO_WIDTH - 14.0, 10.0)
	var led_color: Color = LED_OFF
	if _blink_active:
		var pulse: float = (sin(_blink_time * 9.0) + 1.0) * 0.5
		led_color = LED_OFF.lerp(LED_ACTIVE, 0.4 + pulse * 0.6)
		draw_circle(led_center, 9.0 + pulse * 4.0, Color(LED_GLOW.r, LED_GLOW.g, LED_GLOW.b, LED_GLOW.a * (0.4 + pulse * 0.6)))
	draw_circle(led_center, 4.0, led_color)
	draw_arc(led_center, 4.5, 0.0, TAU, 16, Color(0.0, 0.0, 0.0, 0.8), 1.0, true)
