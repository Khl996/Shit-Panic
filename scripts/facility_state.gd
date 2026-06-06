class_name FacilityState
extends RefCounted

enum RoundState {
	RUNNING,
	SURVIVED,
	LOST,
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

const BASE_CRITICAL_DRAIN_PER_SECOND: float = 0.62
const EXCESS_CRITICAL_DRAIN_PER_SECOND: float = 0.065
const MULTIPLE_CRITICAL_DRAIN_BONUS: float = 0.35

const EMERGENCY_COOL_TEMPERATURE_DELTA: float = -14.0
const EMERGENCY_COOL_POWER_DELTA: float = 6.0
const PRESSURE_VENT_PRESSURE_DELTA: float = -18.0
const PRESSURE_VENT_TEMPERATURE_DELTA: float = 5.0
const POWER_REROUTE_POWER_DELTA: float = -16.0
const REROUTE_COOLING_PENALTY_DURATION: float = 6.0
const REROUTE_TEMPERATURE_PENALTY_PER_SECOND: float = 0.9
const SYSTEM_RESET_POWER_DELTA: float = 4.0
const MANUAL_OVERRIDE_PRIMARY_DELTA: float = -24.0
const MANUAL_OVERRIDE_SIDE_DELTA: float = 5.0
const MANUAL_OVERRIDE_INTEGRITY_RESTORE: float = 5.0
const COOLING_FAILURE_TEMPERATURE_DELTA: float = 5.0
const COOLING_FAILURE_TEMPERATURE_PER_SECOND: float = 1.2
const PRESSURE_SPIKE_PRESSURE_DELTA: float = 14.0
const PRESSURE_SPIKE_PRESSURE_PER_SECOND: float = 0.7
const POWER_SURGE_POWER_DELTA: float = 15.0
const POWER_SURGE_POWER_PER_SECOND: float = 0.8

const SYSTEM_TEMPERATURE: int = 0
const SYSTEM_PRESSURE: int = 1
const SYSTEM_POWER_LOAD: int = 2

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
var _temperature_offset: float = 0.0
var _pressure_offset: float = 0.0
var _power_load_offset: float = 0.0
var _reroute_cooling_penalty_remaining: float = 0.0
var _cooling_failure_remaining: float = 0.0
var _pressure_spike_remaining: float = 0.0
var _power_surge_remaining: float = 0.0
var _sensor_glitch_system: int = -1


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
	_temperature_offset = 0.0
	_pressure_offset = 0.0
	_power_load_offset = 0.0
	_reroute_cooling_penalty_remaining = 0.0
	_cooling_failure_remaining = 0.0
	_pressure_spike_remaining = 0.0
	_power_surge_remaining = 0.0
	_sensor_glitch_system = -1


func advance(delta_seconds: float) -> void:
	if round_state != RoundState.RUNNING:
		return

	var safe_delta: float = maxf(delta_seconds, 0.0)
	var previous_elapsed_time: float = elapsed_time
	elapsed_time = minf(elapsed_time + safe_delta, _round_duration_seconds)
	remaining_time = maxf(_round_duration_seconds - elapsed_time, 0.0)

	_update_temporary_modifiers(safe_delta)
	_update_event_modifiers(safe_delta)
	_update_system_values(elapsed_time)
	_update_trends(previous_elapsed_time)
	_update_integrity(safe_delta)
	_update_panic_level()

	if integrity <= MIN_VALUE:
		round_state = RoundState.LOST
	elif is_zero_approx(remaining_time):
		round_state = RoundState.SURVIVED


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


func is_finished() -> bool:
	return round_state == RoundState.SURVIVED or round_state == RoundState.LOST


func force_survival() -> void:
	if round_state != RoundState.RUNNING:
		return
	elapsed_time = _round_duration_seconds
	remaining_time = 0.0
	round_state = RoundState.SURVIVED if integrity > MIN_VALUE else RoundState.LOST


func force_loss() -> void:
	if round_state != RoundState.RUNNING:
		return
	integrity = MIN_VALUE
	round_state = RoundState.LOST


func get_most_stressed_system_name() -> String:
	if temperature >= pressure and temperature >= power_load:
		return "TEMPERATURE"
	if pressure >= power_load:
		return "PRESSURE"
	return "POWER LOAD"


func has_active_temporary_modifier() -> bool:
	return _reroute_cooling_penalty_remaining > 0.0


func has_sensor_glitch() -> bool:
	return _sensor_glitch_system >= 0


func is_sensor_glitched(system_id: int) -> bool:
	return _sensor_glitch_system == system_id


func has_active_resettable_fault() -> bool:
	return has_active_temporary_modifier() or has_sensor_glitch()


func apply_emergency_cooling() -> void:
	_temperature_offset += EMERGENCY_COOL_TEMPERATURE_DELTA
	_power_load_offset += EMERGENCY_COOL_POWER_DELTA
	_update_system_values(elapsed_time)


func apply_pressure_vent() -> void:
	_pressure_offset += PRESSURE_VENT_PRESSURE_DELTA
	_temperature_offset += PRESSURE_VENT_TEMPERATURE_DELTA
	_update_system_values(elapsed_time)


func apply_power_reroute() -> void:
	_power_load_offset += POWER_REROUTE_POWER_DELTA
	_reroute_cooling_penalty_remaining = REROUTE_COOLING_PENALTY_DURATION
	_update_system_values(elapsed_time)


func apply_system_reset() -> bool:
	if not has_active_resettable_fault():
		return false
	perform_system_reset()
	return true


func perform_system_reset() -> void:
	clear_resettable_faults()
	_power_load_offset += SYSTEM_RESET_POWER_DELTA
	_update_system_values(elapsed_time)


func clear_resettable_faults() -> void:
	_reroute_cooling_penalty_remaining = 0.0
	clear_sensor_glitches()


func apply_manual_override() -> String:
	# Ties resolve Temperature, then Pressure, then Power Load for deterministic playtests.
	var target_name: String = "TEMPERATURE"
	if pressure > temperature and pressure >= power_load:
		target_name = "PRESSURE"
	elif power_load > temperature and power_load > pressure:
		target_name = "POWER LOAD"

	match target_name:
		"TEMPERATURE":
			_temperature_offset += MANUAL_OVERRIDE_PRIMARY_DELTA
			_pressure_offset += MANUAL_OVERRIDE_SIDE_DELTA
			_power_load_offset += MANUAL_OVERRIDE_SIDE_DELTA
		"PRESSURE":
			_pressure_offset += MANUAL_OVERRIDE_PRIMARY_DELTA
			_temperature_offset += MANUAL_OVERRIDE_SIDE_DELTA
			_power_load_offset += MANUAL_OVERRIDE_SIDE_DELTA
		"POWER LOAD":
			_power_load_offset += MANUAL_OVERRIDE_PRIMARY_DELTA
			_temperature_offset += MANUAL_OVERRIDE_SIDE_DELTA
			_pressure_offset += MANUAL_OVERRIDE_SIDE_DELTA

	integrity = clampf(integrity + MANUAL_OVERRIDE_INTEGRITY_RESTORE, MIN_VALUE, MAX_VALUE)
	_update_system_values(elapsed_time)
	_update_panic_level()
	return target_name


func apply_cooling_failure(duration_seconds: float) -> void:
	_temperature_offset += COOLING_FAILURE_TEMPERATURE_DELTA
	_cooling_failure_remaining = maxf(_cooling_failure_remaining, duration_seconds)
	_update_system_values(elapsed_time)


func clear_cooling_failure() -> void:
	_cooling_failure_remaining = 0.0


func apply_pressure_spike(duration_seconds: float) -> void:
	_pressure_offset += PRESSURE_SPIKE_PRESSURE_DELTA
	_pressure_spike_remaining = maxf(_pressure_spike_remaining, duration_seconds)
	_update_system_values(elapsed_time)


func clear_pressure_spike() -> void:
	_pressure_spike_remaining = 0.0


func apply_power_surge(duration_seconds: float) -> void:
	_power_load_offset += POWER_SURGE_POWER_DELTA
	_power_surge_remaining = maxf(_power_surge_remaining, duration_seconds)
	_update_system_values(elapsed_time)


func clear_power_surge() -> void:
	_power_surge_remaining = 0.0


func apply_sensor_glitch(system_id: int) -> void:
	_sensor_glitch_system = system_id


func clear_sensor_glitches() -> void:
	_sensor_glitch_system = -1


func _update_system_values(time_seconds: float) -> void:
	temperature = clampf(
		INITIAL_TEMPERATURE
		+ (TEMPERATURE_DRIFT_PER_SECOND * time_seconds)
		+ (sin(time_seconds * 0.16) * TEMPERATURE_WAVE_AMOUNT)
		- (sin(time_seconds * 0.047) * 2.5)
		+ _temperature_offset,
		MIN_VALUE,
		MAX_VALUE
	)
	pressure = clampf(
		INITIAL_PRESSURE
		+ (PRESSURE_DRIFT_PER_SECOND * time_seconds)
		+ ((sin((time_seconds * 0.11) + 0.5) - sin(0.5)) * PRESSURE_WAVE_AMOUNT)
		+ (sin(time_seconds * 0.29) * 4.0)
		+ _pressure_offset,
		MIN_VALUE,
		MAX_VALUE
	)
	power_load = clampf(
		INITIAL_POWER_LOAD
		+ (POWER_DRIFT_PER_SECOND * time_seconds)
		+ ((sin((time_seconds * 0.13) + 1.4) - sin(1.4)) * POWER_WAVE_AMOUNT)
		- (sin(time_seconds * 0.05) * 3.0)
		+ _power_load_offset,
		MIN_VALUE,
		MAX_VALUE
	)


func _update_temporary_modifiers(delta_seconds: float) -> void:
	if _reroute_cooling_penalty_remaining <= 0.0:
		return

	var active_delta: float = minf(delta_seconds, _reroute_cooling_penalty_remaining)
	_temperature_offset += REROUTE_TEMPERATURE_PENALTY_PER_SECOND * active_delta
	_reroute_cooling_penalty_remaining = maxf(_reroute_cooling_penalty_remaining - delta_seconds, 0.0)


func _update_event_modifiers(delta_seconds: float) -> void:
	if _cooling_failure_remaining > 0.0:
		var cooling_delta: float = minf(delta_seconds, _cooling_failure_remaining)
		_temperature_offset += COOLING_FAILURE_TEMPERATURE_PER_SECOND * cooling_delta
		_cooling_failure_remaining = maxf(_cooling_failure_remaining - delta_seconds, 0.0)

	if _pressure_spike_remaining > 0.0:
		var pressure_delta: float = minf(delta_seconds, _pressure_spike_remaining)
		_pressure_offset += PRESSURE_SPIKE_PRESSURE_PER_SECOND * pressure_delta
		_pressure_spike_remaining = maxf(_pressure_spike_remaining - delta_seconds, 0.0)

	if _power_surge_remaining > 0.0:
		var power_delta: float = minf(delta_seconds, _power_surge_remaining)
		_power_load_offset += POWER_SURGE_POWER_PER_SECOND * power_delta
		_power_surge_remaining = maxf(_power_surge_remaining - delta_seconds, 0.0)


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
