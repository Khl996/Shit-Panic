extends Node2D

const ROOM_WIDTH: float = 1280.0
const ROOM_HEIGHT: float = 720.0
const WALL_THICKNESS: float = 30.0

const STABLE_COLOR: Color = Color(0.411765, 0.717647, 0.682353, 1)
const WARNING_COLOR: Color = Color(0.831373, 0.603922, 0.164706, 1)
const DANGER_COLOR: Color = Color(0.788235, 0.294118, 0.258824, 1)
const FAULT_COLOR: Color = Color(0.498039, 0.568627, 0.552941, 1)
const PAPER_COLOR: Color = Color(0.937255, 0.882353, 0.733333, 1)
const PAPER_BORDER: Color = Color(0.541176, 0.380392, 0.219608, 1)
const PAPER_TEXT: Color = Color(0.180392, 0.117647, 0.0784314, 1)

const AC_LEAK_EVENT_ID: int = 7001
const TAPE_FAILURE_EVENT_ID: int = 7002
const AC_LEAK_START_SECONDS: float = 7.0
const TAPE_PATCH_DELAY_SECONDS: float = 22.0
const TAPE_FAILURE_ALARM_SECONDS: float = 5.0

const INTERACT_DESK: int = 0
const INTERACT_TOOL_RACK: int = 1
const INTERACT_RADIO: int = 2
const INTERACT_MANAGER_DOOR: int = 3

const MAINTENANCE_TOOL_DUCT_TAPE: int = 0
const MAINTENANCE_TOOL_BUCKET: int = 1
const LEAK_USE_RADIUS: float = 130.0
const SERVER_LEAK_STATE_DRY: int = 0
const SERVER_LEAK_STATE_LEAKING: int = 1
const SERVER_LEAK_STATE_TAPE_PATCHED: int = 2
const SERVER_LEAK_STATE_BUCKET_PLACED: int = 3
const SERVER_LEAK_STATE_TAPE_FAILED: int = 4

const MANAGER_LINES: Array[String] = [
	"المدير نائم. لا تطرق.",
	"تحت الباب ورقة: 'لا تطرق إلا في حالة الحريق الفعلي.'",
	"سمعت شخير. الأفضل لك.",
	"يقولون من طرق آخر مرة، نُقل لمبنى أبعد.",
]

@export var round_duration_seconds: float = 90.0
@export var use_fixed_seed: bool = true
@export var fixed_seed: int = 1337
@export var development_controls_enabled: bool = false
@export var alternate_test_seed: int = 4242
@export var short_round_duration_seconds: float = 30.0

var facility_state: FacilityState
var intervention_controller: InterventionController
var event_director: EventDirector
var alarm_feed_controller: AlarmFeedController
var audio_feedback_controller: AudioFeedbackController

var _outcome_reported: bool = false
var _controls_expired_notified: bool = false
var _total_interventions_used: int = 0
var _manual_overrides_used: int = 0
var _events_encountered: int = 0
var _highest_panic_level: float = 0.0
var _previous_integrity: float = 100.0
var _leak_started: bool = false
var _ac_leak_active: bool = false
var _ac_leak_alarm_active: bool = false
var _tape_failure_time: float = -1.0
var _tape_failure_alarm_active: bool = false
var _tape_failure_alarm_remaining: float = 0.0
var _duct_tape_uses: int = 0
var _bucket_uses: int = 0
var _maintenance_notes: Array[String] = []

var _active_radio_event_id: int = -1
var _active_radio_event_type: int = -1
var _active_radio_event_title: String = ""
var _active_radio_event_source: String = ""
var _active_radio_event_severity: String = "warning"
var _last_radio_message: String = "لا توجد بلاغات حالياً."
var _player_carry_state: int = 0
var _manager_line_index: int = 0

@onready var player: CharacterBody2D = $Player
@onready var desk_object: Node2D = $Furniture/MaintenanceConsole
@onready var tool_rack: Node2D = $Furniture/ToolRack
@onready var server_leak_object: Node2D = $Furniture/ServerLeak
@onready var radio_object: Node2D = $Furniture/Radio
@onready var wall_clock: Node2D = $Furniture/WallClock
@onready var temperature_meter: Node2D = $Furniture/TempMeter
@onready var pressure_meter: Node2D = $Furniture/PressureMeter
@onready var power_meter: Node2D = $Furniture/PowerMeter
@onready var manager_door: Node2D = $Furniture/ManagerDoor
@onready var camera: Camera2D = $Camera
@onready var hud_layer: CanvasLayer = $HUD

const SHAKE_BASE_POSITION: Vector2 = Vector2(640.0, 360.0)
var _shake_intensity: float = 0.0
var _shake_remaining: float = 0.0
var _shake_time: float = 0.0
var _was_in_puddle: bool = false
var _drip_audio_timer: float = 0.0
const DRIP_AUDIO_INTERVAL: float = 0.62
var _intro_active: bool = true
var _intro_overlay: Control
var _intro_dim: ColorRect
var _intro_title_label: Label
var _intro_sub_label: Label

var _interactables: Array[Dictionary] = []
var _current_interact_index: int = -1
var _interact_prompt_label: Label
var _integrity_label: Label
var _shift_clock_label: Label
var _carry_label: Label
var _action_panel: PanelContainer
var _action_feedback_label: Label
var _override_remaining_label: Label
var _situation_panel: PanelContainer
var _situation_title_label: Label
var _situation_body_label: Label
var _situation_hint_label: Label
var _cool_button: Button
var _vent_button: Button
var _reroute_button: Button
var _reset_button: Button
var _override_button: Button
var _alarm_count_label: Label
var _alarm_slots: Array[PanelContainer] = []
var _alarm_name_labels: Array[Label] = []
var _alarm_source_labels: Array[Label] = []
var _alarm_time_labels: Array[Label] = []
var _radio_popup_panel: PanelContainer
var _radio_popup_label: Label
var _radio_popup_timer: float = 0.0
var _result_overlay: Control
var _result_panel: PanelContainer
var _result_title_label: Label
var _result_body_label: Label
var _retry_button: Button


func _ready() -> void:
	facility_state = FacilityState.new(round_duration_seconds)
	_build_hud()
	_configure_meters()
	_register_interactables()
	_position_player()
	_configure_interventions()
	_configure_events()
	_configure_alarm_feed()
	_configure_audio()
	_build_result_overlay()
	_build_intro_overlay()
	_reset_round_stats()
	_update_hud()
	_play_intro_cinematic()


func _process(delta: float) -> void:
	if _intro_active:
		_update_camera_shake(delta)
		return
	if facility_state.round_state == FacilityState.RoundState.RUNNING:
		var integrity_before: float = facility_state.integrity
		facility_state.advance(delta)
		_update_maintenance_incidents(delta)
		var _integrity_draining: bool = facility_state.integrity < integrity_before - 0.01
		_highest_panic_level = maxf(_highest_panic_level, facility_state.panic_level)
		if facility_state.is_finished():
			_finish_round()
		else:
			intervention_controller.advance(delta)
			event_director.advance(delta, facility_state.elapsed_time)
			alarm_feed_controller.advance(delta)
	if _radio_popup_timer > 0.0:
		_radio_popup_timer = maxf(_radio_popup_timer - delta, 0.0)
		if _radio_popup_timer <= 0.0 and is_instance_valid(_radio_popup_panel):
			_radio_popup_panel.visible = false
	_update_camera_shake(delta)
	_check_player_slip()
	_update_proximity()
	_update_hud()
	_previous_integrity = facility_state.integrity


func _check_player_slip() -> void:
	if not is_instance_valid(player) or not is_instance_valid(server_leak_object):
		return
	if not server_leak_object.has_method("is_in_puddle"):
		return
	var in_puddle: bool = server_leak_object.is_in_puddle(player.global_position)
	if in_puddle and not _was_in_puddle and player is PlayerCharacter:
		var player_char: PlayerCharacter = player as PlayerCharacter
		if player_char.velocity.length() > 90.0:
			player_char.apply_external_slip()
			_trigger_shake(3.5, 0.25)
			audio_feedback_controller.play(AudioFeedbackController.Cue.SLIP)
			# If carrying something, drop it on the floor (comedy moment)
			if _player_carry_state != PlayerCharacter.CarryState.NONE:
				_show_radio_popup("انزلقت! الأداة طارت من يدك. روح للرف من جديد.")
				_set_carry_state(PlayerCharacter.CarryState.NONE)
	_was_in_puddle = in_puddle


func _update_camera_shake(delta: float) -> void:
	if not is_instance_valid(camera):
		return
	if _shake_remaining > 0.0:
		_shake_remaining = maxf(_shake_remaining - delta, 0.0)
		_shake_time += delta
		var t: float = _shake_remaining
		var falloff: float = clampf(t / 0.6, 0.0, 1.0)
		var amount: float = _shake_intensity * falloff
		var offset_x: float = sin(_shake_time * 47.0) * amount
		var offset_y: float = cos(_shake_time * 53.0) * amount * 0.75
		camera.offset = Vector2(offset_x, offset_y)
	else:
		camera.offset = Vector2.ZERO
		_shake_intensity = 0.0
		_shake_time = 0.0


func _trigger_shake(intensity: float, duration: float) -> void:
	if intensity <= _shake_intensity and _shake_remaining > 0.0:
		# Replace only if new shake is at least as strong
		return
	_shake_intensity = intensity
	_shake_remaining = duration
	_shake_time = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if _handle_development_input(event):
		get_viewport().set_input_as_handled()
		return
	if _handle_result_input(event):
		get_viewport().set_input_as_handled()
		return
	if facility_state.is_finished():
		return
	if _handle_interact_input(event):
		get_viewport().set_input_as_handled()
		return
	if _handle_tool_use_input(event):
		get_viewport().set_input_as_handled()
		return
	if _handle_console_shortcut_input(event):
		get_viewport().set_input_as_handled()


func reset_round() -> void:
	facility_state.reset(round_duration_seconds)
	_controls_expired_notified = false
	_outcome_reported = false
	_reset_round_stats()
	intervention_controller.reset()
	event_director.reset()
	alarm_feed_controller.reset()
	audio_feedback_controller.reset()
	_result_overlay.visible = false
	if is_instance_valid(_result_panel):
		_result_panel.scale = Vector2(1.0, 1.0)
		_result_panel.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if player is PlayerCharacter:
		(player as PlayerCharacter).reset_pose()
	_set_carry_state(PlayerCharacter.CarryState.NONE)
	_position_player()
	if server_leak_object.has_method("set_state"):
		server_leak_object.set_state(SERVER_LEAK_STATE_DRY)
	if radio_object.has_method("set_blink_active"):
		radio_object.set_blink_active(false)
	_shake_intensity = 0.0
	_shake_remaining = 0.0
	_shake_time = 0.0
	_was_in_puddle = false
	_drip_audio_timer = 0.0
	if is_instance_valid(camera):
		camera.offset = Vector2.ZERO
	_update_hud()


func _build_hud() -> void:
	# Top-right integrity + clock cluster
	_integrity_label = Label.new()
	_integrity_label.text = "سلامة المبنى: 100%"
	_integrity_label.text_direction = Control.TEXT_DIRECTION_AUTO
	_integrity_label.add_theme_font_size_override("font_size", 18)
	_integrity_label.add_theme_color_override("font_color", PAPER_COLOR)
	_integrity_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_integrity_label.add_theme_constant_override("outline_size", 4)
	_integrity_label.position = Vector2(ROOM_WIDTH - 280.0, 18.0)
	_integrity_label.size = Vector2(260.0, 28.0)
	_integrity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud_layer.add_child(_integrity_label)

	_shift_clock_label = Label.new()
	_shift_clock_label.text = "01:30"
	_shift_clock_label.text_direction = Control.TEXT_DIRECTION_AUTO
	_shift_clock_label.add_theme_font_size_override("font_size", 26)
	_shift_clock_label.add_theme_color_override("font_color", WARNING_COLOR)
	_shift_clock_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_shift_clock_label.add_theme_constant_override("outline_size", 4)
	_shift_clock_label.position = Vector2(ROOM_WIDTH - 280.0, 46.0)
	_shift_clock_label.size = Vector2(260.0, 36.0)
	_shift_clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud_layer.add_child(_shift_clock_label)

	_carry_label = Label.new()
	_carry_label.text = "اليدين فاضية"
	_carry_label.text_direction = Control.TEXT_DIRECTION_AUTO
	_carry_label.add_theme_font_size_override("font_size", 14)
	_carry_label.add_theme_color_override("font_color", PAPER_COLOR)
	_carry_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_carry_label.add_theme_constant_override("outline_size", 3)
	_carry_label.position = Vector2(20.0, 18.0)
	_carry_label.size = Vector2(260.0, 24.0)
	hud_layer.add_child(_carry_label)

	# Interact prompt bottom-center
	_interact_prompt_label = Label.new()
	_interact_prompt_label.text = ""
	_interact_prompt_label.text_direction = Control.TEXT_DIRECTION_AUTO
	_interact_prompt_label.add_theme_font_size_override("font_size", 18)
	_interact_prompt_label.add_theme_color_override("font_color", PAPER_COLOR)
	_interact_prompt_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_interact_prompt_label.add_theme_constant_override("outline_size", 5)
	_interact_prompt_label.position = Vector2(ROOM_WIDTH * 0.5 - 220.0, ROOM_HEIGHT - 60.0)
	_interact_prompt_label.size = Vector2(440.0, 32.0)
	_interact_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_interact_prompt_label.visible = false
	hud_layer.add_child(_interact_prompt_label)

	# Alarm feed bottom-right (4 slim slots)
	_build_alarm_feed_hud()
	# Radio popup (hidden by default)
	_build_radio_popup()
	# Action panel + situation panel (hidden, shown when near desk)
	_build_action_panel()


func _build_alarm_feed_hud() -> void:
	var alarm_root: PanelContainer = PanelContainer.new()
	alarm_root.add_theme_stylebox_override("panel", _make_alarm_root_style())
	alarm_root.position = Vector2(ROOM_WIDTH - 300.0, 110.0)
	alarm_root.size = Vector2(280.0, 220.0)
	hud_layer.add_child(alarm_root)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	alarm_root.add_child(margin)

	var layout: VBoxContainer = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 5)
	margin.add_child(layout)

	var title: Label = Label.new()
	title.text = "بلاغات اللاسلكي"
	title.text_direction = Control.TEXT_DIRECTION_AUTO
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", PAPER_COLOR)
	layout.add_child(title)

	_alarm_count_label = Label.new()
	_alarm_count_label.text = "0 بلاغ"
	_alarm_count_label.text_direction = Control.TEXT_DIRECTION_AUTO
	_alarm_count_label.add_theme_font_size_override("font_size", 11)
	_alarm_count_label.add_theme_color_override("font_color", WARNING_COLOR)
	layout.add_child(_alarm_count_label)

	for index: int in range(4):
		var slot: PanelContainer = PanelContainer.new()
		slot.add_theme_stylebox_override("panel", _make_alarm_slot_style())
		layout.add_child(slot)
		var slot_margin: MarginContainer = MarginContainer.new()
		slot_margin.add_theme_constant_override("margin_left", 8)
		slot_margin.add_theme_constant_override("margin_top", 5)
		slot_margin.add_theme_constant_override("margin_right", 8)
		slot_margin.add_theme_constant_override("margin_bottom", 5)
		slot.add_child(slot_margin)
		var row: VBoxContainer = VBoxContainer.new()
		slot_margin.add_child(row)
		var name_label: Label = Label.new()
		name_label.text = "--"
		name_label.text_direction = Control.TEXT_DIRECTION_AUTO
		name_label.add_theme_font_size_override("font_size", 12)
		row.add_child(name_label)
		var meta_row: HBoxContainer = HBoxContainer.new()
		meta_row.add_theme_constant_override("separation", 8)
		row.add_child(meta_row)
		var source_label: Label = Label.new()
		source_label.text = "اللاسلكي ساكت"
		source_label.text_direction = Control.TEXT_DIRECTION_AUTO
		source_label.add_theme_font_size_override("font_size", 10)
		source_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		meta_row.add_child(source_label)
		var time_label: Label = Label.new()
		time_label.text = "--:--"
		time_label.text_direction = Control.TEXT_DIRECTION_AUTO
		time_label.add_theme_font_size_override("font_size", 10)
		meta_row.add_child(time_label)
		_alarm_slots.append(slot)
		_alarm_name_labels.append(name_label)
		_alarm_source_labels.append(source_label)
		_alarm_time_labels.append(time_label)


func _build_radio_popup() -> void:
	_radio_popup_panel = PanelContainer.new()
	_radio_popup_panel.add_theme_stylebox_override("panel", _make_paper_style())
	_radio_popup_panel.position = Vector2(ROOM_WIDTH * 0.5 - 240.0, 100.0)
	_radio_popup_panel.size = Vector2(480.0, 80.0)
	_radio_popup_panel.visible = false
	hud_layer.add_child(_radio_popup_panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 12)
	_radio_popup_panel.add_child(margin)

	_radio_popup_label = Label.new()
	_radio_popup_label.text = ""
	_radio_popup_label.text_direction = Control.TEXT_DIRECTION_AUTO
	_radio_popup_label.add_theme_font_size_override("font_size", 16)
	_radio_popup_label.add_theme_color_override("font_color", PAPER_TEXT)
	_radio_popup_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_radio_popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	margin.add_child(_radio_popup_label)


func _build_action_panel() -> void:
	# Action panel along bottom, shown when player near desk
	_action_panel = PanelContainer.new()
	_action_panel.add_theme_stylebox_override("panel", _make_action_panel_style())
	_action_panel.position = Vector2(ROOM_WIDTH * 0.5 - 510.0, ROOM_HEIGHT - 170.0)
	_action_panel.size = Vector2(1020.0, 130.0)
	_action_panel.visible = false
	hud_layer.add_child(_action_panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	_action_panel.add_child(margin)

	var layout: VBoxContainer = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 6)
	margin.add_child(layout)

	var header_row: HBoxContainer = HBoxContainer.new()
	layout.add_child(header_row)
	var header_title: Label = Label.new()
	header_title.text = "قرارات المكتب العامة"
	header_title.text_direction = Control.TEXT_DIRECTION_AUTO
	header_title.add_theme_font_size_override("font_size", 13)
	header_title.add_theme_color_override("font_color", PAPER_COLOR)
	header_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(header_title)
	_override_remaining_label = Label.new()
	_override_remaining_label.text = "تصرف يدوي: 2 باقي"
	_override_remaining_label.text_direction = Control.TEXT_DIRECTION_AUTO
	_override_remaining_label.add_theme_font_size_override("font_size", 12)
	_override_remaining_label.add_theme_color_override("font_color", WARNING_COLOR)
	header_row.add_child(_override_remaining_label)

	_action_feedback_label = Label.new()
	_action_feedback_label.text = "هذه أزرار عامة للمبنى. التسريب والمشاكل اليدوية تحتاج مكان وأداة."
	_action_feedback_label.text_direction = Control.TEXT_DIRECTION_AUTO
	_action_feedback_label.add_theme_font_size_override("font_size", 12)
	_action_feedback_label.add_theme_color_override("font_color", STABLE_COLOR)
	_action_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(_action_feedback_label)

	var button_row: HBoxContainer = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 8)
	button_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(button_row)

	_cool_button = _make_action_button("[1] برّد", false)
	_vent_button = _make_action_button("[2] نفّس", false)
	_reroute_button = _make_action_button("[3] خفّف كهرباء", false)
	_reset_button = _make_action_button("[4] أعد تشغيل", false)
	_override_button = _make_action_button("[5] تصرف يدوي", true)
	button_row.add_child(_cool_button)
	button_row.add_child(_vent_button)
	button_row.add_child(_reroute_button)
	button_row.add_child(_reset_button)
	button_row.add_child(_override_button)

	# Situation panel floats above the action panel
	_situation_panel = PanelContainer.new()
	_situation_panel.add_theme_stylebox_override("panel", _make_situation_panel_style())
	_situation_panel.position = Vector2(ROOM_WIDTH * 0.5 - 380.0, ROOM_HEIGHT - 290.0)
	_situation_panel.size = Vector2(760.0, 110.0)
	_situation_panel.visible = false
	hud_layer.add_child(_situation_panel)
	var situation_margin: MarginContainer = MarginContainer.new()
	situation_margin.add_theme_constant_override("margin_left", 18)
	situation_margin.add_theme_constant_override("margin_top", 12)
	situation_margin.add_theme_constant_override("margin_right", 18)
	situation_margin.add_theme_constant_override("margin_bottom", 12)
	_situation_panel.add_child(situation_margin)
	var situation_layout: VBoxContainer = VBoxContainer.new()
	situation_layout.add_theme_constant_override("separation", 4)
	situation_margin.add_child(situation_layout)
	_situation_title_label = Label.new()
	_situation_title_label.text_direction = Control.TEXT_DIRECTION_AUTO
	_situation_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_situation_title_label.add_theme_font_size_override("font_size", 18)
	_situation_title_label.add_theme_color_override("font_color", WARNING_COLOR)
	situation_layout.add_child(_situation_title_label)
	_situation_body_label = Label.new()
	_situation_body_label.text_direction = Control.TEXT_DIRECTION_AUTO
	_situation_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_situation_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_situation_body_label.add_theme_font_size_override("font_size", 13)
	_situation_body_label.add_theme_color_override("font_color", PAPER_COLOR)
	situation_layout.add_child(_situation_body_label)
	_situation_hint_label = Label.new()
	_situation_hint_label.text_direction = Control.TEXT_DIRECTION_AUTO
	_situation_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_situation_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_situation_hint_label.add_theme_font_size_override("font_size", 11)
	_situation_hint_label.add_theme_color_override("font_color", STABLE_COLOR)
	situation_layout.add_child(_situation_hint_label)


func _make_action_button(label: String, is_override: bool) -> Button:
	var button: Button = Button.new()
	button.text = label
	button.text_direction = Control.TEXT_DIRECTION_AUTO
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", PAPER_COLOR)
	button.add_theme_color_override("font_hover_color", PAPER_COLOR)
	var normal_style: StyleBoxFlat = _make_button_style(Color(0.18, 0.137255, 0.0980392, 1), PAPER_BORDER)
	var hover_style: StyleBoxFlat = _make_button_style(Color(0.231373, 0.176471, 0.121569, 1), Color(0.870588, 0.733333, 0.317647, 1))
	var pressed_style: StyleBoxFlat = _make_button_style(Color(0.105882, 0.0784314, 0.054902, 1), Color(0.831373, 0.603922, 0.164706, 1))
	if is_override:
		normal_style = _make_button_style(Color(0.231373, 0.0901961, 0.0666667, 1), Color(0.831373, 0.247059, 0.176471, 1))
		hover_style = _make_button_style(Color(0.301961, 0.117647, 0.0823529, 1), Color(0.949020, 0.541176, 0.156863, 1))
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("focus", normal_style)
	return button


func _make_button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 3
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 4
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 2
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	return style


func _make_action_panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.0784314, 0.0588235, 0.0431373, 0.96)
	style.border_color = PAPER_BORDER
	style.border_width_left = 3
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 4
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 2
	return style


func _make_situation_panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.0784314, 0.0588235, 0.0431373, 0.92)
	style.border_color = WARNING_COLOR
	style.border_width_left = 4
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 2
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 1
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 2
	return style


func _make_alarm_root_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.0784314, 0.0588235, 0.0431373, 0.85)
	style.border_color = PAPER_BORDER
	style.border_width_left = 2
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 3
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_right = 5
	style.corner_radius_bottom_left = 2
	return style


func _make_alarm_slot_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.156863, 0.117647, 0.0823529, 0.92)
	style.border_color = Color(0.301961, 0.211765, 0.121569, 1)
	style.border_width_left = 3
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 2
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 1
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 2
	return style


func _make_paper_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PAPER_COLOR
	style.border_color = PAPER_BORDER
	style.border_width_left = 4
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 3
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 1
	style.corner_radius_bottom_right = 5
	style.corner_radius_bottom_left = 2
	return style


func _configure_meters() -> void:
	if temperature_meter.has_method("configure"):
		temperature_meter.configure("التكييف")
	if pressure_meter.has_method("configure"):
		pressure_meter.configure("المضخات")
	if power_meter.has_method("configure"):
		power_meter.configure("الكهرباء")


func _register_interactables() -> void:
	_interactables = [
		{
			"id": INTERACT_DESK,
			"node": desk_object,
			"radius": 150.0,
			"label": "[E] افتح لوحة التحكم",
		},
		{
			"id": INTERACT_TOOL_RACK,
			"node": tool_rack,
			"radius": 110.0,
			"label": "[E] احمل أداة",
		},
		{
			"id": INTERACT_RADIO,
			"node": radio_object,
			"radius": 90.0,
			"label": "[E] استمع للبلاغ",
		},
		{
			"id": INTERACT_MANAGER_DOOR,
			"node": manager_door,
			"radius": 110.0,
			"label": "[E] اطرق الباب",
		},
	]


func _position_player() -> void:
	if is_instance_valid(player):
		player.position = Vector2(ROOM_WIDTH * 0.5 - 220.0, ROOM_HEIGHT * 0.5 + 120.0)


func _configure_interventions() -> void:
	intervention_controller = InterventionController.new()
	intervention_controller.configure(
		facility_state,
		_cool_button,
		_vent_button,
		_reroute_button,
		_reset_button,
		_override_button,
		_override_remaining_label,
		_action_feedback_label
	)
	intervention_controller.state_changed.connect(_update_hud)
	intervention_controller.action_accepted.connect(_on_action_accepted)
	intervention_controller.action_rejected.connect(_on_action_rejected)


func _configure_events() -> void:
	event_director = EventDirector.new()
	event_director.configure(facility_state, intervention_controller, use_fixed_seed, fixed_seed)
	event_director.event_raised.connect(_on_event_raised)
	event_director.event_resolved.connect(_on_event_resolved)
	intervention_controller.configure_reset_callbacks(
		event_director.has_resettable_events,
		event_director.clear_resettable_events
	)


func _configure_alarm_feed() -> void:
	alarm_feed_controller = AlarmFeedController.new()
	alarm_feed_controller.configure(
		_alarm_count_label,
		_alarm_slots,
		_alarm_name_labels,
		_alarm_source_labels,
		_alarm_time_labels
	)


func _configure_audio() -> void:
	audio_feedback_controller = AudioFeedbackController.new()
	audio_feedback_controller.configure(self)


func _build_result_overlay() -> void:
	_result_overlay = Control.new()
	_result_overlay.name = "ResultOverlay"
	_result_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_result_overlay.visible = false
	hud_layer.add_child(_result_overlay)
	var dim: ColorRect = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	_result_overlay.add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_result_overlay.add_child(center)
	_result_panel = PanelContainer.new()
	_result_panel.custom_minimum_size = Vector2(560.0, 430.0)
	center.add_child(_result_panel)
	var panel_margin: MarginContainer = MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 26)
	panel_margin.add_theme_constant_override("margin_top", 22)
	panel_margin.add_theme_constant_override("margin_right", 26)
	panel_margin.add_theme_constant_override("margin_bottom", 22)
	_result_panel.add_child(panel_margin)
	var layout: VBoxContainer = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	panel_margin.add_child(layout)
	_result_title_label = Label.new()
	_result_title_label.text_direction = Control.TEXT_DIRECTION_AUTO
	_result_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_title_label.add_theme_font_size_override("font_size", 32)
	layout.add_child(_result_title_label)
	_result_body_label = Label.new()
	_result_body_label.text_direction = Control.TEXT_DIRECTION_AUTO
	_result_body_label.add_theme_font_size_override("font_size", 16)
	_result_body_label.add_theme_color_override("font_color", PAPER_COLOR)
	_result_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(_result_body_label)
	_retry_button = Button.new()
	_retry_button.text = "أعيد الشفت"
	_retry_button.text_direction = Control.TEXT_DIRECTION_AUTO
	_retry_button.custom_minimum_size = Vector2(0.0, 54.0)
	_retry_button.add_theme_font_size_override("font_size", 18)
	_retry_button.pressed.connect(reset_round)
	layout.add_child(_retry_button)


func _build_intro_overlay() -> void:
	_intro_overlay = Control.new()
	_intro_overlay.name = "IntroOverlay"
	_intro_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_intro_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	hud_layer.add_child(_intro_overlay)

	_intro_dim = ColorRect.new()
	_intro_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_intro_dim.color = Color(0.02, 0.018, 0.013, 1.0)
	_intro_overlay.add_child(_intro_dim)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_intro_overlay.add_child(center)

	var stack: VBoxContainer = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 14)
	center.add_child(stack)

	_intro_title_label = Label.new()
	_intro_title_label.text = "01:30 صباحاً"
	_intro_title_label.text_direction = Control.TEXT_DIRECTION_AUTO
	_intro_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intro_title_label.add_theme_font_size_override("font_size", 64)
	_intro_title_label.add_theme_color_override("font_color", WARNING_COLOR)
	stack.add_child(_intro_title_label)

	_intro_sub_label = Label.new()
	_intro_sub_label.text = "استلام المناوبة الليلية"
	_intro_sub_label.text_direction = Control.TEXT_DIRECTION_AUTO
	_intro_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intro_sub_label.add_theme_font_size_override("font_size", 22)
	_intro_sub_label.add_theme_color_override("font_color", PAPER_COLOR)
	stack.add_child(_intro_sub_label)


func _play_intro_cinematic() -> void:
	if not is_instance_valid(_intro_overlay):
		_intro_active = false
		return
	_intro_active = true
	_intro_overlay.visible = true
	_intro_dim.color = Color(0.02, 0.018, 0.013, 1.0)
	_intro_title_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_intro_sub_label.modulate = Color(1.0, 1.0, 1.0, 0.0)

	# Clock tick at the start of the cinematic
	if audio_feedback_controller != null:
		audio_feedback_controller.play(AudioFeedbackController.Cue.CLOCK_TICK)

	var tween: Tween = create_tween()
	tween.set_parallel(false)
	tween.tween_property(_intro_title_label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.55)
	tween.parallel().tween_property(_intro_sub_label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.55).set_delay(0.18)
	tween.tween_interval(1.4)
	tween.tween_property(_intro_dim, "color", Color(0.02, 0.018, 0.013, 0.0), 0.85)
	tween.parallel().tween_property(_intro_title_label, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.7)
	tween.parallel().tween_property(_intro_sub_label, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.7)
	tween.tween_callback(_finish_intro)


func _finish_intro() -> void:
	_intro_active = false
	if is_instance_valid(_intro_overlay):
		_intro_overlay.visible = false


func _reset_round_stats() -> void:
	_total_interventions_used = 0
	_manual_overrides_used = 0
	_events_encountered = 0
	_highest_panic_level = 0.0
	_previous_integrity = FacilityState.INITIAL_INTEGRITY
	_leak_started = false
	_ac_leak_active = false
	_ac_leak_alarm_active = false
	_tape_failure_time = -1.0
	_tape_failure_alarm_active = false
	_tape_failure_alarm_remaining = 0.0
	_duct_tape_uses = 0
	_bucket_uses = 0
	_maintenance_notes.clear()
	_active_radio_event_id = -1
	_active_radio_event_type = -1
	_active_radio_event_title = ""
	_active_radio_event_source = ""
	_active_radio_event_severity = "warning"
	_last_radio_message = "لا توجد بلاغات حالياً."
	_manager_line_index = 0


func _update_proximity() -> void:
	if facility_state.is_finished():
		_current_interact_index = -1
		_interact_prompt_label.visible = false
		_action_panel.visible = false
		_situation_panel.visible = false
		return
	var closest_index: int = -1
	var closest_distance_sq: float = INF
	var player_pos: Vector2 = player.position if is_instance_valid(player) else Vector2.ZERO
	for index: int in range(_interactables.size()):
		var data: Dictionary = _interactables[index]
		var node: Node2D = data["node"] as Node2D
		if not is_instance_valid(node):
			continue
		var distance_sq: float = player_pos.distance_squared_to(node.position)
		var radius: float = float(data["radius"])
		if distance_sq <= radius * radius and distance_sq < closest_distance_sq:
			closest_distance_sq = distance_sq
			closest_index = index
	_current_interact_index = closest_index
	if closest_index == -1:
		_interact_prompt_label.visible = false
	else:
		var data: Dictionary = _interactables[closest_index]
		_interact_prompt_label.text = str(data["label"])
		_interact_prompt_label.visible = true
	_update_objective_prompt()
	# Desk-derived UI shows whenever player is in desk range
	var desk_in_range: bool = _player_in_range(desk_object, _radius_for(INTERACT_DESK))
	_action_panel.visible = desk_in_range
	_situation_panel.visible = desk_in_range


func _update_objective_prompt() -> void:
	if not is_instance_valid(_interact_prompt_label):
		return
	if not _ac_leak_active and not _tape_failure_alarm_active:
		return
	if _player_carry_state == PlayerCharacter.CarryState.NONE:
		if _player_in_range(tool_rack, _radius_for(INTERACT_TOOL_RACK)):
			_interact_prompt_label.text = "[E] سطل آمن   [Q] شطرطون سريع"
			_interact_prompt_label.visible = true
		return
	if _player_in_range(server_leak_object, LEAK_USE_RADIUS):
		_interact_prompt_label.text = "[F] استخدم %s على السيرفر" % _tool_name_for_state(_player_carry_state)
		_interact_prompt_label.visible = true


func _player_in_range(node: Node2D, radius: float) -> bool:
	if not is_instance_valid(node) or not is_instance_valid(player):
		return false
	return player.position.distance_squared_to(node.position) <= radius * radius


func _radius_for(interactable_id: int) -> float:
	for data: Dictionary in _interactables:
		if int(data["id"]) == interactable_id:
			return float(data["radius"])
	return 0.0


func _handle_interact_input(event: InputEvent) -> bool:
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return false
	if key_event.physical_keycode == KEY_Q:
		if _player_in_range(tool_rack, _radius_for(INTERACT_TOOL_RACK)):
			_set_carry_state(PlayerCharacter.CarryState.DUCT_TAPE)
			_show_radio_popup("أخذت الشطرطون. سريع ومغرور، لا تعطيه ثقة كاملة.")
			return true
		return false
	if key_event.physical_keycode != KEY_E:
		return false
	if _current_interact_index == -1:
		return false
	var data: Dictionary = _interactables[_current_interact_index]
	match int(data["id"]):
		INTERACT_DESK:
			# Action panel is already auto-shown; pressing E briefly highlights the situation
			_update_situation_panel()
		INTERACT_TOOL_RACK:
			if _ac_leak_active or _tape_failure_alarm_active:
				_set_carry_state(PlayerCharacter.CarryState.BUCKET)
				_show_radio_popup("أخذت السطل. حل ممل، وهذا أحيانًا المطلوب.")
			else:
				_cycle_carry_state()
		INTERACT_RADIO:
			_show_radio_popup(_last_radio_message)
			if is_instance_valid(radio_object) and radio_object.has_method("set_blink_active"):
				radio_object.set_blink_active(false)
		INTERACT_MANAGER_DOOR:
			_show_manager_line()
	return true


func _handle_tool_use_input(event: InputEvent) -> bool:
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return false
	if key_event.physical_keycode != KEY_F:
		return false
	if _player_carry_state == PlayerCharacter.CarryState.NONE:
		_show_rejection_popup("اليدين فاضية. روح لرف الأدوات وخذ شي ينفع.")
		return true
	if not _ac_leak_active:
		_show_rejection_popup("ما فيه شي تستخدم عليه الأداة الحين. احتفظ فيها.")
		return true
	if not _player_in_range(server_leak_object, LEAK_USE_RADIUS):
		_show_rejection_popup("قرب من السيرفر أول. لا ترمي الحل من بعيد.")
		return true
	match _player_carry_state:
		PlayerCharacter.CarryState.DUCT_TAPE:
			_on_maintenance_tool_used(MAINTENANCE_TOOL_DUCT_TAPE)
			return true
		PlayerCharacter.CarryState.BUCKET:
			_on_maintenance_tool_used(MAINTENANCE_TOOL_BUCKET)
			return true
		_:
			_show_radio_popup("اليدين فاضية. روح لرف الأدوات.")
			return true


func _handle_console_shortcut_input(event: InputEvent) -> bool:
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return false
	var is_console_key: bool = false
	match key_event.physical_keycode:
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
			is_console_key = true
		_:
			is_console_key = false
	if not is_console_key:
		return false
	if not _player_in_range(desk_object, _radius_for(INTERACT_DESK)):
		_show_rejection_popup("القرارات الكبيرة من المكتب. ارجع للوحة واضغطها هناك.")
		if is_instance_valid(_action_feedback_label):
			_action_feedback_label.text = "قرب من المكتب عشان تستخدم أزرار الطوارئ."
		return true
	return intervention_controller.handle_key_input(event)


func _cycle_carry_state() -> void:
	var next_state: int = PlayerCharacter.CarryState.NONE
	match _player_carry_state:
		PlayerCharacter.CarryState.NONE:
			next_state = PlayerCharacter.CarryState.DUCT_TAPE
		PlayerCharacter.CarryState.DUCT_TAPE:
			next_state = PlayerCharacter.CarryState.BUCKET
		PlayerCharacter.CarryState.BUCKET:
			next_state = PlayerCharacter.CarryState.NONE
	_set_carry_state(next_state)
	audio_feedback_controller.play(AudioFeedbackController.Cue.BUTTON_ACCEPTED)


func _set_carry_state(new_state: int) -> void:
	_player_carry_state = new_state
	if player is PlayerCharacter:
		(player as PlayerCharacter).set_carry_state(_player_carry_state)
	if tool_rack.has_method("set_state"):
		var rack_state: int = 0  # BOTH
		match _player_carry_state:
			PlayerCharacter.CarryState.DUCT_TAPE:
				rack_state = 2  # BUCKET_ONLY (tape taken)
			PlayerCharacter.CarryState.BUCKET:
				rack_state = 1  # TAPE_ONLY (bucket taken)
		tool_rack.set_state(rack_state)


func _show_radio_popup(text: String) -> void:
	if not is_instance_valid(_radio_popup_label) or not is_instance_valid(_radio_popup_panel):
		return
	_radio_popup_label.text = text
	_radio_popup_panel.visible = true
	_radio_popup_timer = 3.0
	audio_feedback_controller.play(AudioFeedbackController.Cue.BUTTON_ACCEPTED)


func _show_rejection_popup(text: String) -> void:
	if is_instance_valid(_radio_popup_label) and is_instance_valid(_radio_popup_panel):
		_radio_popup_label.text = text
		_radio_popup_panel.visible = true
		_radio_popup_timer = 2.6
	audio_feedback_controller.play(AudioFeedbackController.Cue.BUTTON_REJECTED)


func _show_manager_line() -> void:
	var line: String = MANAGER_LINES[_manager_line_index % MANAGER_LINES.size()]
	_manager_line_index += 1
	_show_radio_popup(line)


func _update_hud() -> void:
	if not is_instance_valid(_integrity_label):
		return
	_integrity_label.text = "سلامة المبنى: %d%%" % int(roundf(facility_state.integrity))
	_shift_clock_label.text = _format_time(facility_state.remaining_time)
	_shift_clock_label.add_theme_color_override("font_color", _color_for_integrity())
	_carry_label.text = _carry_label_text()
	if is_instance_valid(wall_clock) and wall_clock.has_method("set_elapsed_fraction"):
		var fraction: float = 0.0
		if round_duration_seconds > 0.0:
			fraction = clampf(facility_state.elapsed_time / round_duration_seconds, 0.0, 1.0)
		wall_clock.set_elapsed_fraction(fraction)
	_update_wall_meters()
	_update_situation_panel()


func _update_wall_meters() -> void:
	if is_instance_valid(temperature_meter) and temperature_meter.has_method("set_value"):
		temperature_meter.set_value(facility_state.temperature, facility_state.is_sensor_glitched(FacilityState.SYSTEM_TEMPERATURE))
	if is_instance_valid(pressure_meter) and pressure_meter.has_method("set_value"):
		pressure_meter.set_value(facility_state.pressure, facility_state.is_sensor_glitched(FacilityState.SYSTEM_PRESSURE))
	if is_instance_valid(power_meter) and power_meter.has_method("set_value"):
		power_meter.set_value(facility_state.power_load, facility_state.is_sensor_glitched(FacilityState.SYSTEM_POWER_LOAD))


func _carry_label_text() -> String:
	match _player_carry_state:
		PlayerCharacter.CarryState.DUCT_TAPE:
			return "تحمل: شطرطون"
		PlayerCharacter.CarryState.BUCKET:
			return "تحمل: سطل"
		_:
			return "اليدين فاضية"


func _color_for_integrity() -> Color:
	if facility_state.integrity >= 70.0:
		return STABLE_COLOR
	if facility_state.integrity >= 40.0:
		return WARNING_COLOR
	return DANGER_COLOR


func _format_time(seconds: float) -> String:
	var whole_seconds: int = maxi(int(ceil(maxf(seconds, 0.0))), 0)
	var minutes: int = floori(float(whole_seconds) / 60.0)
	var remaining_seconds: int = whole_seconds % 60
	return "%02d:%02d" % [minutes, remaining_seconds]


func _tool_name_for_state(carry_state: int) -> String:
	match carry_state:
		PlayerCharacter.CarryState.DUCT_TAPE:
			return "الشطرطون"
		PlayerCharacter.CarryState.BUCKET:
			return "السطل"
		_:
			return "الأداة"


func _update_situation_panel() -> void:
	if not is_instance_valid(_situation_title_label):
		return
	if _tape_failure_alarm_active:
		var failure_hint: String = "الرف على يسارك. السطل أهدأ من الشطرطون."
		if _player_carry_state != PlayerCharacter.CarryState.NONE:
			failure_hint = "روح للسيرفر واضغط [F]."
		if _player_carry_state != PlayerCharacter.CarryState.NONE and _player_in_range(server_leak_object, LEAK_USE_RADIUS):
			failure_hint = "اضغط [F] الآن."
		_set_situation_text(
			"الشطرطون خان العشرة",
			"الحل السريع رجع يعضك.",
			failure_hint,
			DANGER_COLOR
		)
		return
	if _ac_leak_active:
		var leak_hint: String = "الرف يسار. [E] سطل آمن أو [Q] شطرطون سريع."
		if _player_carry_state != PlayerCharacter.CarryState.NONE:
			leak_hint = "السيرفر يمين. اضغط [F] قربه."
		if _player_carry_state != PlayerCharacter.CarryState.NONE and _player_in_range(server_leak_object, LEAK_USE_RADIUS):
			leak_hint = "اضغط [F] الآن."
		_set_situation_text(
			"المكيف ينقط فوق السيرفر",
			"مويه فوق شيء غالي. ما تحتاج شهادة هندسة.",
			leak_hint,
			WARNING_COLOR
		)
		return
	if _tape_failure_time > 0.0:
		_set_situation_text(
			"الشطرطون ماسك مؤقتاً",
			"البلاغ راح، بس الحل السريع له ذاكرة سيئة.",
			"تابع البلاغات. لا تثق في الراحة المؤقتة.",
			WARNING_COLOR
		)
		return
	if _active_radio_event_id != -1:
		_set_situation_text(
			"بلاغ: %s" % _active_radio_event_title,
			"المصدر: %s. الأرقام تحت تعكس الضغط، القرار قرارك." % _active_radio_event_source,
			_hint_for_event_type(_active_radio_event_type),
			DANGER_COLOR if _is_active_radio_event_danger() else WARNING_COLOR
		)
		return
	if facility_state.elapsed_time < AC_LEAK_START_SECONDS:
		_set_situation_text(
			"استلمت المناوبة",
			"اصمد لين يخلص الوقت. تحرك، شوف العدّادات، استعد.",
			"أوّل موقف بيجيك بعد شوي.",
			STABLE_COLOR
		)
		return
	_set_situation_text(
		"الوضع هادي",
		"لا بلاغ نشط. راقب العدّادات.",
		"تقدر تتجوّل وتجرّب الأشياء.",
		STABLE_COLOR
	)


func _set_situation_text(title: String, body: String, hint: String, accent: Color) -> void:
	_situation_title_label.text = title
	_situation_body_label.text = body
	_situation_hint_label.text = hint
	_situation_title_label.add_theme_color_override("font_color", accent)


func _hint_for_event_type(event_type: int) -> String:
	match event_type:
		EventDirector.EventType.COOLING_FAILURE:
			return "[1] تبريد طوارئ — قرّب من المكتب أولاً."
		EventDirector.EventType.PRESSURE_SPIKE:
			return "[2] تنفيس المضخات — قرّب من المكتب أولاً."
		EventDirector.EventType.POWER_SURGE:
			return "[3] تحويل الكهرباء — قرّب من المكتب أولاً."
		EventDirector.EventType.SENSOR_GLITCH:
			return "[4] إعادة تشغيل تفك أعطال القراءة."
		EventDirector.EventType.JAMMED_CONTROL:
			return "[4] إعادة تشغيل تفك الأزرار العالقة."
		_:
			return "قرّب من المكتب لاتخاذ القرار."


func _is_active_radio_event_danger() -> bool:
	if _active_radio_event_id == -1:
		return false
	return _active_radio_event_severity == "danger"


func _update_maintenance_incidents(delta_seconds: float) -> void:
	if not _leak_started and facility_state.elapsed_time >= AC_LEAK_START_SECONDS:
		_start_ac_leak()
	if _ac_leak_active:
		facility_state.apply_ac_leak_over_server(delta_seconds)
		_drip_audio_timer = maxf(_drip_audio_timer - delta_seconds, 0.0)
		if _drip_audio_timer <= 0.0:
			audio_feedback_controller.play(AudioFeedbackController.Cue.DRIP)
			_drip_audio_timer = DRIP_AUDIO_INTERVAL
	else:
		_drip_audio_timer = 0.0
	if _tape_failure_time > 0.0 and facility_state.elapsed_time >= _tape_failure_time:
		_trigger_tape_failure()
	if _tape_failure_alarm_active:
		if _ac_leak_active:
			_tape_failure_alarm_remaining = TAPE_FAILURE_ALARM_SECONDS
		else:
			_tape_failure_alarm_remaining = maxf(_tape_failure_alarm_remaining - maxf(delta_seconds, 0.0), 0.0)
			if is_zero_approx(_tape_failure_alarm_remaining):
				_resolve_tape_failure_alarm()


func _start_ac_leak() -> void:
	_leak_started = true
	_ac_leak_active = true
	_ac_leak_alarm_active = true
	_events_encountered += 1
	_maintenance_notes.append("المكيف ينقط فوق السيرفر. طبعًا فوق السيرفر بالذات.")
	var data: Dictionary = _maintenance_alarm_data(
		AC_LEAK_EVENT_ID,
		"المكيف ينقط فوق السيرفر",
		"مكيف المدير",
		"warning"
	)
	alarm_feed_controller.raise_alarm(data)
	_set_last_radio_message(data)
	audio_feedback_controller.play(AudioFeedbackController.Cue.WARNING_ALARM)
	_show_radio_popup("بلاغ 01: المكيف فوق السيرفر قرر يصير شلال.")
	if is_instance_valid(radio_object) and radio_object.has_method("set_blink_active"):
		radio_object.set_blink_active(true)
	if is_instance_valid(server_leak_object) and server_leak_object.has_method("set_state"):
		server_leak_object.set_state(SERVER_LEAK_STATE_LEAKING)
	_trigger_shake(4.0, 0.45)


func _patch_ac_leak_with_tape() -> void:
	_ac_leak_active = false
	_duct_tape_uses += 1
	_total_interventions_used += 1
	_tape_failure_time = facility_state.elapsed_time + TAPE_PATCH_DELAY_SECONDS
	_maintenance_notes.append("استخدمت الشطرطون. انتصار مؤقت ورائحته مشكلة قادمة.")
	if is_instance_valid(server_leak_object) and server_leak_object.has_method("set_state"):
		server_leak_object.set_state(SERVER_LEAK_STATE_TAPE_PATCHED)
	if _ac_leak_alarm_active:
		_ac_leak_alarm_active = false
		alarm_feed_controller.resolve_alarm(_maintenance_alarm_data(
			AC_LEAK_EVENT_ID,
			"المكيف ينقط فوق السيرفر",
			"مكيف المدير",
			"warning"
		))
	if _tape_failure_alarm_active:
		_resolve_tape_failure_alarm()
	_show_radio_popup("الشطرطون ماسك... للحين")
	audio_feedback_controller.play(AudioFeedbackController.Cue.BUTTON_ACCEPTED)
	_trigger_shake(2.5, 0.18)


func _catch_ac_leak_with_bucket() -> void:
	_ac_leak_active = false
	_tape_failure_time = -1.0
	_bucket_uses += 1
	_total_interventions_used += 1
	_maintenance_notes.append("حطيت السطل تحت التنقيط. حل محترم لدرجة تخوف.")
	if is_instance_valid(server_leak_object) and server_leak_object.has_method("set_state"):
		server_leak_object.set_state(SERVER_LEAK_STATE_BUCKET_PLACED)
	if _ac_leak_alarm_active:
		_ac_leak_alarm_active = false
		alarm_feed_controller.resolve_alarm(_maintenance_alarm_data(
			AC_LEAK_EVENT_ID,
			"المكيف ينقط فوق السيرفر",
			"مكيف المدير",
			"warning"
		))
	if _tape_failure_alarm_active:
		_resolve_tape_failure_alarm()
	_show_radio_popup("السطل مستلم التنقيط")
	audio_feedback_controller.play(AudioFeedbackController.Cue.BUTTON_ACCEPTED)
	_trigger_shake(1.6, 0.2)


func _trigger_tape_failure() -> void:
	_tape_failure_time = -1.0
	_ac_leak_active = true
	_tape_failure_alarm_active = true
	_tape_failure_alarm_remaining = TAPE_FAILURE_ALARM_SECONDS
	_events_encountered += 1
	facility_state.apply_bad_tape_failure()
	_maintenance_notes.append("الشطرطون استسلم وقال الرطوبة هي السبب.")
	if is_instance_valid(server_leak_object) and server_leak_object.has_method("set_state"):
		server_leak_object.set_state(SERVER_LEAK_STATE_TAPE_FAILED)
	var data: Dictionary = _maintenance_alarm_data(
		TAPE_FAILURE_EVENT_ID,
		"الشطرطون خان العشرة",
		"دولاب السيرفر",
		"danger"
	)
	alarm_feed_controller.raise_alarm(data)
	_set_last_radio_message(data)
	audio_feedback_controller.play(AudioFeedbackController.Cue.CRITICAL_ALARM)
	_show_radio_popup("الشطرطون خانك. نفس المكان، بس الآن الموضوع محرج.")
	if is_instance_valid(radio_object) and radio_object.has_method("set_blink_active"):
		radio_object.set_blink_active(true)
	_trigger_shake(7.0, 0.6)


func _resolve_tape_failure_alarm() -> void:
	_tape_failure_alarm_active = false
	_tape_failure_alarm_remaining = 0.0
	alarm_feed_controller.resolve_alarm(_maintenance_alarm_data(
		TAPE_FAILURE_EVENT_ID,
		"الشطرطون خان العشرة",
		"دولاب السيرفر",
		"danger"
	))


func _maintenance_alarm_data(event_id: int, title: String, source: String, severity: String) -> Dictionary:
	return {
		"id": event_id,
		"title": title,
		"source": source,
		"elapsed_time": facility_state.elapsed_time,
		"severity": severity,
	}


func _set_last_radio_message(data: Dictionary) -> void:
	_last_radio_message = "%s — %s" % [str(data["title"]), str(data["source"])]


func _on_maintenance_tool_used(tool_id: int) -> void:
	if facility_state.is_finished():
		return
	# Only allow tool use if the player is carrying that tool
	match tool_id:
		MAINTENANCE_TOOL_DUCT_TAPE:
			if _player_carry_state != PlayerCharacter.CarryState.DUCT_TAPE:
				_action_feedback_label.text = "ما تحمل شطرطون. روح للرف."
				audio_feedback_controller.play(AudioFeedbackController.Cue.BUTTON_REJECTED)
				return
			if _ac_leak_active:
				_patch_ac_leak_with_tape()
				_set_carry_state(PlayerCharacter.CarryState.NONE)
			else:
				_action_feedback_label.text = "ما فيه شي تلزقه الحين."
				audio_feedback_controller.play(AudioFeedbackController.Cue.BUTTON_REJECTED)
		MAINTENANCE_TOOL_BUCKET:
			if _player_carry_state != PlayerCharacter.CarryState.BUCKET:
				_action_feedback_label.text = "ما تحمل سطل. روح للرف."
				audio_feedback_controller.play(AudioFeedbackController.Cue.BUTTON_REJECTED)
				return
			if _ac_leak_active:
				_catch_ac_leak_with_bucket()
				_set_carry_state(PlayerCharacter.CarryState.NONE)
			else:
				_action_feedback_label.text = "ما فيه تنقيط يحتاج سطل."
				audio_feedback_controller.play(AudioFeedbackController.Cue.BUTTON_REJECTED)
	_update_hud()


func _on_action_accepted(action: int) -> void:
	_total_interventions_used += 1
	if action == InterventionController.Action.OVERRIDE:
		_manual_overrides_used += 1
		_trigger_shake(5.5, 0.4)
	else:
		_trigger_shake(1.4, 0.12)
	audio_feedback_controller.play(AudioFeedbackController.Cue.BUTTON_ACCEPTED)


func _on_action_rejected(_action: int, _reason: String) -> void:
	audio_feedback_controller.play(AudioFeedbackController.Cue.BUTTON_REJECTED)


func _on_event_raised(event_data: Dictionary) -> void:
	_events_encountered += 1
	_active_radio_event_id = int(event_data["id"])
	_active_radio_event_type = int(event_data["type"])
	_active_radio_event_title = str(event_data["title"])
	_active_radio_event_source = str(event_data["source"])
	_active_radio_event_severity = str(event_data["severity"])
	alarm_feed_controller.raise_alarm(event_data)
	_set_last_radio_message(event_data)
	audio_feedback_controller.play(AudioFeedbackController.Cue.EVENT_RAISED)
	if str(event_data["severity"]) == "danger":
		audio_feedback_controller.play(AudioFeedbackController.Cue.CRITICAL_ALARM)
	else:
		audio_feedback_controller.play(AudioFeedbackController.Cue.WARNING_ALARM)
	if is_instance_valid(radio_object) and radio_object.has_method("set_blink_active"):
		radio_object.set_blink_active(true)
	match int(event_data["type"]):
		EventDirector.EventType.COOLING_FAILURE:
			facility_state.apply_cooling_failure(float(event_data["duration"]))
		EventDirector.EventType.PRESSURE_SPIKE:
			facility_state.apply_pressure_spike(float(event_data["duration"]))
		EventDirector.EventType.POWER_SURGE:
			facility_state.apply_power_surge(float(event_data["duration"]))
		EventDirector.EventType.SENSOR_GLITCH:
			facility_state.apply_sensor_glitch(int(event_data["target_system"]))
			audio_feedback_controller.play(AudioFeedbackController.Cue.FAULT)
		EventDirector.EventType.JAMMED_CONTROL:
			intervention_controller.set_jammed_action(int(event_data["target_action"]))
			audio_feedback_controller.play(AudioFeedbackController.Cue.FAULT)


func _on_event_resolved(event_data: Dictionary) -> void:
	if _active_radio_event_id == int(event_data["id"]):
		_active_radio_event_id = -1
		_active_radio_event_type = -1
		_active_radio_event_title = ""
		_active_radio_event_source = ""
		_active_radio_event_severity = "warning"
	alarm_feed_controller.resolve_alarm(event_data)
	# Turn radio off only if there are no other active alarms
	if _active_radio_event_id == -1 and not _ac_leak_alarm_active and not _tape_failure_alarm_active:
		if is_instance_valid(radio_object) and radio_object.has_method("set_blink_active"):
			radio_object.set_blink_active(false)
	match int(event_data["type"]):
		EventDirector.EventType.COOLING_FAILURE:
			facility_state.clear_cooling_failure()
		EventDirector.EventType.PRESSURE_SPIKE:
			facility_state.clear_pressure_spike()
		EventDirector.EventType.POWER_SURGE:
			facility_state.clear_power_surge()
		EventDirector.EventType.SENSOR_GLITCH:
			facility_state.clear_sensor_glitches()
		EventDirector.EventType.JAMMED_CONTROL:
			intervention_controller.clear_jammed_action(int(event_data["target_action"]))


func _finish_round() -> void:
	if _outcome_reported:
		return
	_outcome_reported = true
	_notify_controls_expired()
	if facility_state.round_state == FacilityState.RoundState.SURVIVED:
		audio_feedback_controller.play(AudioFeedbackController.Cue.WIN)
		_trigger_shake(2.0, 0.25)
	else:
		audio_feedback_controller.play(AudioFeedbackController.Cue.LOSS)
		_trigger_shake(9.0, 0.9)
	_show_result_overlay()


func _notify_controls_expired() -> void:
	if _controls_expired_notified:
		return
	_controls_expired_notified = true
	intervention_controller.expire_controls()


func _show_result_overlay() -> void:
	var survived: bool = facility_state.round_state == FacilityState.RoundState.SURVIVED
	var title: String = "عدّت المناوبة" if survived else "المبنى فلت من يدك"
	var accent_color: Color = STABLE_COLOR if survived else DANGER_COLOR
	_result_title_label.text = title
	_result_title_label.add_theme_color_override("font_color", accent_color)
	_result_panel.add_theme_stylebox_override("panel", _make_result_panel_style(accent_color))
	_result_body_label.text = _build_result_body(survived)
	_result_overlay.visible = true
	# Animate: scale from squashed paper to full, modulate from transparent to opaque
	_result_panel.pivot_offset = _result_panel.size * 0.5
	_result_panel.scale = Vector2(1.0, 0.05)
	_result_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(_result_panel, "scale", Vector2(1.0, 1.0), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_result_panel, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.32)
	tween.tween_callback(_retry_button.grab_focus).set_delay(0.4)


func _make_result_panel_style(accent_color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.0784314, 0.0588235, 0.0431373, 0.98)
	style.border_color = accent_color
	style.border_width_left = 3
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 3
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_right = 2
	style.corner_radius_bottom_left = 2
	return style


func _build_result_body(survived: bool) -> String:
	var cause_label: String = "أكثر شي تعبك"
	if not survived:
		cause_label = "سبب الانهيار"
	return (
		"سلامة المبنى: %d%%\n" % int(roundf(facility_state.integrity))
		+ "الوقت اللي صمدته: %s\n" % _format_time(facility_state.elapsed_time)
		+ "%s: %s\n" % [cause_label, facility_state.get_most_stressed_system_name()]
		+ "قراراتك: %d\n" % _total_interventions_used
		+ "التصرف اليدوي: %d\n" % _manual_overrides_used
		+ "الشطرطون: %d\n" % _duct_tape_uses
		+ "السطل: %d\n" % _bucket_uses
		+ "البلاغات اللي لحقتك: %d\n" % _events_encountered
		+ "أعلى توتر: %d%%\n" % int(roundf(_highest_panic_level * 100.0))
		+ "تقييم المناوبة: %s\n" % _performance_grade(survived)
		+ "ملاحظة المدير: %s" % _post_shift_note()
	)


func _performance_grade(survived: bool) -> String:
	if not survived:
		return "F"
	if facility_state.integrity >= 70.0 and _highest_panic_level < 0.75:
		return "A"
	if facility_state.integrity >= 50.0:
		return "B"
	if facility_state.integrity >= 25.0:
		return "C"
	return "D"


func _post_shift_note() -> String:
	if _maintenance_notes.is_empty():
		return "ما فيه ملاحظات. هذا بحد ذاته يجيب الشك."
	return _maintenance_notes[_maintenance_notes.size() - 1]


func _handle_result_input(event: InputEvent) -> bool:
	if not _outcome_reported:
		return false
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return false
	if key_event.physical_keycode == KEY_R or key_event.physical_keycode == KEY_ENTER:
		reset_round()
		return true
	return false


func _handle_development_input(event: InputEvent) -> bool:
	if not development_controls_enabled:
		return false
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo or not key_event.ctrl_pressed:
		return false
	match key_event.physical_keycode:
		KEY_R:
			reset_round()
			return true
		KEY_W:
			facility_state.force_survival()
			_finish_round()
			return true
		KEY_L:
			facility_state.force_loss()
			_finish_round()
			return true
		KEY_D:
			round_duration_seconds = short_round_duration_seconds
			reset_round()
			return true
		KEY_A:
			use_fixed_seed = true
			fixed_seed = alternate_test_seed
			event_director.set_seed_settings(use_fixed_seed, fixed_seed)
			reset_round()
			return true
	return false
