class_name PlayerCharacter
extends CharacterBody2D

enum CarryState {
	NONE,
	DUCT_TAPE,
	BUCKET,
}

const WALK_SPEED: float = 220.0
const ACCEL: float = 1800.0
const DECEL: float = 1400.0
const SLIP_THRESHOLD: float = 180.0
const SLIP_DURATION: float = 0.45
const BODY_COLOR: Color = Color(0.290196, 0.18, 0.0941176, 1.0)
const SHIRT_COLOR: Color = Color(0.611765, 0.443137, 0.231373, 1.0)
const HEAD_COLOR: Color = Color(0.952941, 0.823529, 0.643137, 1.0)
const HEAD_OUTLINE: Color = Color(0.180392, 0.117647, 0.0784314, 1.0)
const HAIR_COLOR: Color = Color(0.117647, 0.0823529, 0.0509804, 1.0)
const SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.38)
const TAPE_COLOR: Color = Color(0.937255, 0.870588, 0.682353, 1.0)
const TAPE_STRIPE: Color = Color(0.717647, 0.623529, 0.392157, 1.0)
const BUCKET_COLOR: Color = Color(0.611765, 0.611765, 0.643137, 1.0)
const BUCKET_RIM: Color = Color(0.388235, 0.388235, 0.423529, 1.0)
const HEAD_RADIUS: float = 14.0
const BODY_RADIUS: float = 18.0
const ARM_LENGTH: float = 16.0

var carry_state: int = CarryState.NONE
var _facing: Vector2 = Vector2.DOWN
var _walk_cycle: float = 0.0
var _slip_timer: float = 0.0
var _slip_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	z_index = 10


func _physics_process(delta: float) -> void:
	if _slip_timer > 0.0:
		_advance_slip(delta)
	else:
		_advance_walking(delta)
	move_and_slide()
	queue_redraw()


func _advance_walking(delta: float) -> void:
	var input_vector: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_vector.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_vector.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_vector.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_vector.x += 1.0

	if input_vector.length_squared() > 0.01:
		input_vector = input_vector.normalized()
		_facing = input_vector
		velocity = velocity.move_toward(input_vector * WALK_SPEED, ACCEL * delta)
		_walk_cycle += delta * velocity.length() * 0.045
	else:
		var previous_speed: float = velocity.length()
		velocity = velocity.move_toward(Vector2.ZERO, DECEL * delta)
		if previous_speed > SLIP_THRESHOLD and velocity.length() < SLIP_THRESHOLD * 0.7:
			_trigger_slip(previous_speed)


func _advance_slip(delta: float) -> void:
	_slip_timer = maxf(_slip_timer - delta, 0.0)
	velocity = velocity.move_toward(Vector2.ZERO, DECEL * 2.0 * delta)
	var wobble: float = sin(_slip_timer * 38.0) * 8.0
	_slip_offset = _facing.orthogonal() * wobble


func _trigger_slip(speed: float) -> void:
	_slip_timer = SLIP_DURATION
	_slip_offset = Vector2.ZERO
	velocity = _facing * speed * 0.55


func is_walking() -> bool:
	return velocity.length() > 12.0 and _slip_timer <= 0.0


func is_slipping() -> bool:
	return _slip_timer > 0.0


func reset_pose() -> void:
	_walk_cycle = 0.0
	_slip_timer = 0.0
	_slip_offset = Vector2.ZERO
	velocity = Vector2.ZERO


func set_carry_state(new_state: int) -> void:
	carry_state = new_state
	queue_redraw()


func _draw() -> void:
	var shadow_center: Vector2 = Vector2(2.0, 14.0)
	draw_circle(shadow_center, BODY_RADIUS * 0.95, SHADOW_COLOR)
	var bob: float = sin(_walk_cycle * TAU) * (3.0 if is_walking() else 0.0)
	var draw_offset: Vector2 = Vector2(0.0, bob) + _slip_offset
	_draw_body(draw_offset)
	_draw_arms(draw_offset)
	_draw_head(draw_offset)
	if is_slipping():
		_draw_slip_marks()


func _draw_body(draw_offset: Vector2) -> void:
	var body_center: Vector2 = draw_offset
	draw_circle(body_center, BODY_RADIUS, BODY_COLOR)
	draw_circle(body_center + Vector2(0.0, -3.0), BODY_RADIUS - 4.0, SHIRT_COLOR)


func _draw_arms(draw_offset: Vector2) -> void:
	var perp: Vector2 = _facing.orthogonal().normalized() if _facing.length() > 0.01 else Vector2.RIGHT
	var forward: Vector2 = _facing.normalized() if _facing.length() > 0.01 else Vector2.DOWN
	var arm_swing: float = sin(_walk_cycle * TAU) * 5.0 if is_walking() else 0.0
	if carry_state == CarryState.NONE:
		var left_shoulder: Vector2 = draw_offset + perp * 10.0
		var right_shoulder: Vector2 = draw_offset - perp * 10.0
		var left_hand: Vector2 = left_shoulder + forward * (ARM_LENGTH * 0.4) + perp * (4.0 + arm_swing)
		var right_hand: Vector2 = right_shoulder + forward * (ARM_LENGTH * 0.4) - perp * (4.0 + arm_swing)
		draw_line(left_shoulder, left_hand, BODY_COLOR, 5.0, true)
		draw_line(right_shoulder, right_hand, BODY_COLOR, 5.0, true)
		draw_circle(left_hand, 3.5, HEAD_COLOR)
		draw_circle(right_hand, 3.5, HEAD_COLOR)
	else:
		var carry_center: Vector2 = draw_offset + forward * (ARM_LENGTH + 4.0)
		var left_hand: Vector2 = carry_center + perp * 6.0
		var right_hand: Vector2 = carry_center - perp * 6.0
		draw_line(draw_offset + perp * 8.0, left_hand, BODY_COLOR, 5.0, true)
		draw_line(draw_offset - perp * 8.0, right_hand, BODY_COLOR, 5.0, true)
		if carry_state == CarryState.DUCT_TAPE:
			_draw_carried_tape(carry_center, perp)
		elif carry_state == CarryState.BUCKET:
			_draw_carried_bucket(carry_center, perp, forward)


func _draw_carried_tape(center: Vector2, perp: Vector2) -> void:
	draw_circle(center + Vector2(1.5, 2.0), 9.5, SHADOW_COLOR)
	draw_circle(center, 9.0, TAPE_COLOR)
	draw_circle(center, 4.5, TAPE_STRIPE)
	draw_circle(center, 2.0, BODY_COLOR)
	draw_arc(center, 7.0, 0.0, TAU, 24, TAPE_STRIPE, 1.4, true)


func _draw_carried_bucket(center: Vector2, perp: Vector2, forward: Vector2) -> void:
	var rim_left: Vector2 = center + perp * 9.0 - forward * 2.0
	var rim_right: Vector2 = center - perp * 9.0 - forward * 2.0
	var base_left: Vector2 = center + perp * 6.0 + forward * 9.0
	var base_right: Vector2 = center - perp * 6.0 + forward * 9.0
	var points: PackedVector2Array = PackedVector2Array([rim_left, rim_right, base_right, base_left])
	draw_colored_polygon(points, BUCKET_COLOR)
	draw_line(rim_left, rim_right, BUCKET_RIM, 2.5, true)
	draw_line(rim_left, base_left, BUCKET_RIM, 1.5, true)
	draw_line(rim_right, base_right, BUCKET_RIM, 1.5, true)
	draw_line(base_left, base_right, BUCKET_RIM, 1.5, true)
	var handle_top: Vector2 = center + perp * -2.0 - forward * 6.0
	draw_arc(handle_top, 7.0, PI * 1.05, PI * 1.95, 14, BUCKET_RIM, 1.6, true)


func _draw_head(draw_offset: Vector2) -> void:
	var head_center: Vector2 = draw_offset + Vector2(0.0, -BODY_RADIUS + 4.0)
	draw_circle(head_center + Vector2(1.0, 1.5), HEAD_RADIUS + 0.5, SHADOW_COLOR)
	draw_circle(head_center, HEAD_RADIUS, HEAD_COLOR)
	draw_arc(head_center, HEAD_RADIUS - 0.5, 0.0, TAU, 32, HEAD_OUTLINE, 1.2, true)
	# hair on the side the player is facing away from
	var hair_offset: Vector2 = -_facing.normalized() * 4.0 if _facing.length() > 0.01 else Vector2(0.0, -4.0)
	draw_circle(head_center + hair_offset, HEAD_RADIUS - 4.0, HAIR_COLOR)
	# little nose/face direction marker so player can see facing
	var nose: Vector2 = head_center + _facing.normalized() * (HEAD_RADIUS - 4.0)
	draw_circle(nose, 2.0, HEAD_OUTLINE)


func _draw_slip_marks() -> void:
	var spark_color: Color = Color(0.949020, 0.733333, 0.247059, 0.7)
	for index: int in range(4):
		var angle: float = float(index) * (PI * 0.5) + _slip_timer * 12.0
		var start: Vector2 = Vector2(cos(angle), sin(angle)) * (BODY_RADIUS + 8.0)
		var stop: Vector2 = start + start.normalized() * 6.0
		draw_line(start, stop, spark_color, 2.0, true)
