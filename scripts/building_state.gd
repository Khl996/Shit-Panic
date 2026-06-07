class_name BuildingState
extends RefCounted

# The whole game state in one number: building health. It drains by the summed
# danger of every active hazard. Survive as long as possible. No abstract
# temperature / pressure / power meters — one readable bar.

enum RoundState {
	RUNNING,
	LOST,
}

const MAX_HEALTH: float = 100.0
const REGEN_PER_SECOND: float = 1.6  # slow self-recovery when everything is calm

var health: float = MAX_HEALTH
var elapsed_time: float = 0.0
var round_state: int = RoundState.RUNNING
var hazards_fixed: int = 0
var peak_active_hazards: int = 0
var worst_hazard_label: String = "لا شيء"


func reset() -> void:
	health = MAX_HEALTH
	elapsed_time = 0.0
	round_state = RoundState.RUNNING
	hazards_fixed = 0
	peak_active_hazards = 0
	worst_hazard_label = "لا شيء"


func advance(delta: float, total_danger: float, active_hazards: int) -> void:
	if round_state != RoundState.RUNNING:
		return
	var safe_delta: float = maxf(delta, 0.0)
	elapsed_time += safe_delta
	if total_danger > 0.0:
		health -= total_danger * safe_delta
	else:
		health += REGEN_PER_SECOND * safe_delta
	health = clampf(health, 0.0, MAX_HEALTH)
	peak_active_hazards = maxi(peak_active_hazards, active_hazards)
	if health <= 0.0:
		round_state = RoundState.LOST


func register_fix() -> void:
	hazards_fixed += 1


func is_lost() -> bool:
	return round_state == RoundState.LOST


func health_ratio() -> float:
	return clampf(health / MAX_HEALTH, 0.0, 1.0)
