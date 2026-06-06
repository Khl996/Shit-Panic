class_name MaintenanceDeskController
extends RefCounted

signal tool_used(tool_id: int)

enum Tool {
	DUCT_TAPE,
	BUCKET,
}

const READY_TEXT: String = "TOOLS READY"
const TEXT_COLOR: Color = Color(0.898039, 0.909804, 0.894118, 1)
const MUTED_COLOR: Color = Color(0.498039, 0.568627, 0.552941, 1)
const WARNING_COLOR: Color = Color(0.831373, 0.603922, 0.164706, 1)
const PANEL_COLOR: Color = Color(0.027451, 0.039216, 0.043137, 0.96)
const BORDER_COLOR: Color = Color(0.164706, 0.223529, 0.227451, 1)

var _panel: PanelContainer
var _status_label: Label
var _tape_button: Button
var _bucket_button: Button


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
	title.text = "MAINTENANCE DESK"
	title.text_direction = Control.TEXT_DIRECTION_LTR
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", TEXT_COLOR)
	header.add_child(title)

	_status_label = Label.new()
	_status_label.text = READY_TEXT
	_status_label.text_direction = Control.TEXT_DIRECTION_LTR
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_status_label.add_theme_font_size_override("font_size", 11)
	_status_label.add_theme_color_override("font_color", MUTED_COLOR)
	header.add_child(_status_label)

	var tools: HBoxContainer = HBoxContainer.new()
	tools.layout_direction = Control.LAYOUT_DIRECTION_LTR
	tools.add_theme_constant_override("separation", 8)
	layout.add_child(tools)

	_tape_button = _make_tool_button("[Q] DUCT TAPE", "FAST PATCH / LATER RISK")
	_tape_button.pressed.connect(_emit_tool.bind(Tool.DUCT_TAPE))
	tools.add_child(_tape_button)

	_bucket_button = _make_tool_button("[W] BUCKET", "CATCH DRIP / MANUAL")
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
	tool_used.emit(tool_id)


func _make_tool_button(label: String, sublabel: String) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(186.0, 34.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text = "%s\n%s" % [label, sublabel]
	button.text_direction = Control.TEXT_DIRECTION_LTR
	button.add_theme_font_size_override("font_size", 11)
	return button


func _make_panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = BORDER_COLOR
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 3
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_right = 2
	style.corner_radius_bottom_left = 2
	return style
