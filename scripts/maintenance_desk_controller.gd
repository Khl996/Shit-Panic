class_name MaintenanceDeskController
extends RefCounted

signal tool_used(tool_id: int)

enum Tool {
	DUCT_TAPE,
	BUCKET,
}

const READY_TEXT: String = "الأدوات جاهزة"
const TEXT_COLOR: Color = Color(0.945098, 0.901961, 0.811765, 1)
const MUTED_COLOR: Color = Color(0.694118, 0.611765, 0.494118, 1)
const WARNING_COLOR: Color = Color(0.949020, 0.733333, 0.247059, 1)
const PANEL_COLOR: Color = Color(0.137255, 0.0941176, 0.0627451, 0.96)
const BORDER_COLOR: Color = Color(0.541176, 0.380392, 0.219608, 1)

var _panel: PanelContainer
var _status_label: Label
var _tape_button: Button
var _bucket_button: Button
var _tape_tween: Tween
var _bucket_tween: Tween


func configure(parent: Control) -> void:
	_panel = PanelContainer.new()
	_panel.name = "MaintenanceDesk"
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = 24.0
	_panel.offset_top = -218.0
	_panel.offset_right = 430.0
	_panel.offset_bottom = -152.0
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_theme_stylebox_override("panel", _make_panel_style())
	parent.add_child(_panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	_panel.add_child(margin)

	var layout: VBoxContainer = VBoxContainer.new()
	layout.layout_direction = Control.LAYOUT_DIRECTION_LTR
	layout.add_theme_constant_override("separation", 6)
	margin.add_child(layout)

	var header: HBoxContainer = HBoxContainer.new()
	header.layout_direction = Control.LAYOUT_DIRECTION_LTR
	layout.add_child(header)

	var title: Label = Label.new()
	title.text = "طاولة الصيانة"
	title.text_direction = Control.TEXT_DIRECTION_AUTO
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", TEXT_COLOR)
	header.add_child(title)

	_status_label = Label.new()
	_status_label.text = READY_TEXT
	_status_label.text_direction = Control.TEXT_DIRECTION_AUTO
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_status_label.add_theme_font_size_override("font_size", 11)
	_status_label.add_theme_color_override("font_color", MUTED_COLOR)
	header.add_child(_status_label)

	var tools: HBoxContainer = HBoxContainer.new()
	tools.layout_direction = Control.LAYOUT_DIRECTION_LTR
	tools.add_theme_constant_override("separation", 8)
	layout.add_child(tools)

	_tape_button = _make_tool_button("[Q] شطرطون", "حل سريع / بيرجع يعضك")
	_tape_button.pressed.connect(_emit_tool.bind(Tool.DUCT_TAPE))
	tools.add_child(_tape_button)

	_bucket_button = _make_tool_button("[W] سطل", "يلم التنقيط / حل محترم")
	_bucket_button.pressed.connect(_emit_tool.bind(Tool.BUCKET))
	tools.add_child(_bucket_button)

	reset()


func reset() -> void:
	set_status(READY_TEXT, false)
	if is_instance_valid(_tape_button):
		_tape_button.disabled = false
	set_bucket_available(false)


func set_status(message: String, urgent: bool) -> void:
	if not is_instance_valid(_status_label):
		return
	_status_label.text = message
	_status_label.add_theme_color_override("font_color", WARNING_COLOR if urgent else MUTED_COLOR)


func set_bucket_available(available: bool) -> void:
	if is_instance_valid(_bucket_button):
		_bucket_button.disabled = not available


func set_tools_locked(locked: bool) -> void:
	if is_instance_valid(_tape_button):
		_tape_button.disabled = locked
	if is_instance_valid(_bucket_button):
		_bucket_button.disabled = locked or _bucket_button.disabled


func handle_key_input(event: InputEvent) -> bool:
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return false
	match key_event.physical_keycode:
		KEY_Q:
			_emit_tool(Tool.DUCT_TAPE)
			return true
		KEY_W:
			if not _bucket_button.disabled:
				_emit_tool(Tool.BUCKET)
			return true
	return false


func _emit_tool(tool_id: int) -> void:
	match tool_id:
		Tool.DUCT_TAPE:
			_play_tape_animation()
		Tool.BUCKET:
			_play_bucket_animation()
	tool_used.emit(tool_id)


func _play_tape_animation() -> void:
	if not is_instance_valid(_tape_button) or not _tape_button.is_inside_tree():
		return
	if _tape_button.size.x <= 0.0 or _tape_button.size.y <= 0.0:
		return
	_tape_button.pivot_offset = _tape_button.size * 0.5
	if _tape_tween != null and _tape_tween.is_valid():
		_tape_tween.kill()
	_tape_button.scale = Vector2(1.0, 1.0)
	_tape_button.rotation = 0.0
	_tape_tween = _tape_button.create_tween()
	_tape_tween.tween_property(_tape_button, "rotation", deg_to_rad(-9.0), 0.07).set_trans(Tween.TRANS_SINE)
	_tape_tween.parallel().tween_property(_tape_button, "scale", Vector2(0.86, 1.06), 0.07)
	_tape_tween.tween_property(_tape_button, "rotation", deg_to_rad(4.0), 0.09).set_trans(Tween.TRANS_SINE)
	_tape_tween.parallel().tween_property(_tape_button, "scale", Vector2(1.04, 0.96), 0.09)
	_tape_tween.tween_property(_tape_button, "rotation", 0.0, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tape_tween.parallel().tween_property(_tape_button, "scale", Vector2(1.0, 1.0), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _play_bucket_animation() -> void:
	if not is_instance_valid(_bucket_button) or not _bucket_button.is_inside_tree():
		return
	if _bucket_button.size.x <= 0.0 or _bucket_button.size.y <= 0.0:
		return
	_bucket_button.pivot_offset = Vector2(_bucket_button.size.x * 0.5, _bucket_button.size.y)
	if _bucket_tween != null and _bucket_tween.is_valid():
		_bucket_tween.kill()
	_bucket_button.scale = Vector2(1.0, 1.0)
	_bucket_button.rotation = 0.0
	_bucket_tween = _bucket_button.create_tween()
	_bucket_tween.tween_property(_bucket_button, "scale", Vector2(1.12, 0.78), 0.08).set_trans(Tween.TRANS_SINE)
	_bucket_tween.tween_property(_bucket_button, "scale", Vector2(0.96, 1.08), 0.12).set_trans(Tween.TRANS_SINE)
	_bucket_tween.tween_property(_bucket_button, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _make_tool_button(label: String, sublabel: String) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(186.0, 34.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text = "%s\n%s" % [label, sublabel]
	button.text_direction = Control.TEXT_DIRECTION_AUTO
	button.add_theme_font_size_override("font_size", 11)
	return button


func _make_panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = BORDER_COLOR
	style.border_width_left = 3
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 4
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 3
	return style
