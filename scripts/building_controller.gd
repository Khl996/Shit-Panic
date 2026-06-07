extends Node2D

# The new core loop. Hazards spawn faster and faster across the building. The
# player runs between them and holds SPACE to fix the nearest one. One health
# bar. Survive as long as you can; lose with a screenshot-worthy verdict.

const HazardScript = preload("res://scripts/hazard.gd")

const FIX_RADIUS: float = 84.0
const SPAWN_INTERVAL_START: float = 3.6
const SPAWN_INTERVAL_MIN: float = 0.95
const SPAWN_RAMP_SECONDS: float = 110.0
const MAX_HAZARDS: int = 9
const MIN_SPAWN_DISTANCE: float = 130.0

const SPAWN_POINTS: Array[Vector2] = [
	Vector2(170.0, 200.0), Vector2(360.0, 160.0), Vector2(560.0, 220.0),
	Vector2(760.0, 170.0), Vector2(980.0, 210.0), Vector2(1110.0, 320.0),
	Vector2(220.0, 420.0), Vector2(430.0, 470.0), Vector2(900.0, 470.0),
	Vector2(1080.0, 520.0), Vector2(320.0, 600.0), Vector2(640.0, 610.0),
	Vector2(840.0, 600.0),
]

const HEALTH_GOOD: Color = Color(0.42, 0.78, 0.5, 1.0)
const HEALTH_WARN: Color = Color(0.93, 0.72, 0.24, 1.0)
const HEALTH_BAD: Color = Color(0.88, 0.29, 0.25, 1.0)
const PAPER: Color = Color(0.94, 0.88, 0.73, 1.0)

@export var development_controls_enabled: bool = false

var building_state: BuildingState
var audio: AudioFeedbackController
var _hazards: Array[Hazard] = []
var _spawn_timer: float = 2.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _outcome_reported: bool = false
var _fixing_hazard: Hazard = null

# camera shake
var _shake_intensity: float = 0.0
var _shake_remaining: float = 0.0
var _shake_time: float = 0.0

# intro
var _intro_active: bool = true
var _intro_overlay: Control
var _intro_dim: ColorRect

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera
@onready var hazard_layer: Node2D = $HazardLayer
@onready var hud: CanvasLayer = $HUD

var _health_label: Label
var _health_bar_bg: ColorRect
var _health_bar_fill: ColorRect
var _timer_label: Label
var _fixed_label: Label
var _prompt_label: Label
var _result_overlay: Control
var _result_panel: PanelContainer
var _result_title: Label
var _result_body: Label
var _retry_button: Button


func _ready() -> void:
	_rng.randomize()
	building_state = BuildingState.new()
	audio = AudioFeedbackController.new()
	audio.configure(self)
	_build_hud()
	_build_result_overlay()
	_build_intro_overlay()
	_reset()
	_play_intro()


func _process(delta: float) -> void:
	if _intro_active:
		return
	if building_state.round_state == BuildingState.RoundState.RUNNING:
		_update_hazards(delta)
		var total_danger: float = 0.0
		var active: int = 0
		for hz: Hazard in _hazards:
			if hz.is_active():
				total_danger += hz.get_danger()
				active += 1
		building_state.advance(delta, total_danger, active)
		_update_spawning(delta)
		if building_state.is_lost():
			_finish()
	_update_camera_shake(delta)
	_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if _handle_result_input(event):
		get_viewport().set_input_as_handled()
		return
	if development_controls_enabled and event is InputEventKey and event.pressed and event.ctrl_pressed:
		if (event as InputEventKey).physical_keycode == KEY_R:
			_reset()
			get_viewport().set_input_as_handled()


# --- Hazard fixing + spawning ----------------------------------------------

func _update_hazards(delta: float) -> void:
	var holding_fix: bool = Input.is_key_pressed(KEY_SPACE)
	var nearest: Hazard = _nearest_active_hazard()
	var player_pos: Vector2 = player.position if is_instance_valid(player) else Vector2.ZERO
	var in_reach: bool = nearest != null and player_pos.distance_to(nearest.position) <= FIX_RADIUS
	for hz: Hazard in _hazards:
		if not hz.is_active():
			continue
		if holding_fix and in_reach and hz == nearest:
			hz.apply_fix(delta)
		else:
			hz.decay_fix(delta)


func _nearest_active_hazard() -> Hazard:
	if not is_instance_valid(player):
		return null
	var best: Hazard = null
	var best_d: float = INF
	for hz: Hazard in _hazards:
		if not hz.is_active():
			continue
		var d: float = player.position.distance_to(hz.position)
		if d < best_d:
			best_d = d
			best = hz
	return best


func _on_hazard_fixed(hz: Hazard) -> void:
	building_state.register_fix()
	audio.play(AudioFeedbackController.Cue.WIN)
	_trigger_shake(2.0, 0.18)
	hz.queue_free()
	_hazards.erase(hz)


func _update_spawning(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		return
	var ramp: float = clampf(building_state.elapsed_time / SPAWN_RAMP_SECONDS, 0.0, 1.0)
	var interval: float = lerpf(SPAWN_INTERVAL_START, SPAWN_INTERVAL_MIN, ramp)
	_spawn_timer = interval
	if _count_active() >= MAX_HAZARDS:
		return
	_spawn_hazard()


func _count_active() -> int:
	var c: int = 0
	for hz: Hazard in _hazards:
		if hz.is_active():
			c += 1
	return c


func _spawn_hazard() -> void:
	var spot: Vector2 = _pick_spawn_point()
	if spot == Vector2.INF:
		return
	# Fire and spark get more likely as time goes on.
	var ramp: float = clampf(building_state.elapsed_time / 80.0, 0.0, 1.0)
	var roll: float = _rng.randf()
	var hz_type: int = Hazard.Type.LEAK
	if roll < 0.34 + ramp * 0.2:
		hz_type = Hazard.Type.FIRE
	elif roll < 0.62 + ramp * 0.15:
		hz_type = Hazard.Type.SPARK
	var hz: Hazard = HazardScript.new()
	hz.position = spot
	hazard_layer.add_child(hz)
	hz.setup(hz_type)
	hz.fixed.connect(_on_hazard_fixed)
	_hazards.append(hz)
	if hz_type == Hazard.Type.FIRE:
		audio.play(AudioFeedbackController.Cue.CRITICAL_ALARM)
		_trigger_shake(3.0, 0.25)
	else:
		audio.play(AudioFeedbackController.Cue.WARNING_ALARM)
		_trigger_shake(1.5, 0.15)


func _pick_spawn_point() -> Vector2:
	var candidates: Array[Vector2] = SPAWN_POINTS.duplicate()
	candidates.shuffle()
	for spot: Vector2 in candidates:
		var ok: bool = true
		for hz: Hazard in _hazards:
			if hz.is_active() and hz.position.distance_to(spot) < MIN_SPAWN_DISTANCE:
				ok = false
				break
		if ok:
			return spot
	return Vector2.INF


# --- Camera shake -----------------------------------------------------------

func _update_camera_shake(delta: float) -> void:
	if not is_instance_valid(camera):
		return
	if _shake_remaining > 0.0:
		_shake_remaining = maxf(_shake_remaining - delta, 0.0)
		_shake_time += delta
		var falloff: float = clampf(_shake_remaining / 0.6, 0.0, 1.0)
		var amount: float = _shake_intensity * falloff
		camera.offset = Vector2(sin(_shake_time * 47.0) * amount, cos(_shake_time * 53.0) * amount * 0.75)
	else:
		camera.offset = Vector2.ZERO


func _trigger_shake(intensity: float, duration: float) -> void:
	if intensity < _shake_intensity and _shake_remaining > 0.0:
		return
	_shake_intensity = intensity
	_shake_remaining = duration
	_shake_time = 0.0


# --- HUD --------------------------------------------------------------------

func _build_hud() -> void:
	# Big health bar, top-centre
	var bar_w: float = 560.0
	_health_bar_bg = ColorRect.new()
	_health_bar_bg.color = Color(0.05, 0.05, 0.06, 0.85)
	_health_bar_bg.position = Vector2(640.0 - bar_w * 0.5 - 4.0, 24.0)
	_health_bar_bg.size = Vector2(bar_w + 8.0, 34.0)
	hud.add_child(_health_bar_bg)

	_health_bar_fill = ColorRect.new()
	_health_bar_fill.color = HEALTH_GOOD
	_health_bar_fill.position = Vector2(640.0 - bar_w * 0.5, 28.0)
	_health_bar_fill.size = Vector2(bar_w, 26.0)
	hud.add_child(_health_bar_fill)

	_health_label = _make_label("سلامة المبنى 100%", 18, Vector2(640.0 - bar_w * 0.5, 27.0), bar_w, HORIZONTAL_ALIGNMENT_CENTER)
	_health_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_health_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_health_label.add_theme_constant_override("outline_size", 4)

	_timer_label = _make_label("00:00", 30, Vector2(540.0, 66.0), 200.0, HORIZONTAL_ALIGNMENT_CENTER)
	_timer_label.add_theme_color_override("font_color", PAPER)
	_timer_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_timer_label.add_theme_constant_override("outline_size", 4)

	_fixed_label = _make_label("أصلحت: 0", 16, Vector2(24.0, 24.0), 240.0, HORIZONTAL_ALIGNMENT_LEFT)
	_fixed_label.add_theme_color_override("font_color", PAPER)
	_fixed_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_fixed_label.add_theme_constant_override("outline_size", 3)

	_prompt_label = _make_label("", 20, Vector2(440.0, 650.0), 400.0, HORIZONTAL_ALIGNMENT_CENTER)
	_prompt_label.add_theme_color_override("font_color", PAPER)
	_prompt_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_prompt_label.add_theme_constant_override("outline_size", 5)
	_prompt_label.visible = false


func _make_label(text: String, font_size: int, pos: Vector2, width: float, align: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.text_direction = Control.TEXT_DIRECTION_AUTO
	label.add_theme_font_size_override("font_size", font_size)
	label.position = pos
	label.size = Vector2(width, float(font_size) + 12.0)
	label.horizontal_alignment = align
	hud.add_child(label)
	return label


func _update_hud() -> void:
	if not is_instance_valid(_health_label):
		return
	var ratio: float = building_state.health_ratio()
	var bar_w: float = 560.0
	_health_bar_fill.size = Vector2(bar_w * ratio, 26.0)
	var col: Color = HEALTH_BAD
	if ratio > 0.55:
		col = HEALTH_GOOD
	elif ratio > 0.28:
		col = HEALTH_WARN
	_health_bar_fill.color = col
	_health_label.text = "سلامة المبنى %d%%" % int(roundf(building_state.health))
	_timer_label.text = _format_time(building_state.elapsed_time)
	_fixed_label.text = "أصلحت: %d" % building_state.hazards_fixed
	_update_prompt()


func _update_prompt() -> void:
	if building_state.is_lost():
		_prompt_label.visible = false
		return
	var nearest: Hazard = _nearest_active_hazard()
	if nearest == null:
		_prompt_label.visible = false
		return
	var d: float = player.position.distance_to(nearest.position) if is_instance_valid(player) else INF
	if d <= FIX_RADIUS:
		_prompt_label.text = "[مسافة] استمر بالضغط لإصلاح %s" % nearest.get_label()
		_prompt_label.visible = true
	else:
		_prompt_label.text = "اركض نحو %s وأصلحها" % nearest.get_label()
		_prompt_label.visible = true


func _format_time(seconds: float) -> String:
	var whole: int = int(floorf(maxf(seconds, 0.0)))
	return "%02d:%02d" % [whole / 60, whole % 60]


# --- Round flow -------------------------------------------------------------

func _reset() -> void:
	building_state.reset()
	_outcome_reported = false
	_spawn_timer = 2.0
	for hz: Hazard in _hazards:
		if is_instance_valid(hz):
			hz.queue_free()
	_hazards.clear()
	if is_instance_valid(player) and player is PlayerCharacter:
		(player as PlayerCharacter).reset_pose()
		player.position = Vector2(640.0, 470.0)
	_shake_intensity = 0.0
	_shake_remaining = 0.0
	if is_instance_valid(camera):
		camera.offset = Vector2.ZERO
	if is_instance_valid(_result_overlay):
		_result_overlay.visible = false
	_update_hud()


func _finish() -> void:
	if _outcome_reported:
		return
	_outcome_reported = true
	audio.play(AudioFeedbackController.Cue.LOSS)
	_trigger_shake(9.0, 0.9)
	# Clear remaining hazards visually
	for hz: Hazard in _hazards:
		if is_instance_valid(hz):
			hz.queue_free()
	_hazards.clear()
	_show_result()


func _build_result_overlay() -> void:
	_result_overlay = Control.new()
	_result_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_result_overlay.visible = false
	hud.add_child(_result_overlay)
	var dim: ColorRect = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.74)
	_result_overlay.add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_result_overlay.add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(540.0, 360.0)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.07, 0.05, 0.98)
	style.border_color = HEALTH_BAD
	style.border_width_left = 4
	style.border_width_bottom = 4
	style.border_width_top = 1
	style.border_width_right = 1
	style.corner_radius_top_left = 4
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	_result_panel = panel
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)
	_result_title = Label.new()
	_result_title.text_direction = Control.TEXT_DIRECTION_AUTO
	_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_title.add_theme_font_size_override("font_size", 32)
	_result_title.add_theme_color_override("font_color", HEALTH_BAD)
	vbox.add_child(_result_title)
	_result_body = Label.new()
	_result_body.text_direction = Control.TEXT_DIRECTION_AUTO
	_result_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_body.add_theme_font_size_override("font_size", 18)
	_result_body.add_theme_color_override("font_color", PAPER)
	_result_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_result_body)
	_retry_button = Button.new()
	_retry_button.text = "مناوبة جديدة  [Enter]"
	_retry_button.text_direction = Control.TEXT_DIRECTION_AUTO
	_retry_button.custom_minimum_size = Vector2(0.0, 52.0)
	_retry_button.add_theme_font_size_override("font_size", 18)
	_retry_button.pressed.connect(_reset)
	vbox.add_child(_retry_button)


func _show_result() -> void:
	_result_title.text = "انهار المبنى"
	_result_body.text = (
		"صمدت: %s\n" % _format_time(building_state.elapsed_time)
		+ "مشاكل أصلحتها: %d\n" % building_state.hazards_fixed
		+ "أعلى فوضى متزامنة: %d\n" % building_state.peak_active_hazards
		+ "\n%s" % _verdict()
	)
	_result_overlay.visible = true
	if is_instance_valid(_result_panel):
		_result_panel.pivot_offset = _result_panel.size * 0.5
		_result_panel.scale = Vector2(1.0, 0.06)
		var tw: Tween = create_tween()
		tw.tween_property(_result_panel, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_retry_button.grab_focus()


func _verdict() -> String:
	var t: float = building_state.elapsed_time
	if t >= 150.0:
		return "التقييم: أسطورة المناوبة. الإدارة خائفة منك."
	if t >= 90.0:
		return "التقييم: موظف مرعب الكفاءة. مشبوه."
	if t >= 45.0:
		return "التقييم: صمدت بشرف. المبنى لا."
	if t >= 20.0:
		return "التقييم: محاولة محترمة قبل الكارثة."
	return "التقييم: استقالة فورية، وهي مقبولة."


func _handle_result_input(event: InputEvent) -> bool:
	if not _outcome_reported:
		return false
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return false
	if key.physical_keycode == KEY_ENTER or key.physical_keycode == KEY_R:
		_reset()
		return true
	return false


# --- Intro ------------------------------------------------------------------

func _build_intro_overlay() -> void:
	_intro_overlay = Control.new()
	_intro_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_intro_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	hud.add_child(_intro_overlay)
	_intro_dim = ColorRect.new()
	_intro_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_intro_dim.color = Color(0.02, 0.018, 0.013, 1.0)
	_intro_overlay.add_child(_intro_dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_intro_overlay.add_child(center)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	center.add_child(vbox)
	var title: Label = Label.new()
	title.text = "المبنى تحت مسؤوليتك"
	title.text_direction = Control.TEXT_DIRECTION_AUTO
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", HEALTH_WARN)
	vbox.add_child(title)
	var sub: Label = Label.new()
	sub.text = "تحرّك [WASD] • اقترب من المشكلة واستمر بالضغط [مسافة] لإصلاحها • اصمد"
	sub.text_direction = Control.TEXT_DIRECTION_AUTO
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", PAPER)
	vbox.add_child(sub)


func _play_intro() -> void:
	_intro_active = true
	_intro_overlay.visible = true
	var tw: Tween = create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(_intro_dim, "color", Color(0.02, 0.018, 0.013, 0.0), 0.7)
	tw.parallel().tween_property(_intro_overlay, "modulate", Color(1, 1, 1, 0.0), 0.7)
	tw.tween_callback(_finish_intro)


func _finish_intro() -> void:
	_intro_active = false
	if is_instance_valid(_intro_overlay):
		_intro_overlay.visible = false
