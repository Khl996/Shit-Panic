class_name InterventionController
extends RefCounted

signal state_changed

enum Action {
	COOL,
	VENT,
	REROUTE,
	RESET,
	OVERRIDE,
}

const DEFAULT_FEEDBACK: String = "CONTROL INPUT READY"
const EXPIRED_FEEDBACK: String = "SHIFT COMPLETE — CONTROLS LOCKED"
const GLOBAL_LOCK_SECONDS: float = 2.5
const MANUAL_OVERRIDE_MAX_USES: int = 2

const COOLDOWN_SECONDS: Array[float] = [
	6.0,
	7.0,
	8.0,
	10.0,
	12.0,
]

const BUTTON_LABELS: Array[String] = [
	"[1] EMERGENCY COOL\nTEMP ↓ / POWER ↑",
	"[2] PRESSURE VENT\nPRESSURE ↓ / HEAT ↑",
	"[3] REROUTE POWER\nLOAD ↓ / COOLING ↓",
	"[4] SYSTEM RESET\nCLEARS CONTROL FAULTS",
	"[5] MANUAL OVERRIDE\nCRITICAL RECOVERY",
]

var facility_state: FacilityState
var buttons: Array[Button] = []
var override_remaining_label: Label
var feedback_label: Label
var cooldowns: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]
var manual_override_uses: int = MANUAL_OVERRIDE_MAX_USES
var global_lock_remaining: float = 0.0
var inputs_expired: bool = false


func configure(
	state: FacilityState,
	cool_button: Button,
	vent_button: Button,
	reroute_button: Button,
	reset_button: Button,
	override_button: Button,
	remaining_label: Label,
	action_feedback_label: Label
) -> void:
	facility_state = state
	buttons = [cool_button, vent_button, reroute_button, reset_button, override_button]
	override_remaining_label = remaining_label
	feedback_label = action_feedback_label
	_validate_configuration()
	_connect_buttons()
	reset()


func reset() -> void:
	cooldowns = [0.0, 0.0, 0.0, 0.0, 0.0]
	manual_override_uses = MANUAL_OVERRIDE_MAX_USES
	global_lock_remaining = 0.0
	inputs_expired = false
	_set_feedback(DEFAULT_FEEDBACK)
	_update_button_states()


func advance(delta_seconds: float) -> void:
	if inputs_expired:
		_update_button_states()
		return

	var safe_delta: float = maxf(delta_seconds, 0.0)
	global_lock_remaining = maxf(global_lock_remaining - safe_delta, 0.0)
	for index: int in range(cooldowns.size()):
		cooldowns[index] = maxf(cooldowns[index] - safe_delta, 0.0)
	_update_button_states()


func expire_controls() -> void:
	inputs_expired = true
	_set_feedback(EXPIRED_FEEDBACK)
	_update_button_states()


func handle_key_input(event: InputEvent) -> bool:
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return false

	match key_event.physical_keycode:
		KEY_1:
			return try_action(Action.COOL)
		KEY_2:
			return try_action(Action.VENT)
		KEY_3:
			return try_action(Action.REROUTE)
		KEY_4:
			return try_action(Action.RESET)
		KEY_5:
			return try_action(Action.OVERRIDE)
		_:
			return false


func try_action(action: int) -> bool:
	if inputs_expired:
		_set_feedback(EXPIRED_FEEDBACK)
		_update_button_states()
		state_changed.emit()
		return true

	if global_lock_remaining > 0.0:
		_set_feedback("CONTROLS LOCKED")
		_update_button_states()
		state_changed.emit()
		return true

	if action == Action.OVERRIDE and manual_override_uses <= 0:
		_set_feedback("MANUAL OVERRIDE DEPLETED")
		_update_button_states()
		state_changed.emit()
		return true

	if cooldowns[action] > 0.0:
		_set_feedback("ACTION ON COOLDOWN")
		_update_button_states()
		state_changed.emit()
		return true

	match action:
		Action.COOL:
			facility_state.apply_emergency_cooling()
			_start_cooldown(action)
			_set_feedback("EMERGENCY COOLING ENGAGED")
		Action.VENT:
			facility_state.apply_pressure_vent()
			_start_cooldown(action)
			_set_feedback("PRESSURE VENT OPEN")
		Action.REROUTE:
			facility_state.apply_power_reroute()
			_start_cooldown(action)
			_set_feedback("POWER REROUTED — COOLING DEGRADED")
		Action.RESET:
			if not facility_state.apply_system_reset():
				_set_feedback("NO CONTROL FAULT TO RESET")
				_update_button_states()
				state_changed.emit()
				return true
			global_lock_remaining = GLOBAL_LOCK_SECONDS
			_start_cooldown(action)
			_set_feedback("CONTROL RESET IN PROGRESS")
		Action.OVERRIDE:
			var target_name: String = facility_state.apply_manual_override()
			manual_override_uses -= 1
			_start_cooldown(action)
			_set_feedback("MANUAL OVERRIDE APPLIED TO %s" % target_name)

	_update_button_states()
	state_changed.emit()
	return true


func _connect_buttons() -> void:
	for index: int in range(buttons.size()):
		if not buttons[index].pressed.is_connected(try_action.bind(index)):
			buttons[index].pressed.connect(try_action.bind(index))


func _start_cooldown(action: int) -> void:
	cooldowns[action] = COOLDOWN_SECONDS[action]


func _update_button_states() -> void:
	override_remaining_label.text = "MANUAL OVERRIDE: %d REMAINING" % manual_override_uses
	for index: int in range(buttons.size()):
		var state_text: String = _state_text_for(index)
		buttons[index].text = "%s\n%s" % [BUTTON_LABELS[index], state_text]
		buttons[index].disabled = _is_button_disabled(index)


func _state_text_for(action: int) -> String:
	if inputs_expired:
		return "LOCKED"
	if global_lock_remaining > 0.0:
		return "LOCKED"
	if action == Action.OVERRIDE and manual_override_uses <= 0:
		return "NO USES"
	if cooldowns[action] > 0.0:
		return "%.1fs" % cooldowns[action]
	return "READY"


func _is_button_disabled(action: int) -> bool:
	if inputs_expired or global_lock_remaining > 0.0:
		return true
	if action == Action.OVERRIDE and manual_override_uses <= 0:
		return true
	return cooldowns[action] > 0.0


func _set_feedback(message: String) -> void:
	feedback_label.text = message


func _validate_configuration() -> void:
	if facility_state == null:
		push_error("InterventionController requires a FacilityState.")
		assert(false)
	if buttons.size() != BUTTON_LABELS.size():
		push_error("InterventionController requires exactly five buttons.")
		assert(false)
	for button: Button in buttons:
		if not is_instance_valid(button):
			push_error("InterventionController is missing a required Button.")
			assert(false)
	if not is_instance_valid(override_remaining_label) or not is_instance_valid(feedback_label):
		push_error("InterventionController is missing required action labels.")
		assert(false)
