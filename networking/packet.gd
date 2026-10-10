class_name Packet
extends RefCounted

static var _next_id: int = 1

var id: String
var source_ip: String
var dest_ip: String
var source_mac: String = ""
var dest_mac: String = ""
var protocol: String
var source_port: int = 0
var dest_port: int = 0
var payload: String = ""
var ttl: int = 64
var hops: Array = []
var timestamp: float = 0.0

func _init(p_src_ip: String, p_dst_ip: String, p_protocol: String, p_payload: String = "") -> void:
	id = "pkt_%04d" % _next_id
	Packet._next_id += 1
	
	source_ip = p_src_ip
	dest_ip = p_dst_ip
	protocol = p_protocol
	payload = p_payload
	
	var tree = Engine.get_main_loop()
	if tree and tree.root and tree.root.has_node("SimTime"):
		timestamp = tree.root.get_node("SimTime").total_elapsed

func add_hop(device_id: String) -> void:
	hops.append(device_id)

func to_dict() -> Dictionary:
	return {
		"id": id,
		"source_ip": source_ip,
		"dest_ip": dest_ip,
		"source_mac": source_mac,
		"dest_mac": dest_mac,
		"protocol": protocol,
		"source_port": source_port,
		"dest_port": dest_port,
		"payload": payload,
		"ttl": ttl,
		"hops": hops.duplicate(),
		"timestamp": timestamp
	}
