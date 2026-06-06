extends Control

@export var round_duration_seconds: float = 90.0
@export var use_fixed_seed: bool = true
@export var fixed_seed: int = 1337

var facility_state: FacilityState
var intervention_controller: InterventionController
var event_director: EventDirector
var alarm_feed_controller: AlarmFeedController
var _controls_expired_notified: bool = false

const STABLE_COLOR: Color = Color(0.411765, 0.717647, 0.682353, 1)
const WARNING_COLOR: Color = Color(0.831373, 0.603922, 0.164706, 1)
const DANGER_COLOR: Color = Color(0.788235, 0.294118, 0.258824, 1)
const FAULT_COLOR: Color = Color(0.498039, 0.568627, 0.552941, 1)

@onready var timer_value_label: Label = get_node("OuterMargin/MainLayout/Header/HeaderPad/HeaderRow/TimerBlock/TimerValue")
@onready var integrity_value_label: Label = get_node("OuterMargin/MainLayout/Header/HeaderPad/HeaderRow/IntegrityBlock/IntegrityLine/IntegrityValue")
@onready var integrity_bar: ProgressBar = get_node("OuterMargin/MainLayout/Header/HeaderPad/HeaderRow/IntegrityBlock/IntegrityBar")

@onready var temperature_value_label: Label = get_node("OuterMargin/MainLayout/ContentArea/SystemsSection/SystemsPad/SystemsLayout/TemperaturePanel/TemperaturePad/TemperatureLayout/TemperatureReadout/TemperatureValue")
@onready var temperature_meter: ProgressBar = get_node("OuterMargin/MainLayout/ContentArea/SystemsSection/SystemsPad/SystemsLayout/TemperaturePanel/TemperaturePad/TemperatureLayout/TemperatureReadout/TemperatureMeterBlock/TemperatureMeter")
@onready var temperature_state_label: Label = get_node("OuterMargin/MainLayout/ContentArea/SystemsSection/SystemsPad/SystemsLayout/TemperaturePanel/TemperaturePad/TemperatureLayout/TemperatureReadout/TemperatureStatusBlock/TemperatureState")
@onready var temperature_trend_label: Label = get_node("OuterMargin/MainLayout/ContentArea/SystemsSection/SystemsPad/SystemsLayout/TemperaturePanel/TemperaturePad/TemperatureLayout/TemperatureReadout/TemperatureStatusBlock/TemperatureTrend")
@onready var temperature_led: Panel = get_node("OuterMargin/MainLayout/ContentArea/SystemsSection/SystemsPad/SystemsLayout/TemperaturePanel/TemperaturePad/TemperatureLayout/TemperatureTop/TemperatureLed")

@onready var pressure_value_label: Label = get_node("OuterMargin/MainLayout/ContentArea/SystemsSection/SystemsPad/SystemsLayout/PressurePanel/PressurePad/PressureLayout/PressureReadout/PressureValue")
@onready var pressure_meter: ProgressBar = get_node("OuterMargin/MainLayout/ContentArea/SystemsSection/SystemsPad/SystemsLayout/PressurePanel/PressurePad/PressureLayout/PressureReadout/PressureMeterBlock/PressureMeter")
@onready var pressure_state_label: Label = get_node("OuterMargin/MainLayout/ContentArea/SystemsSection/SystemsPad/SystemsLayout/PressurePanel/PressurePad/PressureLayout/PressureReadout/PressureStatusBlock/PressureState")
@onready var pressure_trend_label: Label = get_node("OuterMargin/MainLayout/ContentArea/SystemsSection/SystemsPad/SystemsLayout/PressurePanel/PressurePad/PressureLayout/PressureReadout/PressureStatusBlock/PressureTrend")
@onready var pressure_led: Panel = get_node("OuterMargin/MainLayout/ContentArea/SystemsSection/SystemsPad/SystemsLayout/PressurePanel/PressurePad/PressureLayout/PressureTop/PressureLed")

@onready var power_value_label: Label = get_node("OuterMargin/MainLayout/ContentArea/SystemsSection/SystemsPad/SystemsLayout/PowerPanel/PowerPad/PowerLayout/PowerReadout/PowerValue")
@onready var power_meter: ProgressBar = get_node("OuterMargin/MainLayout/ContentArea/SystemsSection/SystemsPad/SystemsLayout/PowerPanel/PowerPad/PowerLayout/PowerReadout/PowerMeterBlock/PowerMeter")
@onready var power_state_label: Label = get_node("OuterMargin/MainLayout/ContentArea/SystemsSection/SystemsPad/SystemsLayout/PowerPanel/PowerPad/PowerLayout/PowerReadout/PowerStatusBlock/PowerState")
@onready var power_trend_label: Label = get_node("OuterMargin/MainLayout/ContentArea/SystemsSection/SystemsPad/SystemsLayout/PowerPanel/PowerPad/PowerLayout/PowerReadout/PowerStatusBlock/PowerTrend")
@onready var power_led: Panel = get_node("OuterMargin/MainLayout/ContentArea/SystemsSection/SystemsPad/SystemsLayout/PowerPanel/PowerPad/PowerLayout/PowerTop/PowerLed")

@onready var action_feedback_label: Label = get_node("OuterMargin/MainLayout/ActionBar/ActionPad/ActionLayout/ActionFeedback")
@onready var override_remaining_label: Label = get_node("OuterMargin/MainLayout/ActionBar/ActionPad/ActionLayout/ActionHeader/OverrideRemaining")
@onready var cool_button: Button = get_node("OuterMargin/MainLayout/ActionBar/ActionPad/ActionLayout/ButtonRow/CoolButton")
@onready var vent_button: Button = get_node("OuterMargin/MainLayout/ActionBar/ActionPad/ActionLayout/ButtonRow/VentButton")
@onready var reroute_button: Button = get_node("OuterMargin/MainLayout/ActionBar/ActionPad/ActionLayout/ButtonRow/RerouteButton")
@onready var reset_button: Button = get_node("OuterMargin/MainLayout/ActionBar/ActionPad/ActionLayout/ButtonRow/ResetButton")
@onready var override_button: Button = get_node("OuterMargin/MainLayout/ActionBar/ActionPad/ActionLayout/ButtonRow/OverrideButton")

@onready var alarm_count_label: Label = get_node("OuterMargin/MainLayout/ContentArea/AlarmSection/AlarmPad/AlarmLayout/AlarmHeader/AlarmCount")
@onready var alarm_slots: Array[PanelContainer] = [
	get_node("OuterMargin/MainLayout/ContentArea/AlarmSection/AlarmPad/AlarmLayout/AlarmEntry1") as PanelContainer,
	get_node("OuterMargin/MainLayout/ContentArea/AlarmSection/AlarmPad/AlarmLayout/AlarmEntry2") as PanelContainer,
	get_node("OuterMargin/MainLayout/ContentArea/AlarmSection/AlarmPad/AlarmLayout/AlarmEntry3") as PanelContainer,
	get_node("OuterMargin/MainLayout/ContentArea/AlarmSection/AlarmPad/AlarmLayout/AlarmEntry4") as PanelContainer,
]
@onready var alarm_name_labels: Array[Label] = [
	get_node("OuterMargin/MainLayout/ContentArea/AlarmSection/AlarmPad/AlarmLayout/AlarmEntry1/AlarmEntry1Row/Alarm1Text/Alarm1Name") as Label,
	get_node("OuterMargin/MainLayout/ContentArea/AlarmSection/AlarmPad/AlarmLayout/AlarmEntry2/AlarmEntry2Row/Alarm2Text/Alarm2Name") as Label,
	get_node("OuterMargin/MainLayout/ContentArea/AlarmSection/AlarmPad/AlarmLayout/AlarmEntry3/AlarmEntry3Row/Alarm3Text/Alarm3Name") as Label,
	get_node("OuterMargin/MainLayout/ContentArea/AlarmSection/AlarmPad/AlarmLayout/AlarmEntry4/AlarmEntry4Row/Alarm4Text/Alarm4Name") as Label,
]
@onready var alarm_source_labels: Array[Label] = [
	get_node("OuterMargin/MainLayout/ContentArea/AlarmSection/AlarmPad/AlarmLayout/AlarmEntry1/AlarmEntry1Row/Alarm1Text/Alarm1Source") as Label,
	get_node("OuterMargin/MainLayout/ContentArea/AlarmSection/AlarmPad/AlarmLayout/AlarmEntry2/AlarmEntry2Row/Alarm2Text/Alarm2Source") as Label,
	get_node("OuterMargin/MainLayout/ContentArea/AlarmSection/AlarmPad/AlarmLayout/AlarmEntry3/AlarmEntry3Row/Alarm3Text/Alarm3Source") as Label,
	get_node("OuterMargin/MainLayout/ContentArea/AlarmSection/AlarmPad/AlarmLayout/AlarmEntry4/AlarmEntry4Row/Alarm4Text/Alarm4Source") as Label,
]
@onready var alarm_time_labels: Array[Label] = [
	get_node("OuterMargin/MainLayout/ContentArea/AlarmSection/AlarmPad/AlarmLayout/AlarmEntry1/AlarmEntry1Row/Alarm1Time") as Label,
	get_node("OuterMargin/MainLayout/ContentArea/AlarmSection/AlarmPad/AlarmLayout/AlarmEntry2/AlarmEntry2Row/Alarm2Time") as Label,
	get_node("OuterMargin/MainLayout/ContentArea/AlarmSection/AlarmPad/AlarmLayout/AlarmEntry3/AlarmEntry3Row/Alarm3Time") as Label,
	get_node("OuterMargin/MainLayout/ContentArea/AlarmSection/AlarmPad/AlarmLayout/AlarmEntry4/AlarmEntry4Row/Alarm4Time") as Label,
]

var _bar_styles: Dictionary = {}
var _led_styles: Dictionary = {}
var _fault_bar_style: StyleBoxFlat


func _ready() -> void:
	_build_status_styles()
	facility_state = FacilityState.new(round_duration_seconds)
	_validate_required_nodes()
	_configure_interventions()
	_configure_events()
	_configure_alarm_feed()
	_update_ui()


func _process(delta: float) -> void:
	if facility_state.round_state == FacilityState.RoundState.RUNNING:
		facility_state.advance(delta)
		if facility_state.round_state == FacilityState.RoundState.TIME_EXPIRED:
			_notify_controls_expired()
		else:
			intervention_controller.advance(delta)
			event_director.advance(delta, facility_state.elapsed_time)
			alarm_feed_controller.advance(delta)
		_update_ui()


func _unhandled_input(event: InputEvent) -> void:
	if intervention_controller.handle_key_input(event):
		get_viewport().set_input_as_handled()


func reset_round() -> void:
	facility_state.reset(round_duration_seconds)
	_controls_expired_notified = false
	intervention_controller.reset()
	event_director.reset()
	alarm_feed_controller.reset()
	_update_ui()


func _validate_required_nodes() -> void:
	var required_nodes: Array[Node] = [
		timer_value_label,
		integrity_value_label,
		integrity_bar,
		temperature_value_label,
		temperature_meter,
		temperature_state_label,
		temperature_trend_label,
		temperature_led,
		pressure_value_label,
		pressure_meter,
		pressure_state_label,
		pressure_trend_label,
		pressure_led,
		power_value_label,
		power_meter,
		power_state_label,
		power_trend_label,
		power_led,
		action_feedback_label,
		override_remaining_label,
		cool_button,
		vent_button,
		reroute_button,
		reset_button,
		override_button,
		alarm_count_label,
	]
	required_nodes.append_array(alarm_slots)
	required_nodes.append_array(alarm_name_labels)
	required_nodes.append_array(alarm_source_labels)
	required_nodes.append_array(alarm_time_labels)

	for required_node: Node in required_nodes:
		if not is_instance_valid(required_node):
			push_error("ManualOverride is missing a required UI node for Milestone 2.")
			assert(false)


func _configure_interventions() -> void:
	intervention_controller = InterventionController.new()
	intervention_controller.configure(
		facility_state,
		cool_button,
		vent_button,
		reroute_button,
		reset_button,
		override_button,
		override_remaining_label,
		action_feedback_label
	)
	intervention_controller.state_changed.connect(_update_ui)


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
		alarm_count_label,
		alarm_slots,
		alarm_name_labels,
		alarm_source_labels,
		alarm_time_labels
	)


func _notify_controls_expired() -> void:
	if _controls_expired_notified:
		return
	_controls_expired_notified = true
	intervention_controller.expire_controls()


func _update_ui() -> void:
	timer_value_label.text = _format_time(facility_state.remaining_time)
	integrity_value_label.text = "%d%%" % int(roundf(facility_state.integrity))
	integrity_bar.value = facility_state.integrity
	_apply_bar_status(integrity_bar, _integrity_status())

	_update_system_ui(
		temperature_value_label,
		temperature_meter,
		temperature_state_label,
		temperature_trend_label,
		temperature_led,
		FacilityState.SYSTEM_TEMPERATURE,
		facility_state.temperature,
		facility_state.temperature_trend
	)
	_update_system_ui(
		pressure_value_label,
		pressure_meter,
		pressure_state_label,
		pressure_trend_label,
		pressure_led,
		FacilityState.SYSTEM_PRESSURE,
		facility_state.pressure,
		facility_state.pressure_trend
	)
	_update_system_ui(
		power_value_label,
		power_meter,
		power_state_label,
		power_trend_label,
		power_led,
		FacilityState.SYSTEM_POWER_LOAD,
		facility_state.power_load,
		facility_state.power_load_trend
	)


func _update_system_ui(
	value_label: Label,
	meter: ProgressBar,
	state_label: Label,
	trend_label: Label,
	led_panel: Panel,
	system_id: int,
	value: float,
	trend_text: String
) -> void:
	if facility_state.is_sensor_glitched(system_id):
		value_label.text = "ERR"
		value_label.add_theme_color_override("font_color", FAULT_COLOR)
		meter.value = clampf(value, 0.0, 100.0)
		meter.add_theme_stylebox_override("fill", _fault_bar_style)
		state_label.text = "SIGNAL LOST"
		state_label.add_theme_color_override("font_color", FAULT_COLOR)
		trend_label.text = "?"
		trend_label.add_theme_color_override("font_color", FAULT_COLOR)
		led_panel.add_theme_stylebox_override("panel", _led_styles[FacilityState.SystemStatus.WARNING])
		return

	var status: int = facility_state.get_status(value)
	var color: Color = _color_for_status(status)
	value_label.text = str(int(roundf(value)))
	value_label.add_theme_color_override("font_color", color)
	meter.value = clampf(value, 0.0, 100.0)
	_apply_bar_status(meter, status)
	state_label.text = facility_state.get_status_text(value)
	state_label.add_theme_color_override("font_color", color)
	trend_label.text = trend_text
	trend_label.add_theme_color_override("font_color", color)
	led_panel.add_theme_stylebox_override("panel", _led_styles[status])


func _format_time(seconds: float) -> String:
	var whole_seconds: int = maxi(int(ceil(maxf(seconds, 0.0))), 0)
	var minutes: int = floori(float(whole_seconds) / 60.0)
	var remaining_seconds: int = whole_seconds % 60
	return "%02d:%02d" % [minutes, remaining_seconds]


func _build_status_styles() -> void:
	_bar_styles = {
		FacilityState.SystemStatus.STABLE: _make_bar_style(STABLE_COLOR),
		FacilityState.SystemStatus.WARNING: _make_bar_style(WARNING_COLOR),
		FacilityState.SystemStatus.DANGER: _make_bar_style(DANGER_COLOR),
		FacilityState.SystemStatus.CRITICAL: _make_bar_style(DANGER_COLOR),
	}
	_led_styles = {
		FacilityState.SystemStatus.STABLE: _make_led_style(STABLE_COLOR),
		FacilityState.SystemStatus.WARNING: _make_led_style(WARNING_COLOR),
		FacilityState.SystemStatus.DANGER: _make_led_style(DANGER_COLOR),
		FacilityState.SystemStatus.CRITICAL: _make_led_style(DANGER_COLOR),
	}
	_fault_bar_style = _make_bar_style(FAULT_COLOR)


func _apply_bar_status(meter: ProgressBar, status: int) -> void:
	meter.add_theme_stylebox_override("fill", _bar_styles[status])


func _color_for_status(status: int) -> Color:
	match status:
		FacilityState.SystemStatus.STABLE:
			return STABLE_COLOR
		FacilityState.SystemStatus.WARNING:
			return WARNING_COLOR
		_:
			return DANGER_COLOR


func _integrity_status() -> int:
	if facility_state.integrity >= 70.0:
		return FacilityState.SystemStatus.STABLE
	if facility_state.integrity >= 40.0:
		return FacilityState.SystemStatus.WARNING
	return FacilityState.SystemStatus.DANGER


func _make_bar_style(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 1
	style.corner_radius_top_right = 1
	style.corner_radius_bottom_right = 1
	style.corner_radius_bottom_left = 1
	return style


func _make_led_style(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	return style


func _on_event_raised(event_data: Dictionary) -> void:
	alarm_feed_controller.raise_alarm(event_data)
	match int(event_data["type"]):
		EventDirector.EventType.COOLING_FAILURE:
			facility_state.apply_cooling_failure(float(event_data["duration"]))
		EventDirector.EventType.PRESSURE_SPIKE:
			facility_state.apply_pressure_spike(float(event_data["duration"]))
		EventDirector.EventType.POWER_SURGE:
			facility_state.apply_power_surge(float(event_data["duration"]))
		EventDirector.EventType.SENSOR_GLITCH:
			facility_state.apply_sensor_glitch(int(event_data["target_system"]))
		EventDirector.EventType.JAMMED_CONTROL:
			intervention_controller.set_jammed_action(int(event_data["target_action"]))
	_update_ui()


func _on_event_resolved(event_data: Dictionary) -> void:
	alarm_feed_controller.resolve_alarm(event_data)
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
	_update_ui()
