class_name EthernetLink
extends RefCounted

var id: String
var source_device_id: String
var source_interface_name: String
var dest_device_id: String
var dest_interface_name: String
var is_enabled: bool = true
var bandwidth_mbps: int = 1000
var latency_ms: float = 1.0
var packet_loss_percent: float = 0.0
var bytes_transferred: int = 0
var _util_window_start: float = -1.0
var _util_window_bytes: int = 0

func record_traffic(bytes: int) -> void:
	bytes_transferred += bytes
	_util_window_bytes += bytes
	var now = Time.get_ticks_msec() / 1000.0
	if _util_window_start < 0.0:
		_util_window_start = now
	var elapsed = now - _util_window_start
	if elapsed >= 1.0:
		_util_window_start = now
		_util_window_bytes = 0

func get_utilization() -> float:
	# Utilization as fraction of bandwidth over the last ~1s window
	var now = Time.get_ticks_msec() / 1000.0
	var elapsed = now - _util_window_start if _util_window_start >= 0.0 else 0.0
	if elapsed <= 0.0 or bandwidth_mbps <= 0:
		return 0.0
	var bits = _util_window_bytes * 8.0
	var capacity_bits = bandwidth_mbps * 1000000.0 * elapsed
	return clampf(bits / capacity_bits, 0.0, 1.0)

func get_congested_latency() -> float:
	# Latency grows hyperbolically as utilization approaches 100%
	var util = get_utilization()
	var penalty = 1.0 / maxf(0.05, 1.0 - util) - 1.0
	return latency_ms * (1.0 + penalty)

func _init(p_id: String, src_dev_id: String, src_iface: String, dst_dev_id: String, dst_iface: String) -> void:
	id = p_id
	source_device_id = src_dev_id
	source_interface_name = src_iface
	dest_device_id = dst_dev_id
	dest_interface_name = dst_iface

func get_other_device_id(device_id: String) -> String:
	if device_id == source_device_id:
		return dest_device_id
	elif device_id == dest_device_id:
		return source_device_id
	return ""

func get_other_interface_name(device_id: String) -> String:
	if device_id == source_device_id:
		return dest_interface_name
	elif device_id == dest_device_id:
		return source_interface_name
	return ""

func to_dict() -> Dictionary:
	return {
		"id": id,
		"source_device_id": source_device_id,
		"source_interface_name": source_interface_name,
		"dest_device_id": dest_device_id,
		"dest_interface_name": dest_interface_name,
		"is_enabled": is_enabled,
		"bandwidth_mbps": bandwidth_mbps,
		"latency_ms": latency_ms,
		"packet_loss_percent": packet_loss_percent,
		"bytes_transferred": bytes_transferred
	}

func from_dict(data: Dictionary) -> void:
	id = data.get("id", "")
	source_device_id = data.get("source_device_id", "")
	source_interface_name = data.get("source_interface_name", "")
	dest_device_id = data.get("dest_device_id", "")
	dest_interface_name = data.get("dest_interface_name", "")
	is_enabled = data.get("is_enabled", true)
	bandwidth_mbps = data.get("bandwidth_mbps", 1000)
	latency_ms = data.get("latency_ms", 1.0)
	packet_loss_percent = data.get("packet_loss_percent", 0.0)
	bytes_transferred = data.get("bytes_transferred", 0)
