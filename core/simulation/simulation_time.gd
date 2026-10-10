extends Node

var total_elapsed: float = 0.0
var is_paused: bool = true
var speed: float = 1.0
var tick_count: int = 0

func _process(delta: float) -> void:
	if not is_paused:
		advance(delta * speed)

func advance(delta: float) -> void:
	total_elapsed += delta
	tick_count += 1
	EventBus.simulation_tick.emit(delta)

func reset() -> void:
	total_elapsed = 0.0
	tick_count = 0
	is_paused = true
	speed = 1.0

func get_formatted_time() -> String:
	var total_seconds: int = int(total_elapsed)
	var hours: int = total_seconds / 3600
	var minutes: int = (total_seconds % 3600) / 60
	var seconds: int = total_seconds % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

func pause() -> void:
	if not is_paused:
		is_paused = true
		EventBus.simulation_paused.emit()

func unpause() -> void:
	if is_paused:
		is_paused = false
		EventBus.simulation_started.emit()

func set_speed(s: float) -> void:
	speed = max(0.1, s)
