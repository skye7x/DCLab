class_name IPv4Address
extends RefCounted

static func is_valid(ip: String) -> bool:
	var parts = ip.split(".")
	if parts.size() != 4:
		return false
	for p in parts:
		if not p.is_valid_int():
			return false
		var v = p.to_int()
		if v < 0 or v > 255:
			return false
	return true

static func to_int(ip: String) -> int:
	if not is_valid(ip):
		return 0
	var parts = ip.split(".")
	var val: int = 0
	val += parts[0].to_int() << 24
	val += parts[1].to_int() << 16
	val += parts[2].to_int() << 8
	val += parts[3].to_int()
	return val

static func from_int(value: int) -> String:
	var p1 = (value >> 24) & 255
	var p2 = (value >> 16) & 255
	var p3 = (value >> 8) & 255
	var p4 = value & 255
	return "%d.%d.%d.%d" % [p1, p2, p3, p4]

static func get_network(ip: String, mask: String) -> String:
	var ip_val = to_int(ip)
	var mask_val = to_int(mask)
	return from_int(ip_val & mask_val)

static func get_broadcast(ip: String, mask: String) -> String:
	var ip_val = to_int(ip)
	var mask_val = to_int(mask)
	return from_int((ip_val & mask_val) | (~mask_val & 0xFFFFFFFF))

static func is_same_subnet(ip1: String, ip2: String, mask: String) -> bool:
	var n1 = get_network(ip1, mask)
	var n2 = get_network(ip2, mask)
	return n1 == n2

static func cidr_to_mask(cidr: int) -> String:
	if cidr < 0 or cidr > 32:
		return "0.0.0.0"
	var mask_val = 0
	if cidr > 0:
		mask_val = (0xFFFFFFFF << (32 - cidr)) & 0xFFFFFFFF
	return from_int(mask_val)

static func mask_to_cidr(mask: String) -> int:
	var m = to_int(mask)
	var count = 0
	while m > 0:
		count += (m & 1)
		m = m >> 1
	return count

static func generate_mac() -> String:
	var hex_chars = "0123456789ABCDEF"
	var mac = "02"
	for i in range(5):
		mac += ":" + hex_chars[randi() % 16] + hex_chars[randi() % 16]
	return mac
