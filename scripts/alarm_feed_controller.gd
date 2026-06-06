class_name AlarmFeedController
extends RefCounted

const RESOLVED_RETENTION_SECONDS: float = 5.0
const ACTIVE_WARNING_COLOR: Color = Color(0.541176, 0.317647, 0.0509804, 1)
const ACTIVE_DANGER_COLOR: Color = Color(0.564706, 0.137255, 0.0980392, 1)
const MUTED_TEXT_COLOR: Color = Color(0.388235, 0.286275, 0.196078, 1)
const PRIMARY_TEXT_COLOR: Color = Color(0.156863, 0.105882, 0.0666667, 1)
const EMPTY_TEXT_COLOR: Color = Color(0.443137, 0.380392, 0.305882, 1)

var _alarm_count_label: Label
var _slots: Array[PanelContainer] = []
var _name_labels: Array[Label] = []
var _source_labels: Array[Label] = []
var _time_labels: Array[Label] = []
var _alarms: Array[Dictionary] = []
var _warning_style: StyleBoxFlat
var _danger_style: StyleBoxFlat
var _resolved_style: StyleBoxFlat
var _empty_style: StyleBoxFlat
var _arrival_tween: Tween


func configure(
	alarm_count_label: Label,
	slots: Array[PanelContainer],
	name_labels: Array[Label],
	source_labels: Array[Label],
	time_labels: Array[Label]
) -> void:
	_alarm_count_label = alarm_count_label
	_slots = slots
	_name_labels = name_labels
	_source_labels = source_labels
	_time_labels = time_labels
	_build_styles()
	_validate_configuration()
	reset()


func reset() -> void:
	_alarms.clear()
	_render()


func advance(delta_seconds: float) -> void:
	var safe_delta: float = maxf(delta_seconds, 0.0)
	var index: int = _alarms.size() - 1
	while index >= 0:
		if not bool(_alarms[index]["active"]):
			_alarms[index]["resolved_age"] = float(_alarms[index]["resolved_age"]) + safe_delta
			if float(_alarms[index]["resolved_age"]) >= RESOLVED_RETENTION_SECONDS:
				_alarms.remove_at(index)
		index -= 1
	_render()


func raise_alarm(event_data: Dictionary) -> void:
	var alarm: Dictionary = {
		"id": int(event_data["id"]),
		"title": str(event_data["title"]),
		"source": str(event_data["source"]),
		"time": _format_time(float(event_data["elapsed_time"])),
		"severity": str(event_data["severity"]),
		"active": true,
		"resolved_age": 0.0,
	}
	_alarms.push_front(alarm)
	_render()
	_animate_arrival()


func resolve_alarm(event_data: Dictionary) -> void:
	var event_id: int = int(event_data["id"])
	for index: int in range(_alarms.size()):
		if int(_alarms[index]["id"]) == event_id:
			_alarms[index]["active"] = false
			_alarms[index]["resolved_age"] = 0.0
			break
	_render()


func _render() -> void:
	var active_count: int = _active_alarm_count()
	_alarm_count_label.text = "%d بلاغ" % active_count

	for slot_index: int in range(_slots.size()):
		if slot_index >= _alarms.size():
			_render_empty_slot(slot_index)
			continue
		_render_alarm_slot(slot_index, _alarms[slot_index])


func _render_alarm_slot(slot_index: int, alarm: Dictionary) -> void:
	var is_active: bool = bool(alarm["active"])
	var severity: String = str(alarm["severity"])
	_name_labels[slot_index].text = str(alarm["title"])
	_source_labels[slot_index].text = str(alarm["source"]) if is_active else "انحل / %s" % str(alarm["source"])
	_time_labels[slot_index].text = str(alarm["time"])

	if is_active:
		if severity == "danger":
			_slots[slot_index].add_theme_stylebox_override("panel", _danger_style)
			_time_labels[slot_index].add_theme_color_override("font_color", ACTIVE_DANGER_COLOR)
		else:
			_slots[slot_index].add_theme_stylebox_override("panel", _warning_style)
			_time_labels[slot_index].add_theme_color_override("font_color", ACTIVE_WARNING_COLOR)
		_name_labels[slot_index].add_theme_color_override("font_color", PRIMARY_TEXT_COLOR)
		_source_labels[slot_index].add_theme_color_override("font_color", MUTED_TEXT_COLOR)
	else:
		_slots[slot_index].add_theme_stylebox_override("panel", _resolved_style)
		_name_labels[slot_index].add_theme_color_override("font_color", MUTED_TEXT_COLOR)
		_source_labels[slot_index].add_theme_color_override("font_color", MUTED_TEXT_COLOR)
		_time_labels[slot_index].add_theme_color_override("font_color", MUTED_TEXT_COLOR)


func _render_empty_slot(slot_index: int) -> void:
	_slots[slot_index].add_theme_stylebox_override("panel", _empty_style)
	_name_labels[slot_index].text = "--"
	_source_labels[slot_index].text = "اللاسلكي ساكت"
	_time_labels[slot_index].text = "--:--"
	_name_labels[slot_index].add_theme_color_override("font_color", EMPTY_TEXT_COLOR)
	_source_labels[slot_index].add_theme_color_override("font_color", EMPTY_TEXT_COLOR)
	_time_labels[slot_index].add_theme_color_override("font_color", EMPTY_TEXT_COLOR)


func _active_alarm_count() -> int:
	var count: int = 0
	for alarm: Dictionary in _alarms:
		if bool(alarm["active"]):
			count += 1
	return count


func _format_time(seconds: float) -> String:
	var whole_seconds: int = maxi(int(floorf(seconds)), 0)
	var minutes: int = floori(float(whole_seconds) / 60.0)
	var remaining_seconds: int = whole_seconds % 60
	return "%02d:%02d" % [minutes, remaining_seconds]


func _build_styles() -> void:
	_warning_style = _make_slot_style(Color(0.901961, 0.843137, 0.694118, 1), Color(0.737255, 0.501961, 0.156863, 1))
	_danger_style = _make_slot_style(Color(0.92549, 0.815686, 0.733333, 1), Color(0.745098, 0.231373, 0.196078, 1))
	_resolved_style = _make_slot_style(Color(0.815686, 0.776471, 0.690196, 1), Color(0.443137, 0.34902, 0.231373, 1))
	_empty_style = _make_slot_style(Color(0.156863, 0.117647, 0.0823529, 0.92), Color(0.301961, 0.211765, 0.121569, 1))


func _make_slot_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_width_left = 4
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 2
	style.border_color = border_color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 1
	style.corner_radius_bottom_right = 5
	style.corner_radius_bottom_left = 2
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 6
	return style


func _validate_configuration() -> void:
	if not is_instance_valid(_alarm_count_label):
		push_error("AlarmFeedController requires an alarm count label.")
		assert(false)
	if _slots.size() != 4 or _name_labels.size() != 4 or _source_labels.size() != 4 or _time_labels.size() != 4:
		push_error("AlarmFeedController requires exactly four alarm slots.")
		assert(false)
	_validate_nodes(_slots)
	_validate_nodes(_name_labels)
	_validate_nodes(_source_labels)
	_validate_nodes(_time_labels)


func _validate_nodes(nodes: Array) -> void:
	for node: Node in nodes:
		if not is_instance_valid(node):
			push_error("AlarmFeedController has a missing alarm slot reference.")
			assert(false)


func _animate_arrival() -> void:
	if _slots.is_empty():
		return
	var slot: PanelContainer = _slots[0]
	if not is_instance_valid(slot) or not slot.is_inside_tree():
		return
	if slot.size.x <= 0.0 or slot.size.y <= 0.0:
		return
	slot.pivot_offset = Vector2(slot.size.x * 0.5, 0.0)
	if _arrival_tween != null and _arrival_tween.is_valid():
		_arrival_tween.kill()
	slot.scale = Vector2(1.0, 0.35)
	slot.modulate = Color(1.4, 1.35, 1.15, 0.0)
	_arrival_tween = slot.create_tween().set_parallel(true)
	_arrival_tween.tween_property(slot, "scale", Vector2(1.0, 1.0), 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_arrival_tween.tween_property(slot, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.28)
