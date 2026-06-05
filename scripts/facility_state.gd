class_name FacilityState
extends RefCounted

enum RoundState {
	RUNNING,
	TIME_EXPIRED,
}

enum SystemStatus {
	STABLE,
	WARNING,
	DANGER,
	CRITICAL,
}

const DEFAULT_ROUND_DURATION_SECONDS: float = 90.0
const MIN_VALUE: float = 0.0
const MAX_VALUE: float = 100.0

const SAFE_LIMIT: float = 55.0
const WARNING_LIMIT: float = 74.0
const DANGER_LIMIT: float = 89.0
const CATASTROPHIC_LIMIT: float = 90.0

const INITIAL_TEMPERATURE: float = 72.0
const INITIAL_PRESSURE: float = 41.0
const INITIAL_POWER_LOAD: float = 83.0
const INITIAL_INTEGRITY: float = 100.0

const TEMPERATURE_DRIFT_PER_SECOND: float = 0.18
const PRESSURE_DRIFT_PER_SECOND: float = 0.10
const POWER_DRIFT_PER_SECOND: float = 0.12

const TEMPERATURE_WAVE_AMOUNT: float = 6.0
const PRESSURE_WAVE_AMOUNT: float = 9.0
const POWER_WAVE_AMOUNT: float = 7.0

const TREND_TOLERANCE: float = 0.28
const STRONG_TREND_TOLERANCE: float = 1.15
const TREND_SAMPLE_INTERVAL: float = 0.25

const BASE_CRITICAL_DRAIN_PER_SECOND: float = 0.75
const EXCESS_CRITICAL_DRAIN_PER_SECOND: float = 0.08
const MULTIPLE_CRITICAL_DRAIN_BONUS: float = 0.45

var temperature: float = INITIAL_TEMPERATURE
var pressure: float = INITIAL_PRESSURE
var power_load: float = INITIAL_POWER_LOAD
var integrity: float = INITIAL_INTEGRITY
var elapsed_time: float = 0.0
var remaining_time: float = DEFAULT_ROUND_DURATION_SECONDS
var panic_level: float = 0.0
var round_state: RoundState = RoundState.RUNNING

var temperature_trend: String = "→"
var pressure_trend: String = "→"
var power_load_trend: String = "→"

var _round_duration_seconds: float = DEFAULT_ROUND_DURATION_SECONDS
var _trend_sample_time: float = 0.0
var _sampled_temperature: float = INITIAL_TEMPERATURE
var _sampled_pressure: float = INITIAL_PRESSURE
var _sampled_power_load: float = INITIAL_POWER_LOAD


func _init(round_duration_seconds: float = DEFAULT_ROUND_DURATION_SECONDS) -> void:
	reset(round_duration_seconds)


func reset(round_duration_seconds: float = DEFAULT_ROUND_DURATION_SECONDS) -> void:
	_round_duration_seconds = maxf(round_duration_seconds, 1.0)
	temperature = INITIAL_TEMPERATURE
	pressure = INITIAL_PRESSURE
	power_load = INITIAL_POWER_LOAD
	integrity = INITIAL_INTEGRITY
	elapsed_time = 0.0
	remaining_time = _round_duration_seconds
	panic_level = 0.0
	round_state = RoundState.RUNNING
	temperature_trend = "→"
	pressure_trend = "→"
	power_load_trend = "→"
	_trend_sample_time = 0.0
	_sampled_temperature = temperature
	_sampled_pressure = pressure
	_sampled_power_load = power_load


func advance(delta_seconds: float) -> void:
	if round_state != RoundState.RUNNING:
		return

	var safe_delta: float = maxf(delta_seconds, 0.0)
	var previous_elapsed_time: float = elapsed_time
	elapsed_time = minf(elapsed_time + safe_delta, _round_duration_seconds)
	remaining_time = maxf(_round_duration_seconds - elapsed_time, 0.0)

	_update_system_values(elapsed_time)
	_update_trends(previous_elapsed_time)
	_update_integrity(safe_delta)
	_update_panic_level()

	if is_zero_approx(remaining_time):
		round_state = RoundState.TIME_EXPIRED


func get_status(value: float) -> int:
	if value >= CATASTROPHIC_LIMIT:
		return SystemStatus.CRITICAL
	if value > WARNING_LIMIT:
		return SystemStatus.DANGER
	if value > SAFE_LIMIT:
		return SystemStatus.WARNING
	return SystemStatus.STABLE


func get_status_text(value: float) -> String:
	match get_status(value):
		SystemStatus.CRITICAL:
			return "CRITICAL"
		SystemStatus.DANGER:
			return "DANGER"
		SystemStatus.WARNING:
			return "WARNING"
		_:
			return "STABLE"


func get_critical_system_count() -> int:
	var critical_count: int = 0
	for value: float in [temperature, pressure, power_load]:
		if value >= CATASTROPHIC_LIMIT:
			critical_count += 1
	return critical_count


func _update_system_values(time_seconds: float) -> void:
	temperature = clampf(
		INITIAL_TEMPERATURE
		+ (TEMPERATURE_DRIFT_PER_SECOND * time_seconds)
		+ (sin(time_seconds * 0.16) * TEMPERATURE_WAVE_AMOUNT)
		- (sin(time_seconds * 0.047) * 2.5),
		MIN_VALUE,
		MAX_VALUE
	)
	pressure = clampf(
		INITIAL_PRESSURE
		+ (PRESSURE_DRIFT_PER_SECOND * time_seconds)
		+ ((sin((time_seconds * 0.11) + 0.5) - sin(0.5)) * PRESSURE_WAVE_AMOUNT)
		+ (sin(time_seconds * 0.29) * 4.0),
		MIN_VALUE,
		MAX_VALUE
	)
	power_load = clampf(
		INITIAL_POWER_LOAD
		+ (POWER_DRIFT_PER_SECOND * time_seconds)
		+ ((sin((time_seconds * 0.13) + 1.4) - sin(1.4)) * POWER_WAVE_AMOUNT)
		- (sin(time_seconds * 0.05) * 3.0),
		MIN_VALUE,
		MAX_VALUE
	)


func _update_trends(previous_elapsed_time: float) -> void:
	if elapsed_time - _trend_sample_time < TREND_SAMPLE_INTERVAL and elapsed_time > previous_elapsed_time:
		return

	temperature_trend = _trend_from_delta(temperature - _sampled_temperature)
	pressure_trend = _trend_from_delta(pressure - _sampled_pressure)
	power_load_trend = _trend_from_delta(power_load - _sampled_power_load)
	_trend_sample_time = elapsed_time
	_sampled_temperature = temperature
	_sampled_pressure = pressure
	_sampled_power_load = power_load


func _trend_from_delta(value_delta: float) -> String:
	if value_delta >= STRONG_TREND_TOLERANCE:
		return "↑↑"
	if value_delta >= TREND_TOLERANCE:
		return "↑"
	if value_delta <= -STRONG_TREND_TOLERANCE:
		return "↓↓"
	if value_delta <= -TREND_TOLERANCE:
		return "↓"
	return "→"


func _update_integrity(delta_seconds: float) -> void:
	var critical_count: int = get_critical_system_count()
	if critical_count == 0:
		return

	var critical_excess: float = 0.0
	for value: float in [temperature, pressure, power_load]:
		if value >= CATASTROPHIC_LIMIT:
			critical_excess += value - CATASTROPHIC_LIMIT

	var drain_rate: float = (
		BASE_CRITICAL_DRAIN_PER_SECOND * float(critical_count)
		+ EXCESS_CRITICAL_DRAIN_PER_SECOND * critical_excess
		+ MULTIPLE_CRITICAL_DRAIN_BONUS * maxf(float(critical_count - 1), 0.0)
	)
	integrity = clampf(integrity - (drain_rate * delta_seconds), MIN_VALUE, MAX_VALUE)


func _update_panic_level() -> void:
	var highest_system_value: float = maxf(temperature, maxf(pressure, power_load))
	var stressed_systems: int = 0
	for value: float in [temperature, pressure, power_load]:
		if value > SAFE_LIMIT:
			stressed_systems += 1

	var system_pressure: float = clampf((highest_system_value - SAFE_LIMIT) / (MAX_VALUE - SAFE_LIMIT), 0.0, 1.0)
	var spread_pressure: float = float(stressed_systems) / 3.0
	var integrity_pressure: float = 1.0 - (integrity / INITIAL_INTEGRITY)
	var time_pressure: float = 1.0 - (remaining_time / _round_duration_seconds)
	panic_level = clampf(
		(system_pressure * 0.45)
		+ (spread_pressure * 0.20)
		+ (integrity_pressure * 0.25)
		+ (time_pressure * 0.10),
		0.0,
		1.0
	)
