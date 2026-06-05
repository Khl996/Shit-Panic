extends Control

@export var round_duration_seconds: float = 90.0

var facility_state: FacilityState

const STABLE_COLOR: Color = Color(0.411765, 0.717647, 0.682353, 1)
const WARNING_COLOR: Color = Color(0.831373, 0.603922, 0.164706, 1)
const DANGER_COLOR: Color = Color(0.788235, 0.294118, 0.258824, 1)

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

var _bar_styles: Dictionary = {}
var _led_styles: Dictionary = {}


func _ready() -> void:
	_build_status_styles()
	facility_state = FacilityState.new(round_duration_seconds)
	_validate_required_nodes()
	_update_ui()


func _process(delta: float) -> void:
	if facility_state.round_state == FacilityState.RoundState.RUNNING:
		facility_state.advance(delta)
		_update_ui()


func reset_round() -> void:
	facility_state.reset(round_duration_seconds)
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
	]

	for required_node: Node in required_nodes:
		if not is_instance_valid(required_node):
			push_error("ManualOverride is missing a required UI node for Milestone 2.")
			assert(false)


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
		facility_state.temperature,
		facility_state.temperature_trend
	)
	_update_system_ui(
		pressure_value_label,
		pressure_meter,
		pressure_state_label,
		pressure_trend_label,
		pressure_led,
		facility_state.pressure,
		facility_state.pressure_trend
	)
	_update_system_ui(
		power_value_label,
		power_meter,
		power_state_label,
		power_trend_label,
		power_led,
		facility_state.power_load,
		facility_state.power_load_trend
	)


func _update_system_ui(
	value_label: Label,
	meter: ProgressBar,
	state_label: Label,
	trend_label: Label,
	led_panel: Panel,
	value: float,
	trend_text: String
) -> void:
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
