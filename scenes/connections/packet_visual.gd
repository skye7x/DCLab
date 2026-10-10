extends Node2D
class_name PacketVisual

var start_pos: Vector2
var end_pos: Vector2
var travel_time: float = 0.5
var _elapsed: float = 0.0
var color: Color = Color(0.2, 0.8, 0.2)
var radius: float = 4.0

var protocol_color: Dictionary = {
	'ICMP': Color(0.2, 0.8, 0.2),
	'TCP': Color(0.2, 0.2, 0.8),
	'HTTP': Color(0.8, 0.6, 0.2),
	'UDP': Color(0.8, 0.2, 0.8)
}

func setup(from: Vector2, to: Vector2, protocol: String = 'ICMP', speed: float = 0.5) -> void:
	start_pos = from
	end_pos = to
	travel_time = max(0.01, speed)
	color = protocol_color.get(protocol, Color.GREEN)
	position = start_pos

func _process(delta: float) -> void:
	_elapsed += delta
	var t = clampf(_elapsed / travel_time, 0.0, 1.0)
	position = start_pos.lerp(end_pos, t)
	
	if t >= 1.0:
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
	draw_circle(Vector2.ZERO, radius * 1.5, Color(color, 0.3))
