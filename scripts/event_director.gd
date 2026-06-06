class_name EventDirector
extends RefCounted

signal event_raised(event_data: Dictionary)
signal event_resolved(event_data: Dictionary)

enum EventType {
	COOLING_FAILURE,
	PRESSURE_SPIKE,
	POWER_SURGE,
	SENSOR_GLITCH,
	JAMMED_CONTROL,
}

enum Phase {
	ORIENTATION,
	ESCALATION,
	PANIC,
}

const EVENT_TYPE_COUNT: int = 5
const NO_EVENT_AFTER_SECONDS: float = 86.0
const FIRST_EVENT_NOT_BEFORE_SECONDS: float = 6.0
const FAIR_RETRY_DELAY_SECONDS: float = 1.0

const COOLING_FAILURE_DURATION: float = 7.5
const PRESSURE_SPIKE_DURATION: float = 5.0
const POWER_SURGE_DURATION: float = 4.5
const SENSOR_GLITCH_DURATION: float = 6.5
const JAMMED_CONTROL_DURATION: float = 6.5

var use_fixed_seed: bool = true
var fixed_seed: int = 1337
var active_seed: int = 1337

var _facility_state: FacilityState
var _interventions: InterventionController
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _active_events: Array[Dictionary] = []
var _next_event_time: float = 0.0
var _last_event_type: int = -1
var _last_target_key: String = ""
var _next_event_id: int = 1


func configure(
	state: FacilityState,
	intervention_controller: InterventionController,
	use_fixed: bool,
	seed: int
) -> void:
	_facility_state = state
	_interventions = intervention_controller
	use_fixed_seed = use_fixed
	fixed_seed = seed
	_validate_configuration()
	reset()


func reset() -> void:
	_active_events.clear()
	_next_event_id = 1
	_last_event_type = -1
	_last_target_key = ""
	active_seed = fixed_seed if use_fixed_seed else int(Time.get_unix_time_from_system())
	_rng.seed = active_seed
	_next_event_time = _interval_for_phase(Phase.ORIENTATION)


func advance(delta_seconds: float, elapsed_time: float) -> void:
	var safe_delta: float = maxf(delta_seconds, 0.0)
	_update_active_events(safe_delta)

	if elapsed_time >= NO_EVENT_AFTER_SECONDS:
		return

	if elapsed_time >= _next_event_time:
		if _try_raise_event(elapsed_time):
			_schedule_next_event(elapsed_time)
		else:
			_next_event_time = elapsed_time + FAIR_RETRY_DELAY_SECONDS


func has_resettable_events() -> bool:
	for event: Dictionary in _active_events:
		var event_type: int = int(event["type"])
		if event_type == EventType.SENSOR_GLITCH or event_type == EventType.JAMMED_CONTROL:
			return true
	return false


func clear_resettable_events() -> void:
	var index: int = _active_events.size() - 1
	while index >= 0:
		var event: Dictionary = _active_events[index]
		var event_type: int = int(event["type"])
		if event_type == EventType.SENSOR_GLITCH or event_type == EventType.JAMMED_CONTROL:
			_resolve_event_at(index, true)
		index -= 1


func get_active_event_count() -> int:
	return _active_events.size()


func set_seed_settings(use_fixed: bool, seed: int) -> void:
	use_fixed_seed = use_fixed
	fixed_seed = seed


func force_event(event_type: int, elapsed_time: float) -> bool:
	if event_type < 0 or event_type >= EVENT_TYPE_COUNT:
		return false
	var event: Dictionary = _build_event(event_type, elapsed_time)
	if event.is_empty():
		return false
	_active_events.append(event)
	_last_event_type = event_type
	_last_target_key = str(event["target_key"])
	event_raised.emit(event.duplicate(true))
	return true


func _update_active_events(delta_seconds: float) -> void:
	var index: int = _active_events.size() - 1
	while index >= 0:
		var event: Dictionary = _active_events[index]
		event["remaining"] = maxf(float(event["remaining"]) - delta_seconds, 0.0)
		_active_events[index] = event
		if is_zero_approx(float(event["remaining"])):
			_resolve_event_at(index, false)
		index -= 1


func _try_raise_event(elapsed_time: float) -> bool:
	var phase: int = _phase_for_elapsed(elapsed_time)
	if _active_events.size() >= _max_active_for_phase(phase):
		return false

	var fair_types: Array[int] = _fair_event_types(phase, elapsed_time)
	if fair_types.is_empty():
		return false

	var event_type: int = fair_types[_rng.randi_range(0, fair_types.size() - 1)]
	var event: Dictionary = _build_event(event_type, elapsed_time)
	if event.is_empty():
		return false

	_active_events.append(event)
	_last_event_type = event_type
	_last_target_key = str(event["target_key"])
	event_raised.emit(event.duplicate(true))
	return true


func _fair_event_types(phase: int, elapsed_time: float) -> Array[int]:
	var weighted_types: Array[int] = _weighted_types_for_phase(phase, elapsed_time)
	var fair_types: Array[int] = []
	for event_type: int in weighted_types:
		if _is_event_type_fair(event_type, phase):
			fair_types.append(event_type)
	return fair_types


func _weighted_types_for_phase(phase: int, elapsed_time: float) -> Array[int]:
	match phase:
		Phase.ORIENTATION:
			var types: Array[int] = [
				EventType.COOLING_FAILURE,
				EventType.PRESSURE_SPIKE,
				EventType.POWER_SURGE,
			]
			if elapsed_time >= 15.0:
				types.append(EventType.SENSOR_GLITCH)
			return types
		Phase.ESCALATION:
			return [
				EventType.COOLING_FAILURE,
				EventType.PRESSURE_SPIKE,
				EventType.POWER_SURGE,
				EventType.SENSOR_GLITCH,
				EventType.JAMMED_CONTROL,
			]
		_:
			return [
				EventType.COOLING_FAILURE,
				EventType.PRESSURE_SPIKE,
				EventType.POWER_SURGE,
				EventType.POWER_SURGE,
				EventType.SENSOR_GLITCH,
				EventType.JAMMED_CONTROL,
			]


func _is_event_type_fair(event_type: int, phase: int) -> bool:
	if event_type == _last_event_type:
		return false
	if _has_active_type(event_type):
		return false

	match event_type:
		EventType.COOLING_FAILURE:
			return _is_physical_event_fair(FacilityState.SYSTEM_TEMPERATURE, InterventionController.Action.COOL, "SYS-T01")
		EventType.PRESSURE_SPIKE:
			return _is_physical_event_fair(FacilityState.SYSTEM_PRESSURE, InterventionController.Action.VENT, "SYS-P02")
		EventType.POWER_SURGE:
			return _is_physical_event_fair(FacilityState.SYSTEM_POWER_LOAD, InterventionController.Action.REROUTE, "SYS-E03")
		EventType.SENSOR_GLITCH:
			if _has_active_type(EventType.JAMMED_CONTROL) and phase == Phase.ORIENTATION:
				return false
			return _select_sensor_target() != -1
		EventType.JAMMED_CONTROL:
			if phase == Phase.ORIENTATION and _has_active_type(EventType.SENSOR_GLITCH):
				return false
			return _select_jammed_action() != -1
	return false


func _is_physical_event_fair(system_id: int, counter_action: int, target_key: String) -> bool:
	if target_key == _last_target_key:
		return false
	var value: float = _value_for_system(system_id)
	if value >= 92.0 and _interventions.is_action_counter_unavailable(counter_action) and not _interventions.has_manual_override_available():
		return false
	return true


func _build_event(event_type: int, elapsed_time: float) -> Dictionary:
	var event: Dictionary = {
		"id": _next_event_id,
		"type": event_type,
		"elapsed_time": elapsed_time,
		"remaining": 0.0,
		"duration": 0.0,
		"title": "",
		"source": "",
		"target_system": -1,
		"target_action": -1,
		"target_key": "",
		"severity": "warning",
	}
	_next_event_id += 1

	match event_type:
		EventType.COOLING_FAILURE:
			event["duration"] = COOLING_FAILURE_DURATION
			event["remaining"] = COOLING_FAILURE_DURATION
			event["title"] = "COOLING FAILURE"
			event["source"] = "LOOP 01"
			event["target_system"] = FacilityState.SYSTEM_TEMPERATURE
			event["target_key"] = "SYS-T01"
			if _facility_state.temperature >= FacilityState.CATASTROPHIC_LIMIT:
				event["severity"] = "danger"
		EventType.PRESSURE_SPIKE:
			event["duration"] = PRESSURE_SPIKE_DURATION
			event["remaining"] = PRESSURE_SPIKE_DURATION
			event["title"] = "PRESSURE SPIKE"
			event["source"] = "SECTOR B"
			event["target_system"] = FacilityState.SYSTEM_PRESSURE
			event["target_key"] = "SYS-P02"
		EventType.POWER_SURGE:
			event["duration"] = POWER_SURGE_DURATION
			event["remaining"] = POWER_SURGE_DURATION
			event["title"] = "POWER SURGE"
			event["source"] = "MAIN BUS"
			event["target_system"] = FacilityState.SYSTEM_POWER_LOAD
			event["target_key"] = "SYS-E03"
			event["severity"] = "danger"
		EventType.SENSOR_GLITCH:
			var sensor_target: int = _select_sensor_target()
			if sensor_target == -1:
				return {}
			event["duration"] = SENSOR_GLITCH_DURATION
			event["remaining"] = SENSOR_GLITCH_DURATION
			event["title"] = "SENSOR SIGNAL LOST"
			event["source"] = _source_for_system(sensor_target)
			event["target_system"] = sensor_target
			event["target_key"] = _source_for_system(sensor_target)
		EventType.JAMMED_CONTROL:
			var jammed_action: int = _select_jammed_action()
			if jammed_action == -1:
				return {}
			event["duration"] = JAMMED_CONTROL_DURATION
			event["remaining"] = JAMMED_CONTROL_DURATION
			event["title"] = "CONTROL JAMMED"
			event["source"] = _source_for_action(jammed_action)
			event["target_action"] = jammed_action
			event["target_key"] = _source_for_action(jammed_action)
	return event


func _resolve_event_at(index: int, forced: bool) -> void:
	var event: Dictionary = _active_events[index]
	event["forced"] = forced
	_active_events.remove_at(index)
	event_resolved.emit(event.duplicate(true))


func _schedule_next_event(elapsed_time: float) -> void:
	_next_event_time = elapsed_time + _interval_for_phase(_phase_for_elapsed(elapsed_time))


func _interval_for_phase(phase: int) -> float:
	match phase:
		Phase.ORIENTATION:
			return _rng.randf_range(9.0, 12.0)
		Phase.ESCALATION:
			return _rng.randf_range(7.0, 10.0)
		_:
			return _rng.randf_range(5.0, 8.0)


func _phase_for_elapsed(elapsed_time: float) -> int:
	if elapsed_time < 30.0:
		return Phase.ORIENTATION
	if elapsed_time < 60.0:
		return Phase.ESCALATION
	return Phase.PANIC


func _max_active_for_phase(phase: int) -> int:
	if phase == Phase.ORIENTATION:
		return 1
	return 2


func _has_active_type(event_type: int) -> bool:
	for event: Dictionary in _active_events:
		if int(event["type"]) == event_type:
			return true
	return false


func _select_sensor_target() -> int:
	var possible_targets: Array[int] = []
	for system_id: int in [FacilityState.SYSTEM_TEMPERATURE, FacilityState.SYSTEM_PRESSURE, FacilityState.SYSTEM_POWER_LOAD]:
		var target_key: String = _source_for_system(system_id)
		if not _facility_state.is_sensor_glitched(system_id) and target_key != _last_target_key:
			possible_targets.append(system_id)
	if possible_targets.is_empty():
		return -1
	return possible_targets[_rng.randi_range(0, possible_targets.size() - 1)]


func _select_jammed_action() -> int:
	var possible_actions: Array[int] = []
	for action: int in [InterventionController.Action.COOL, InterventionController.Action.VENT, InterventionController.Action.REROUTE]:
		var target_key: String = _source_for_action(action)
		if not _interventions.is_action_jammed(action) and target_key != _last_target_key:
			possible_actions.append(action)
	if possible_actions.is_empty():
		return -1
	return possible_actions[_rng.randi_range(0, possible_actions.size() - 1)]


func _value_for_system(system_id: int) -> float:
	match system_id:
		FacilityState.SYSTEM_TEMPERATURE:
			return _facility_state.temperature
		FacilityState.SYSTEM_PRESSURE:
			return _facility_state.pressure
		_:
			return _facility_state.power_load


func _source_for_system(system_id: int) -> String:
	match system_id:
		FacilityState.SYSTEM_TEMPERATURE:
			return "SYS-T01"
		FacilityState.SYSTEM_PRESSURE:
			return "SYS-P02"
		_:
			return "SYS-E03"


func _source_for_action(action: int) -> String:
	match action:
		InterventionController.Action.COOL:
			return "COOL"
		InterventionController.Action.VENT:
			return "VENT"
		_:
			return "REROUTE"


func _validate_configuration() -> void:
	if _facility_state == null or _interventions == null:
		push_error("EventDirector requires FacilityState and InterventionController.")
		assert(false)
