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
		"packet_loss_percent": packet_loss_percent
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
