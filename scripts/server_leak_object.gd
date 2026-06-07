extends Node2D

enum LeakState {
	DRY,
	LEAKING,
	TAPE_PATCHED,
	BUCKET_PLACED,
	TAPE_FAILED,
}

const RACK_WIDTH: float = 84.0
const RACK_HEIGHT: float = 200.0
const RACK_SPACING: float = 120.0
const RACK_TOP: float = -104.0
const FRAME_DARK: Color = Color(0.082353, 0.090196, 0.105882, 1.0)
const FRAME_METAL: Color = Color(0.196078, 0.215686, 0.243137, 1.0)
const FRAME_EDGE: Color = Color(0.301961, 0.329412, 0.376471, 1.0)
const UNIT_BODY: Color = Color(0.043137, 0.050980, 0.062745, 1.0)
const UNIT_FACE: Color = Color(0.105882, 0.117647, 0.137255, 1.0)
const VENT_COLOR: Color = Color(0.027451, 0.031373, 0.039216, 1.0)
const SERVER_LIGHT: Color = Color(0.411765, 0.835294, 0.733333, 1.0)
const SCREEN_GLOW: Color = Color(0.345098, 0.737255, 0.521569, 1.0)
const WARNING_COLOR: Color = Color(0.949020, 0.694118, 0.231373, 1.0)
const DANGER_COLOR: Color = Color(0.870588, 0.286275, 0.247059, 1.0)
const WATER_COLOR: Color = Color(0.321569, 0.674510, 0.831373, 0.82)
const WATER_DARK: Color = Color(0.125490, 0.309804, 0.447059, 0.55)
const TAPE_COLOR: Color = Color(0.937255, 0.870588, 0.682353, 1.0)
const BUCKET_COLOR: Color = Color(0.611765, 0.611765, 0.643137, 1.0)
const PAPER_COLOR: Color = Color(0.937255, 0.882353, 0.733333, 1.0)
const TEXT_COLOR: Color = Color(0.180392, 0.117647, 0.0784314, 1.0)
const AC_BODY: Color = Color(0.815686, 0.823529, 0.831373, 1.0)
const AC_SHADE: Color = Color(0.560784, 0.572549, 0.592157, 1.0)
const AC_DARK: Color = Color(0.349020, 0.356863, 0.372549, 1.0)
const PUDDLE_CENTER_OFFSET: Vector2 = Vector2(0.0, 132.0)
const PUDDLE_GROWTH_PER_SECOND: float = 16.0
const PUDDLE_SHRINK_PER_SECOND: float = 38.0
const PUDDLE_MAX_RADIUS: float = 82.0
const PUDDLE_ASPECT: float = 0.42

var state: int = LeakState.DRY
var _time: float = 0.0
var _label: String = "غرفة السيرفر"
var _drip_particles: GPUParticles2D
var _splash_particles: GPUParticles2D
var _puddle_radius: float = 0.0


func _ready() -> void:
	z_index = 4
	set_process(true)
	_setup_particles()
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	_update_puddle(delta)
	# Racks animate continuously (fans, LED blinks), so always redraw.
	queue_redraw()


func _update_puddle(delta: float) -> void:
	if state == LeakState.LEAKING or state == LeakState.TAPE_FAILED:
		_puddle_radius = minf(_puddle_radius + PUDDLE_GROWTH_PER_SECOND * delta, PUDDLE_MAX_RADIUS)
	else:
		_puddle_radius = maxf(_puddle_radius - PUDDLE_SHRINK_PER_SECOND * delta, 0.0)


func get_puddle_world_center() -> Vector2:
	return global_position + PUDDLE_CENTER_OFFSET


func get_puddle_radius() -> float:
	return _puddle_radius


func is_in_puddle(world_pos: Vector2) -> bool:
	if _puddle_radius < 12.0:
		return false
	var center: Vector2 = get_puddle_world_center()
	var dx: float = world_pos.x - center.x
	var dy: float = (world_pos.y - center.y) / PUDDLE_ASPECT
	return sqrt(dx * dx + dy * dy) <= _puddle_radius


func set_state(new_state: int) -> void:
	if state == new_state:
		return
	state = new_state
	_update_particle_emission()
	queue_redraw()


func set_label(text: String) -> void:
	_label = text
	queue_redraw()


func _draw() -> void:
	_draw_growing_puddle()
	# Side racks (healthy), then the centre rack (the damaged one under the AC).
	_draw_rack(-RACK_SPACING, false)
	_draw_rack(RACK_SPACING, false)
	_draw_rack(0.0, true)
	_draw_ac_unit()
	_draw_state_overlay()
	_draw_label()


func _draw_rack(center_x: float, is_damaged: bool) -> void:
	var origin: Vector2 = Vector2(center_x - RACK_WIDTH * 0.5, RACK_TOP)
	# Cast shadow
	draw_rect(Rect2(origin + Vector2(6.0, 10.0), Vector2(RACK_WIDTH, RACK_HEIGHT)), Color(0.0, 0.0, 0.0, 0.5), true)
	# Outer frame
	draw_rect(Rect2(origin, Vector2(RACK_WIDTH, RACK_HEIGHT)), FRAME_DARK, true)
	draw_rect(Rect2(origin, Vector2(RACK_WIDTH, RACK_HEIGHT)), FRAME_METAL, false, 2.0)
	# Side rails
	draw_rect(Rect2(origin, Vector2(7.0, RACK_HEIGHT)), FRAME_METAL, true)
	draw_rect(Rect2(origin + Vector2(RACK_WIDTH - 7.0, 0.0), Vector2(7.0, RACK_HEIGHT)), FRAME_METAL, true)
	draw_line(origin + Vector2(2.0, 0.0), origin + Vector2(2.0, RACK_HEIGHT), FRAME_EDGE, 1.0, true)
	# Mounted units
	var unit_count: int = 7
	var inner_left: float = origin.x + 9.0
	var inner_width: float = RACK_WIDTH - 18.0
	var unit_gap: float = 3.0
	var unit_height: float = (RACK_HEIGHT - 20.0 - unit_gap * float(unit_count)) / float(unit_count)
	for unit_index: int in range(unit_count):
		var unit_y: float = origin.y + 10.0 + float(unit_index) * (unit_height + unit_gap)
		_draw_rack_unit(Vector2(inner_left, unit_y), Vector2(inner_width, unit_height), unit_index, is_damaged)
	# Fan grille at the bottom
	var fan_center: Vector2 = Vector2(center_x, origin.y + RACK_HEIGHT - 6.0)
	var spin: float = _time * (5.0 if not is_damaged else 1.5)
	for blade: int in range(3):
		var a: float = spin + float(blade) * (TAU / 3.0)
		draw_line(fan_center, fan_center + Vector2(cos(a), sin(a)) * 5.0, FRAME_EDGE, 1.5, true)
	draw_arc(fan_center, 6.0, 0.0, TAU, 16, FRAME_METAL, 1.2, true)


func _draw_rack_unit(unit_pos: Vector2, unit_size: Vector2, unit_index: int, is_damaged: bool) -> void:
	draw_rect(Rect2(unit_pos, unit_size), UNIT_BODY, true)
	draw_rect(Rect2(unit_pos, unit_size), UNIT_FACE, false, 1.0)
	# Some units carry a small LCD screen, others are vented blanks.
	var has_screen: bool = (unit_index % 3) == 1
	if has_screen:
		var screen_rect: Rect2 = Rect2(unit_pos + Vector2(4.0, unit_size.y * 0.25), Vector2(unit_size.x * 0.4, unit_size.y * 0.5))
		var glow: float = 0.6 + 0.4 * sin(_time * 3.0 + float(unit_index))
		var screen_color: Color = SCREEN_GLOW
		if is_damaged and (state == LeakState.LEAKING or state == LeakState.TAPE_FAILED):
			screen_color = DANGER_COLOR if state == LeakState.TAPE_FAILED else WARNING_COLOR
		draw_rect(screen_rect, Color(screen_color.r, screen_color.g, screen_color.b, 0.30 + glow * 0.4), true)
		# A couple of text-line bars on the screen
		draw_line(screen_rect.position + Vector2(2.0, 3.0), screen_rect.position + Vector2(screen_rect.size.x - 3.0, 3.0), Color(screen_color.r, screen_color.g, screen_color.b, 0.8), 1.0, true)
		draw_line(screen_rect.position + Vector2(2.0, 6.0), screen_rect.position + Vector2(screen_rect.size.x - 6.0, 6.0), Color(screen_color.r, screen_color.g, screen_color.b, 0.6), 1.0, true)
	else:
		# Vent slits
		for slit: int in range(3):
			var sy: float = unit_pos.y + 3.0 + float(slit) * (unit_size.y - 6.0) / 2.0
			draw_line(Vector2(unit_pos.x + 4.0, sy), Vector2(unit_pos.x + unit_size.x * 0.55, sy), VENT_COLOR, 1.5, true)
	# Status LED on the right of every unit
	var blink: float = (sin(_time * 4.0 + float(unit_index) * 1.3) + 1.0) * 0.5
	var led: Color = SERVER_LIGHT
	if is_damaged and state == LeakState.LEAKING:
		led = SERVER_LIGHT.lerp(WARNING_COLOR, blink)
	elif is_damaged and state == LeakState.TAPE_FAILED:
		led = DANGER_COLOR
	else:
		led = SERVER_LIGHT.lerp(Color(0.2, 0.3, 0.3, 1.0), 1.0 - blink)
	draw_circle(unit_pos + Vector2(unit_size.x - 6.0, unit_size.y * 0.5), 2.4, led)


func _draw_ac_unit() -> void:
	# Wall AC box mounted above the centre (damaged) rack.
	var unit_rect: Rect2 = Rect2(Vector2(-70.0, RACK_TOP - 44.0), Vector2(140.0, 36.0))
	draw_rect(Rect2(unit_rect.position + Vector2(3.0, 5.0), unit_rect.size), Color(0.0, 0.0, 0.0, 0.4), true)
	draw_rect(unit_rect, AC_BODY, true)
	draw_rect(Rect2(unit_rect.position, Vector2(unit_rect.size.x, 6.0)), AC_SHADE, true)
	draw_rect(unit_rect, AC_DARK, false, 2.0)
	# Louvers
	for index: int in range(6):
		var x: float = unit_rect.position.x + 14.0 + float(index) * 20.0
		draw_line(Vector2(x, unit_rect.position.y + 10.0), Vector2(x + 10.0, unit_rect.position.y + 26.0), AC_DARK, 2.0, true)
	# A wet stain seam under the AC when leaking
	if state == LeakState.LEAKING or state == LeakState.TAPE_FAILED:
		draw_rect(Rect2(Vector2(-30.0, unit_rect.position.y + unit_rect.size.y - 2.0), Vector2(60.0, 4.0)), Color(WATER_COLOR.r, WATER_COLOR.g, WATER_COLOR.b, 0.6), true)


func _draw_growing_puddle() -> void:
	if _puddle_radius < 1.0:
		return
	var center: Vector2 = PUDDLE_CENTER_OFFSET
	var radii: Vector2 = Vector2(_puddle_radius, _puddle_radius * PUDDLE_ASPECT)
	_draw_ellipse(center + Vector2(3.0, 4.0), radii * 1.02, Color(0.0, 0.0, 0.0, 0.30))
	_draw_ellipse(center, radii, WATER_DARK)
	_draw_ellipse(center + Vector2(-_puddle_radius * 0.18, -_puddle_radius * 0.07), radii * 0.55, WATER_COLOR)
	_draw_ellipse(center + Vector2(-_puddle_radius * 0.3, -_puddle_radius * 0.12), radii * 0.28, Color(0.823529, 0.929412, 0.952941, 0.55))


func _draw_state_overlay() -> void:
	match state:
		LeakState.LEAKING:
			_draw_warning_burst("مويه على السيرفر!")
		LeakState.TAPE_PATCHED:
			_draw_tape_patch(false)
		LeakState.BUCKET_PLACED:
			_draw_bucket()
		LeakState.TAPE_FAILED:
			_draw_tape_patch(true)
			_draw_warning_burst("الشطرطون خان!")


func _draw_tape_patch(failed: bool) -> void:
	var center: Vector2 = Vector2(0.0, RACK_TOP - 6.0)
	var angle: float = -0.12 if not failed else 0.22
	var transform: Transform2D = Transform2D(angle, center)
	draw_set_transform_matrix(transform)
	var rect: Rect2 = Rect2(Vector2(-52.0, -9.0), Vector2(104.0, 18.0))
	draw_rect(rect, TAPE_COLOR, true)
	draw_rect(rect, Color(0.549020, 0.466667, 0.270588, 1.0), false, 1.6)
	if failed:
		draw_line(Vector2(-34.0, -9.0), Vector2(-16.0, 9.0), DANGER_COLOR, 3.0, true)
		draw_line(Vector2(20.0, -9.0), Vector2(36.0, 9.0), DANGER_COLOR, 3.0, true)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_bucket() -> void:
	var center: Vector2 = PUDDLE_CENTER_OFFSET + Vector2(0.0, -6.0)
	var top_left: Vector2 = center + Vector2(-24.0, -18.0)
	var top_right: Vector2 = center + Vector2(24.0, -18.0)
	var bottom_left: Vector2 = center + Vector2(-16.0, 18.0)
	var bottom_right: Vector2 = center + Vector2(16.0, 18.0)
	draw_colored_polygon(PackedVector2Array([top_left + Vector2(3, 4), top_right + Vector2(3, 4), bottom_right + Vector2(3, 4), bottom_left + Vector2(3, 4)]), Color(0, 0, 0, 0.4))
	draw_colored_polygon(PackedVector2Array([top_left, top_right, bottom_right, bottom_left]), BUCKET_COLOR)
	draw_line(top_left, top_right, Color(0.388235, 0.388235, 0.423529, 1), 3.0, true)
	draw_line(bottom_left, bottom_right, Color(0.388235, 0.388235, 0.423529, 1), 2.0, true)
	draw_arc(center + Vector2(0.0, -18.0), 19.0, PI * 1.05, PI * 1.95, 16, Color(0.388235, 0.388235, 0.423529, 1), 1.8, true)


func _draw_warning_burst(text: String) -> void:
	var pulse: float = (sin(_time * 9.0) + 1.0) * 0.5
	var rect_size: Vector2 = Vector2(180.0 + pulse * 8.0, 32.0 + pulse * 4.0)
	var rect: Rect2 = Rect2(Vector2(-rect_size.x * 0.5, RACK_TOP - 74.0), rect_size)
	draw_rect(rect, WARNING_COLOR.lerp(DANGER_COLOR, pulse), true)
	draw_rect(rect, Color(0.180392, 0.117647, 0.078431, 1.0), false, 2.0)
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 15
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size)
	draw_string(font, rect.position + Vector2((rect.size.x - text_size.x) * 0.5, 21.0), text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size, TEXT_COLOR)


func _draw_label() -> void:
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 13
	var text_size: Vector2 = font.get_string_size(_label, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size)
	var rect_size: Vector2 = Vector2(text_size.x + 22.0, 24.0)
	var rect: Rect2 = Rect2(Vector2(-rect_size.x * 0.5, RACK_TOP + RACK_HEIGHT + 14.0), rect_size)
	draw_rect(Rect2(rect.position + Vector2(2.0, 2.0), rect.size), Color(0, 0, 0, 0.35), true)
	draw_rect(rect, PAPER_COLOR, true)
	draw_rect(rect, TEXT_COLOR, false, 1.3)
	draw_string(font, rect.position + Vector2((rect.size.x - text_size.x) * 0.5, 17.0), _label, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size, TEXT_COLOR)


func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for index: int in range(28):
		var angle: float = (float(index) / 28.0) * TAU
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)


func _setup_particles() -> void:
	var drip_texture: ImageTexture = _make_drip_texture()
	_drip_particles = GPUParticles2D.new()
	_drip_particles.position = Vector2(0.0, RACK_TOP - 6.0)
	_drip_particles.amount = 14
	_drip_particles.lifetime = 0.85
	_drip_particles.explosiveness = 0.0
	_drip_particles.emitting = false
	_drip_particles.local_coords = false
	_drip_particles.texture = drip_texture
	var drip_material: ParticleProcessMaterial = ParticleProcessMaterial.new()
	drip_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	drip_material.emission_box_extents = Vector3(26.0, 1.0, 0.0)
	drip_material.direction = Vector3(0.0, 1.0, 0.0)
	drip_material.spread = 4.0
	drip_material.gravity = Vector3(0.0, 620.0, 0.0)
	drip_material.initial_velocity_min = 18.0
	drip_material.initial_velocity_max = 42.0
	drip_material.scale_min = 0.55
	drip_material.scale_max = 1.05
	drip_material.color = Color(0.321569, 0.674510, 0.831373, 0.92)
	_drip_particles.process_material = drip_material
	add_child(_drip_particles)

	_splash_particles = GPUParticles2D.new()
	_splash_particles.position = PUDDLE_CENTER_OFFSET
	_splash_particles.amount = 18
	_splash_particles.lifetime = 0.4
	_splash_particles.explosiveness = 0.0
	_splash_particles.emitting = false
	_splash_particles.local_coords = false
	_splash_particles.texture = drip_texture
	var splash_material: ParticleProcessMaterial = ParticleProcessMaterial.new()
	splash_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	splash_material.direction = Vector3(0.0, -1.0, 0.0)
	splash_material.spread = 80.0
	splash_material.gravity = Vector3(0.0, 480.0, 0.0)
	splash_material.initial_velocity_min = 38.0
	splash_material.initial_velocity_max = 95.0
	splash_material.scale_min = 0.35
	splash_material.scale_max = 0.75
	splash_material.color = Color(0.498039, 0.811765, 0.894118, 0.85)
	_splash_particles.process_material = splash_material
	add_child(_splash_particles)


func _update_particle_emission() -> void:
	var should_emit: bool = state == LeakState.LEAKING or state == LeakState.TAPE_FAILED
	if is_instance_valid(_drip_particles):
		_drip_particles.emitting = should_emit
	if is_instance_valid(_splash_particles):
		_splash_particles.emitting = should_emit


func _make_drip_texture() -> ImageTexture:
	var image: Image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 1.0, 1.0, 0.0))
	for y: int in range(16):
		for x: int in range(16):
			var dx: float = float(x) - 7.5
			var dy: float = float(y) - 7.5
			var distance: float = sqrt(dx * dx + dy * dy) / 7.5
			var alpha: float = clampf(1.0 - distance * distance, 0.0, 1.0)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(image)
