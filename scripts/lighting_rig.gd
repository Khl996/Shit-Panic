extends Node2D

# Builds the 2D lighting for the room: a cool night CanvasModulate plus a set of
# PointLight2D fixtures. Ceiling fluorescents flicker subtly. All light textures
# are generated procedurally (radial gradient) so no external assets are used.

const NIGHT_TINT: Color = Color(0.52, 0.54, 0.66, 1.0)
const FLUORESCENT_COLOR: Color = Color(0.74, 0.82, 1.0, 1.0)
const DESK_LAMP_COLOR: Color = Color(1.0, 0.81, 0.5, 1.0)
const SERVER_GLOW_COLOR: Color = Color(0.42, 0.78, 0.96, 1.0)
const DOOR_RED_COLOR: Color = Color(0.95, 0.32, 0.27, 1.0)
const RACK_GLOW_COLOR: Color = Color(0.5, 0.85, 0.78, 1.0)

var _light_texture: Texture2D
var _flicker_lights: Array[PointLight2D] = []
var _flicker_base_energy: Array[float] = []
var _flicker_phase: Array[float] = []
var _time: float = 0.0


func _ready() -> void:
	_light_texture = _make_radial_texture()
	var modulate_node: CanvasModulate = CanvasModulate.new()
	modulate_node.color = NIGHT_TINT
	add_child(modulate_node)

	# Ceiling fluorescents (flicker)
	_add_light(Vector2(300.0, 130.0), FLUORESCENT_COLOR, 0.85, 5.5, true)
	_add_light(Vector2(620.0, 130.0), FLUORESCENT_COLOR, 0.85, 5.5, true)
	_add_light(Vector2(980.0, 150.0), FLUORESCENT_COLOR, 0.7, 5.0, true)
	# Warm desk lamp over the console
	_add_light(Vector2(640.0, 430.0), DESK_LAMP_COLOR, 1.0, 3.4, false)
	# Cold server-room ambience
	_add_light(Vector2(1050.0, 380.0), SERVER_GLOW_COLOR, 0.75, 4.2, false)
	# Tool rack pool of light
	_add_light(Vector2(150.0, 360.0), FLUORESCENT_COLOR, 0.55, 3.0, false)
	# Dim red over the manager door
	_add_light(Vector2(1215.0, 300.0), DOOR_RED_COLOR, 0.55, 2.4, false)

	set_process(true)


func _process(delta: float) -> void:
	_time += delta
	for index: int in range(_flicker_lights.size()):
		var light: PointLight2D = _flicker_lights[index]
		if not is_instance_valid(light):
			continue
		var base: float = _flicker_base_energy[index]
		var phase: float = _flicker_phase[index]
		# Mostly steady with occasional dips, like a tired fluorescent tube.
		var slow: float = sin(_time * 2.3 + phase) * 0.04
		var buzz: float = sin(_time * 47.0 + phase) * 0.02
		var dip: float = 0.0
		var flicker_window: float = fmod(_time * 0.37 + phase, 6.0)
		if flicker_window < 0.18:
			dip = -0.28 * (1.0 - flicker_window / 0.18)
		light.energy = maxf(base + slow + buzz + dip, 0.1)


func _add_light(light_position: Vector2, color: Color, energy: float, texture_scale: float, flicker: bool) -> void:
	var light: PointLight2D = PointLight2D.new()
	light.texture = _light_texture
	light.position = light_position
	light.color = color
	light.energy = energy
	light.texture_scale = texture_scale
	light.blend_mode = Light2D.BLEND_MODE_ADD
	add_child(light)
	if flicker:
		_flicker_lights.append(light)
		_flicker_base_energy.append(energy)
		_flicker_phase.append(float(_flicker_lights.size()) * 1.7)


func _make_radial_texture() -> Texture2D:
	# Soft white-to-transparent radial falloff for the light cookies.
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0, 0.5),
		Color(1.0, 1.0, 1.0, 0.0),
	])
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 256
	texture.height = 256
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture
