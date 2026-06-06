class_name InterventionController
extends RefCounted

signal state_changed
signal action_accepted(action: int)
signal action_rejected(action: int, reason: String)

enum Action {
	COOL,
	VENT,
	REROUTE,
	RESET,
	OVERRIDE,
}

const DEFAULT_FEEDBACK: String = "اللاسلكي صاحي. راقب البلاغات واختر قرارك."
const EXPIRED_FEEDBACK: String = "خلص الشفت. الأزرار تقفلت."
const GLOBAL_LOCK_SECONDS: float = 2.5
const MANUAL_OVERRIDE_MAX_USES: int = 2

const COOLDOWN_SECONDS: Array[float] = [
	5.5,
	6.5,
	7.5,
	9.0,
	12.0,
]

const BUTTON_LABELS: Array[String] = [
	"[1] برّد المبنى\nينزل الحرارة / يضغط الكهرباء",
	"[2] نفّس الضغط\nينزل الضغط / يرفع الحرارة شوي",
	"[3] خفّف الكهرباء\nينزل الحمل / يضعف التبريد",
	"[4] أعد التشغيل\nيفك قراءة خربانة أو زر عالق",
	"[5] تصرف يدوي\nحل قوي، مرتين فقط",
]

var facility_state: FacilityState
var buttons: Array[Button] = []
var override_remaining_label: Label
var feedback_label: Label
var cooldowns: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]
var manual_override_uses: int = MANUAL_OVERRIDE_MAX_USES
var global_lock_remaining: float = 0.0
var inputs_expired: bool = false
var jammed_actions: Array[bool] = [false, false, false, false, false]
var _has_external_resettable_faults: Callable
var _clear_external_resettable_faults: Callable
var _active_button_tweens: Array[Tween] = [null, null, null, null, null]


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
	jammed_actions = [false, false, false, false, false]
	_set_feedback(DEFAULT_FEEDBACK)
	_update_button_states()


func configure_reset_callbacks(has_faults: Callable, clear_faults: Callable) -> void:
	_has_external_resettable_faults = has_faults
	_clear_external_resettable_faults = clear_faults


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
		_play_button_rejection(action)
		action_rejected.emit(action, "expired")
		state_changed.emit()
		return true

	if global_lock_remaining > 0.0:
		_set_feedback("اصبر شوي. اللوحة ماسكة نفسها.")
		_update_button_states()
		_play_button_rejection(action)
		action_rejected.emit(action, "locked")
		state_changed.emit()
		return true

	if action == Action.OVERRIDE and manual_override_uses <= 0:
		_set_feedback("خلصت التصرفات اليدوية. عاد دبّرها.")
		_update_button_states()
		_play_button_rejection(action)
		action_rejected.emit(action, "depleted")
		state_changed.emit()
		return true

	if is_action_jammed(action):
		_set_feedback("الزر علق. واضح محد نظفه من 2012.")
		_update_button_states()
		_play_button_rejection(action)
		action_rejected.emit(action, "jammed")
		state_changed.emit()
		return true

	if cooldowns[action] > 0.0:
		_set_feedback("هالقرار يبرد. جرب شي ثاني.")
		_update_button_states()
		_play_button_rejection(action)
		action_rejected.emit(action, "cooldown")
		state_changed.emit()
		return true

	match action:
		Action.COOL:
			facility_state.apply_emergency_cooling()
			_start_cooldown(action)
			_set_feedback("شغلت تبريد طوارئ. الكهرباء بتزعل شوي.")
		Action.VENT:
			facility_state.apply_pressure_vent()
			_start_cooldown(action)
			_set_feedback("فتحت التنفيس. الضغط نزل، والحرارة بتتنفس عليك.")
		Action.REROUTE:
			facility_state.apply_power_reroute()
			_start_cooldown(action)
			_set_feedback("حوّلت الكهرباء. التبريد بيصير نفسية شوي.")
		Action.RESET:
			if not _has_any_resettable_fault():
				_set_feedback("ما فيه عطل ينفك. لا تضغط عالفاضي.")
				_update_button_states()
				action_rejected.emit(action, "no_fault")
				state_changed.emit()
				return true
			facility_state.perform_system_reset()
			clear_jammed_controls()
			_clear_external_faults()
			global_lock_remaining = GLOBAL_LOCK_SECONDS
			_start_cooldown(action)
			_set_feedback("سويت إعادة تشغيل. إذا اشتغل نقول الحمد لله.")
		Action.OVERRIDE:
			var target_name: String = facility_state.apply_manual_override()
			manual_override_uses -= 1
			_start_cooldown(action)
			_set_feedback("تدخلت يدويًا في %s. لا تعلم المدير." % target_name)

	_update_button_states()
	_play_button_acceptance(action)
	action_accepted.emit(action)
	state_changed.emit()
	return true


func _connect_buttons() -> void:
	for index: int in range(buttons.size()):
		if not buttons[index].pressed.is_connected(try_action.bind(index)):
			buttons[index].pressed.connect(try_action.bind(index))


func _start_cooldown(action: int) -> void:
	cooldowns[action] = COOLDOWN_SECONDS[action]


func set_jammed_action(action: int, jammed: bool = true) -> void:
	if action < 0 or action >= jammed_actions.size():
		push_error("Invalid jammed intervention action.")
		assert(false)
		return
	jammed_actions[action] = jammed
	_update_button_states()


func clear_jammed_action(action: int) -> void:
	set_jammed_action(action, false)


func clear_jammed_controls() -> void:
	for index: int in range(jammed_actions.size()):
		jammed_actions[index] = false
	_update_button_states()


func has_jammed_control() -> bool:
	for is_jammed: bool in jammed_actions:
		if is_jammed:
			return true
	return false


func is_action_jammed(action: int) -> bool:
	if action < 0 or action >= jammed_actions.size():
		return false
	return jammed_actions[action]


func has_manual_override_available() -> bool:
	return manual_override_uses > 0 and not inputs_expired and global_lock_remaining <= 0.0


func is_action_counter_unavailable(action: int) -> bool:
	if inputs_expired or global_lock_remaining > 0.0:
		return true
	if is_action_jammed(action):
		return true
	return cooldowns[action] > 0.0


func _update_button_states() -> void:
	override_remaining_label.text = "تصرف يدوي: %d باقي" % manual_override_uses
	for index: int in range(buttons.size()):
		var state_text: String = _state_text_for(index)
		buttons[index].text = "%s\n%s" % [BUTTON_LABELS[index], state_text]
		buttons[index].disabled = _is_button_disabled(index)


func _state_text_for(action: int) -> String:
	if inputs_expired:
		return "مقفل"
	if global_lock_remaining > 0.0:
		return "مقفل"
	if action == Action.OVERRIDE and manual_override_uses <= 0:
		return "خلص"
	if is_action_jammed(action):
		return "عالق"
	if cooldowns[action] > 0.0:
		return "%.1fs" % cooldowns[action]
	return "جاهز"


func _is_button_disabled(action: int) -> bool:
	if inputs_expired or global_lock_remaining > 0.0:
		return true
	if action == Action.OVERRIDE and manual_override_uses <= 0:
		return true
	if is_action_jammed(action):
		return true
	return cooldowns[action] > 0.0


func _set_feedback(message: String) -> void:
	feedback_label.text = message


func _has_any_resettable_fault() -> bool:
	if facility_state.has_active_resettable_fault() or has_jammed_control():
		return true
	if _has_external_resettable_faults.is_valid():
		return bool(_has_external_resettable_faults.call())
	return false


func _clear_external_faults() -> void:
	if _clear_external_resettable_faults.is_valid():
		_clear_external_resettable_faults.call()


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


func _play_button_acceptance(action: int) -> void:
	if action < 0 or action >= buttons.size():
		return
	var button: Button = buttons[action]
	if not is_instance_valid(button) or not button.is_inside_tree():
		return
	if button.size.x > 0.0 and button.size.y > 0.0:
		button.pivot_offset = button.size * 0.5
	var tween: Tween = _restart_button_tween(action, button)
	tween.tween_property(button, "scale", Vector2(0.92, 0.94), 0.07)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _play_button_rejection(action: int) -> void:
	if action < 0 or action >= buttons.size():
		return
	var button: Button = buttons[action]
	if not is_instance_valid(button) or not button.is_inside_tree():
		return
	if button.size.x > 0.0 and button.size.y > 0.0:
		button.pivot_offset = button.size * 0.5
	var tween: Tween = _restart_button_tween(action, button)
	tween.tween_property(button, "rotation", deg_to_rad(-2.6), 0.05)
	tween.tween_property(button, "rotation", deg_to_rad(2.6), 0.07)
	tween.tween_property(button, "rotation", deg_to_rad(-1.4), 0.06)
	tween.tween_property(button, "rotation", 0.0, 0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _restart_button_tween(action: int, button: Button) -> Tween:
	var previous: Tween = _active_button_tweens[action]
	if previous != null and previous.is_valid():
		previous.kill()
	button.scale = Vector2(1.0, 1.0)
	button.rotation = 0.0
	var tween: Tween = button.create_tween()
	_active_button_tweens[action] = tween
	return tween
