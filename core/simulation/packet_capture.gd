class_name PacketCapture
extends RefCounted

static var packets: Array = []
static var max_packets: int = 500
static var is_capturing: bool = false

static func start_capture() -> void:
	packets.clear()
	is_capturing = true

static func stop_capture() -> void:
	is_capturing = false

static func clear() -> void:
	packets.clear()

static func record(src_ip: String, dst_ip: String, protocol: String, size_bytes: int, info: String = "") -> void:
	if not is_capturing:
		return
	var tree = Engine.get_main_loop()
	var sim_time = 0.0
	if tree and tree.root and tree.root.has_node("SimTime"):
		sim_time = tree.root.get_node("SimTime").total_elapsed
	packets.append({
		"time": sim_time,
		"src": src_ip,
		"dst": dst_ip,
		"protocol": protocol,
		"size": size_bytes,
		"info": info
	})
	if packets.size() > max_packets:
		packets.pop_front()

static func get_packets() -> Array:
	return packets.duplicate(true)
