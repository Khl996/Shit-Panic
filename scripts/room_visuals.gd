extends Node2D

const ROOM_WIDTH: float = 1280.0
const ROOM_HEIGHT: float = 720.0
const WALL_THICKNESS: float = 30.0
const FLOOR_BASE: Color = Color(0.227451, 0.156863, 0.0980392, 1.0)
const FLOOR_PLANK_LIGHT: Color = Color(0.290196, 0.196078, 0.121569, 1.0)
const FLOOR_PLANK_DARK: Color = Color(0.180392, 0.121569, 0.0784314, 1.0)
const PLANK_LINE: Color = Color(0.0784314, 0.0509804, 0.0313726, 0.85)
const GRAIN_LIGHT: Color = Color(0.345098, 0.235294, 0.156863, 0.42)
const GRAIN_DARK: Color = Color(0.0509804, 0.0313726, 0.0156863, 0.45)
const WALL_BASE: Color = Color(0.388235, 0.262745, 0.156863, 1.0)
const WALL_TRIM: Color = Color(0.580392, 0.419608, 0.243137, 1.0)
const WALL_SHADOW: Color = Color(0.0901961, 0.0588235, 0.0392157, 0.85)
const STAIN_COLOR: Color = Color(0.0823529, 0.0470588, 0.0235294, 0.4)
const PLANK_HEIGHT: float = 92.0
const GRAIN_SEED: int = 4477


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	_draw_floor()
	_draw_floor_stains()
	_draw_walls()


func _draw_floor() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(ROOM_WIDTH, ROOM_HEIGHT)), FLOOR_BASE, true)
	var plank_index: int = 0
	var y: float = WALL_THICKNESS
	while y < ROOM_HEIGHT - WALL_THICKNESS:
		var plank_color: Color = FLOOR_PLANK_LIGHT if plank_index % 2 == 0 else FLOOR_PLANK_DARK
		var plank_rect: Rect2 = Rect2(
			Vector2(WALL_THICKNESS, y),
			Vector2(ROOM_WIDTH - WALL_THICKNESS * 2.0, minf(PLANK_HEIGHT, ROOM_HEIGHT - WALL_THICKNESS - y))
		)
		draw_rect(plank_rect, plank_color, true)
		draw_line(
			Vector2(plank_rect.position.x, plank_rect.position.y),
			Vector2(plank_rect.position.x + plank_rect.size.x, plank_rect.position.y),
			PLANK_LINE,
			1.0,
			true
		)
		_draw_plank_grain(plank_rect, plank_index)
		plank_index += 1
		y += PLANK_HEIGHT


func _draw_plank_grain(plank_rect: Rect2, plank_index: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = GRAIN_SEED + plank_index
	var grain_count: int = 18
	for index: int in range(grain_count):
		var grain_y: float = plank_rect.position.y + rng.randf_range(4.0, plank_rect.size.y - 4.0)
		var grain_x_start: float = plank_rect.position.x + rng.randf_range(0.0, plank_rect.size.x * 0.3)
		var grain_x_end: float = plank_rect.position.x + rng.randf_range(plank_rect.size.x * 0.7, plank_rect.size.x)
		var sway: float = rng.randf_range(-3.0, 3.0)
		var color: Color = GRAIN_LIGHT if index % 2 == 0 else GRAIN_DARK
		var thickness: float = rng.randf_range(0.5, 1.3)
		draw_line(Vector2(grain_x_start, grain_y), Vector2((grain_x_start + grain_x_end) * 0.5, grain_y + sway), color, thickness, true)
		draw_line(Vector2((grain_x_start + grain_x_end) * 0.5, grain_y + sway), Vector2(grain_x_end, grain_y + sway * 0.4), color, thickness, true)


func _draw_floor_stains() -> void:
	var stains: Array[Vector3] = [
		Vector3(320.0, 280.0, 42.0),
		Vector3(880.0, 450.0, 36.0),
		Vector3(640.0, 600.0, 28.0),
	]
	for stain: Vector3 in stains:
		var center: Vector2 = Vector2(stain.x, stain.y)
		var radius: float = stain.z
		draw_circle(center, radius, STAIN_COLOR)
		draw_arc(center, radius * 0.92, 0.0, TAU, 36, Color(STAIN_COLOR.r, STAIN_COLOR.g, STAIN_COLOR.b, 0.55), 1.5, true)
		draw_arc(center, radius * 0.55, 0.0, TAU, 24, Color(STAIN_COLOR.r, STAIN_COLOR.g, STAIN_COLOR.b, 0.5), 1.0, true)


func _draw_walls() -> void:
	# Top
	draw_rect(Rect2(Vector2(0.0, 0.0), Vector2(ROOM_WIDTH, WALL_THICKNESS)), WALL_BASE, true)
	# Bottom
	draw_rect(Rect2(Vector2(0.0, ROOM_HEIGHT - WALL_THICKNESS), Vector2(ROOM_WIDTH, WALL_THICKNESS)), WALL_BASE, true)
	# Left
	draw_rect(Rect2(Vector2(0.0, 0.0), Vector2(WALL_THICKNESS, ROOM_HEIGHT)), WALL_BASE, true)
	# Right
	draw_rect(Rect2(Vector2(ROOM_WIDTH - WALL_THICKNESS, 0.0), Vector2(WALL_THICKNESS, ROOM_HEIGHT)), WALL_BASE, true)
	# Inner wall trim line
	draw_line(Vector2(WALL_THICKNESS, WALL_THICKNESS), Vector2(ROOM_WIDTH - WALL_THICKNESS, WALL_THICKNESS), WALL_TRIM, 2.0, true)
	draw_line(Vector2(WALL_THICKNESS, ROOM_HEIGHT - WALL_THICKNESS), Vector2(ROOM_WIDTH - WALL_THICKNESS, ROOM_HEIGHT - WALL_THICKNESS), WALL_TRIM, 2.0, true)
	draw_line(Vector2(WALL_THICKNESS, WALL_THICKNESS), Vector2(WALL_THICKNESS, ROOM_HEIGHT - WALL_THICKNESS), WALL_TRIM, 2.0, true)
	draw_line(Vector2(ROOM_WIDTH - WALL_THICKNESS, WALL_THICKNESS), Vector2(ROOM_WIDTH - WALL_THICKNESS, ROOM_HEIGHT - WALL_THICKNESS), WALL_TRIM, 2.0, true)
	# Soft inner shadow
	var shadow_size: float = 6.0
	draw_rect(Rect2(Vector2(WALL_THICKNESS, WALL_THICKNESS), Vector2(ROOM_WIDTH - WALL_THICKNESS * 2.0, shadow_size)), WALL_SHADOW, true)
	draw_rect(Rect2(Vector2(WALL_THICKNESS, WALL_THICKNESS), Vector2(shadow_size, ROOM_HEIGHT - WALL_THICKNESS * 2.0)), WALL_SHADOW, true)
	draw_rect(Rect2(Vector2(ROOM_WIDTH - WALL_THICKNESS - shadow_size, WALL_THICKNESS), Vector2(shadow_size, ROOM_HEIGHT - WALL_THICKNESS * 2.0)), WALL_SHADOW, true)
	draw_rect(Rect2(Vector2(WALL_THICKNESS, ROOM_HEIGHT - WALL_THICKNESS - shadow_size), Vector2(ROOM_WIDTH - WALL_THICKNESS * 2.0, shadow_size)), WALL_SHADOW, true)
