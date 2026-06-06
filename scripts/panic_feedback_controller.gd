class_name PanicFeedbackController
extends RefCounted

const SHAKE_START_PANIC: float = 0.68
const SHAKE_MAX_PIXELS: float = 5.0
const FLASH_MAX_ALPHA: float = 0.16
const TERMINAL_TINT_MAX_ALPHA: float = 0.08
const SCANLINE_COUNT: int = 40

var _root: Control
var _console: Control
var _base_console_position: Vector2 = Vector2.ZERO
var _overlay: Control
var _danger_flash: ColorRect
var _terminal_tint: ColorRect
var _scanlines: Array[ColorRect] = []
var _time: float = 0.0


func configure(root: Control, console: Control) -> void:
	_root = root
	_console = console
	_base_console_position = _console.position
	_overlay = Control.new()
	_overlay.name = "PanicFeedbackOverlay"
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_overlay)

	_terminal_tint = ColorRect.new()
	_terminal_tint.name = "TerminalTint"
	_terminal_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	_terminal_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_terminal_tint.color = Color(0.0, 0.24, 0.20, 0.03)
	_overlay.add_child(_terminal_tint)

	for index: int in range(SCANLINE_COUNT):
		var line: ColorRect = ColorRect.new()
		line.name = "Scanline%02d" % index
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.color = Color(0.0, 0.0, 0.0, 0.05)
		_overlay.add_child(line)
		_scanlines.append(line)

	_danger_flash = ColorRect.new()
	_danger_flash.name = "DangerFlash"
	_danger_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_danger_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_danger_flash.color = Color(0.8, 0.08, 0.04, 0.0)
	_overlay.add_child(_danger_flash)
	reset()


func reset() -> void:
	_time = 0.0
	if is_instance_valid(_console):
		_console.position = _base_console_position
	if is_instance_valid(_danger_flash):
		_danger_flash.color = Color(0.8, 0.08, 0.04, 0.0)
	if is_instance_valid(_terminal_tint):
		_terminal_tint.color = Color(0.0, 0.24, 0.20, 0.03)
	_update_scanline_layout()


func advance(delta_seconds: float, panic_level: float, integrity_draining: bool, critical_count: int) -> void:
	if not is_instance_valid(_root) or not is_instance_valid(_console):
		return
	_time += maxf(delta_seconds, 0.0)
	_update_scanline_layout()
	_update_shake(panic_level)
	_update_flash(panic_level, integrity_draining, critical_count)


func _update_shake(panic_level: float) -> void:
	var shake_amount: float = clampf((panic_level - SHAKE_START_PANIC) / (1.0 - SHAKE_START_PANIC), 0.0, 1.0)
	if shake_amount <= 0.0:
		_console.position = _base_console_position
		return
	var distance: float = shake_amount * SHAKE_MAX_PIXELS
	_console.position = _base_console_position + Vector2(
		sin(_time * 42.0) * distance,
		cos(_time * 37.0) * distance * 0.65
	)


func _update_flash(panic_level: float, integrity_draining: bool, critical_count: int) -> void:
	var pulse: float = (sin(_time * 8.0) + 1.0) * 0.5
	var flash_alpha: float = 0.0
	if integrity_draining:
		flash_alpha = FLASH_MAX_ALPHA * (0.35 + (panic_level * 0.65)) * pulse
	if critical_count > 0:
		flash_alpha = maxf(flash_alpha, 0.05 + (0.03 * float(critical_count)) * pulse)
	_danger_flash.color = Color(0.8, 0.08, 0.04, clampf(flash_alpha, 0.0, FLASH_MAX_ALPHA))

	var tint_alpha: float = 0.03 + (panic_level * TERMINAL_TINT_MAX_ALPHA)
	_terminal_tint.color = Color(0.0, 0.24, 0.20, clampf(tint_alpha, 0.03, TERMINAL_TINT_MAX_ALPHA))


func _update_scanline_layout() -> void:
	if not is_instance_valid(_root):
		return
	var width: float = maxf(_root.size.x, 1280.0)
	var height: float = maxf(_root.size.y, 720.0)
	var step: float = height / float(SCANLINE_COUNT)
	for index: int in range(_scanlines.size()):
		var line: ColorRect = _scanlines[index]
		line.position = Vector2(0.0, floorf(float(index) * step))
		line.size = Vector2(width, 1.0)
