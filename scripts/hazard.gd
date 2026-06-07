class_name Hazard
extends Node2D

# A single visible, escalating problem in the building. Three readable types,
# each drawn distinctly with particles. It grows while ignored and is cleared by
# a hold-to-fix progress. One glance should tell the player "fire over there!".

signal fixed(hazard)

enum Type {
	LEAK,
	FIRE,
	SPARK,
}

enum State {
	ACTIVE,
	FIXED,
}

const START_SEVERITY: float = 0.35
const FIX_DECAY_WHEN_IDLE: float = 0.6  # progress slips back if you walk away mid-fix

var type: int = Type.LEAK
var severity: float = START_SEVERITY
var fix_progress: float = 0.0
var state: int = State.ACTIVE
var _time: float = 0.0
var _particles: GPUParticles2D


func setup(hazard_type: int) -> void:
	type = hazard_type
	severity = START_SEVERITY
	fix_progress = 0.0
	state = State.ACTIVE
	_time = randf() * 6.0
	z_index = 6
	_build_particles()
	queue_redraw()


func _process(delta: float) -> void:
	if state == State.FIXED:
		return
	_time += delta
	severity = clampf(severity + _growth_rate() * delta, 0.0, 1.0)
	queue_redraw()


# --- Public API used by the controller (called every frame) -----------------

func apply_fix(delta: float) -> void:
	if state == State.FIXED:
		return
	fix_progress += _fix_rate() * delta
	if fix_progress >= 1.0:
		_mark_fixed()


func decay_fix(delta: float) -> void:
	if state == State.FIXED:
		return
	fix_progress = maxf(fix_progress - FIX_DECAY_WHEN_IDLE * delta, 0.0)


func get_danger() -> float:
	if state == State.FIXED:
		return 0.0
	# Even a small hazard hurts a little; a big one hurts a lot.
	return _base_danger() * (0.4 + severity * 0.6)


func is_active() -> bool:
	return state == State.ACTIVE


func get_label() -> String:
	match type:
		Type.FIRE:
			return "حريق"
		Type.SPARK:
			return "ماس كهربائي"
		_:
			return "تسريب مياه"


func _mark_fixed() -> void:
	state = State.FIXED
	fix_progress = 1.0
	if is_instance_valid(_particles):
		_particles.emitting = false
	fixed.emit(self)
	queue_redraw()


# --- Per-type tuning --------------------------------------------------------

func _base_danger() -> float:
	match type:
		Type.FIRE:
			return 7.0
		Type.SPARK:
			return 6.0
		_:
			return 4.0


func _growth_rate() -> float:
	match type:
		Type.FIRE:
			return 0.16
		Type.SPARK:
			return 0.2
		_:
			return 0.1


func _fix_rate() -> float:
	match type:
		Type.FIRE:
			return 0.45
		Type.SPARK:
			return 0.7
		_:
			return 0.55


func _main_color() -> Color:
	match type:
		Type.FIRE:
			return Color(0.949020, 0.435294, 0.145098, 1.0)
		Type.SPARK:
			return Color(0.968627, 0.847059, 0.274510, 1.0)
		_:
			return Color(0.321569, 0.674510, 0.949020, 1.0)


# --- Drawing ----------------------------------------------------------------

func _draw() -> void:
	if state == State.FIXED:
		return
	var pulse: float = 0.5 + 0.5 * sin(_time * 5.0)
	var glow_radius: float = 24.0 + severity * 26.0
	var color: Color = _main_color()
	# Ground glow so it reads from across the room
	_draw_filled_circle(Vector2(0.0, 6.0), glow_radius, Color(color.r, color.g, color.b, 0.18 + pulse * 0.12))
	match type:
		Type.FIRE:
			_draw_fire()
		Type.SPARK:
			_draw_spark()
		_:
			_draw_leak()
	_draw_danger_marker(pulse)
	_draw_fix_ring()


func _draw_leak() -> void:
	var color: Color = _main_color()
	var spread: float = 18.0 + severity * 30.0
	# Puddle
	_draw_ellipse(Vector2(0.0, 14.0), Vector2(spread, spread * 0.42), Color(0.149020, 0.337255, 0.498039, 0.7))
	_draw_ellipse(Vector2(-spread * 0.2, 10.0), Vector2(spread * 0.55, spread * 0.24), color)
	_draw_ellipse(Vector2(-spread * 0.3, 8.0), Vector2(spread * 0.25, spread * 0.12), Color(0.78, 0.92, 0.97, 0.6))


func _draw_fire() -> void:
	var base: Vector2 = Vector2(0.0, 6.0)
	var height: float = 26.0 + severity * 34.0
	var width: float = 16.0 + severity * 16.0
	# Layered flames
	for layer: int in range(3):
		var t: float = float(layer) / 3.0
		var flicker: float = sin(_time * (9.0 + float(layer) * 3.0)) * (3.0 + float(layer) * 2.0)
		var col: Color = Color(0.95, 0.43, 0.14, 1.0).lerp(Color(0.98, 0.82, 0.25, 1.0), t)
		var tip: Vector2 = base + Vector2(flicker, -height * (1.0 - t * 0.35))
		var pts: PackedVector2Array = PackedVector2Array([
			base + Vector2(-width * (1.0 - t) * 0.5, 0.0),
			tip,
			base + Vector2(width * (1.0 - t) * 0.5, 0.0),
		])
		draw_colored_polygon(pts, col)


func _draw_spark() -> void:
	var color: Color = _main_color()
	var flash: bool = sin(_time * 30.0) > 0.3
	var bolts: int = 4 + int(severity * 4.0)
	for i: int in range(bolts):
		var a: float = (float(i) / float(bolts)) * TAU + _time * 4.0
		var length: float = 14.0 + severity * 18.0
		var mid: Vector2 = Vector2(cos(a), sin(a)) * length * 0.5 + Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0))
		var tip: Vector2 = Vector2(cos(a), sin(a)) * length
		draw_line(Vector2(0.0, 4.0), mid, color, 2.0, true)
		draw_line(mid, tip, color, 1.5, true)
	if flash:
		_draw_filled_circle(Vector2(0.0, 4.0), 8.0 + severity * 6.0, Color(1.0, 0.98, 0.7, 0.7))


func _draw_danger_marker(pulse: float) -> void:
	# A floating exclamation that grows louder with severity, for at-a-glance read.
	var marker_y: float = -40.0 - severity * 28.0
	var scale: float = 0.8 + severity * 0.6 + pulse * 0.1
	var color: Color = Color(0.95, 0.3, 0.22, 1.0) if severity > 0.6 else Color(0.95, 0.7, 0.2, 1.0)
	var center: Vector2 = Vector2(0.0, marker_y)
	# Rounded badge
	_draw_filled_circle(center, 11.0 * scale, color)
	_draw_filled_circle(center, 11.0 * scale, Color(color.r, color.g, color.b, 0.4))
	var font: Font = ThemeDB.fallback_font
	var fs: int = int(18.0 * scale)
	var glyph: String = "!"
	var ts: Vector2 = font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_CENTER, -1.0, fs)
	draw_string(font, center + Vector2(-ts.x * 0.5, fs * 0.35), glyph, HORIZONTAL_ALIGNMENT_CENTER, -1.0, fs, Color(1, 1, 1, 1))


func _draw_fix_ring() -> void:
	if fix_progress <= 0.01:
		return
	var center: Vector2 = Vector2(0.0, 6.0)
	var radius: float = 34.0
	draw_arc(center, radius, 0.0, TAU, 32, Color(0, 0, 0, 0.4), 5.0, true)
	draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * fix_progress, 32, Color(0.45, 0.95, 0.55, 0.95), 5.0, true)


func _draw_filled_circle(center: Vector2, radius: float, color: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(22):
		var a: float = (float(i) / 22.0) * TAU
		pts.append(center + Vector2(cos(a) * radius, sin(a) * radius))
	draw_colored_polygon(pts, color)


func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(22):
		var a: float = (float(i) / 22.0) * TAU
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_colored_polygon(pts, color)


# --- Particles --------------------------------------------------------------

func _build_particles() -> void:
	if is_instance_valid(_particles):
		_particles.queue_free()
	_particles = GPUParticles2D.new()
	_particles.texture = _make_soft_texture()
	_particles.amount = 16
	_particles.lifetime = 0.7
	_particles.local_coords = false
	var mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 6.0
	match type:
		Type.FIRE:
			mat.direction = Vector3(0.0, -1.0, 0.0)
			mat.spread = 22.0
			mat.gravity = Vector3(0.0, -120.0, 0.0)
			mat.initial_velocity_min = 30.0
			mat.initial_velocity_max = 70.0
			mat.color = Color(0.98, 0.62, 0.2, 0.85)
			_particles.position = Vector2(0.0, 0.0)
		Type.SPARK:
			mat.direction = Vector3(0.0, -1.0, 0.0)
			mat.spread = 180.0
			mat.gravity = Vector3(0.0, 240.0, 0.0)
			mat.initial_velocity_min = 60.0
			mat.initial_velocity_max = 140.0
			mat.color = Color(1.0, 0.95, 0.5, 0.9)
			_particles.lifetime = 0.4
			_particles.position = Vector2(0.0, 4.0)
		_:
			mat.direction = Vector3(0.0, -1.0, 0.0)
			mat.spread = 35.0
			mat.gravity = Vector3(0.0, 320.0, 0.0)
			mat.initial_velocity_min = 20.0
			mat.initial_velocity_max = 55.0
			mat.color = Color(0.4, 0.72, 0.95, 0.8)
			_particles.position = Vector2(0.0, 2.0)
	_particles.process_material = mat
	_particles.emitting = true
	add_child(_particles)


func _make_soft_texture() -> ImageTexture:
	var image: Image = Image.create(12, 12, false, Image.FORMAT_RGBA8)
	image.fill(Color(1, 1, 1, 0))
	for y: int in range(12):
		for x: int in range(12):
			var dx: float = float(x) - 5.5
			var dy: float = float(y) - 5.5
			var d: float = sqrt(dx * dx + dy * dy) / 5.5
			image.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - d * d, 0.0, 1.0)))
	return ImageTexture.create_from_image(image)
