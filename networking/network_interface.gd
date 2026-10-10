class_name NetworkInterface
extends RefCounted

var iface_name: String
var mac_address: String
var ipv4_address: String = ""
var subnet_mask: String = ""
var gateway: String = ""
var is_enabled: bool = true
var is_linked: bool = false
var rx_bytes: int = 0
var tx_bytes: int = 0
var link = null
var device_id: String = ""

func _init(p_name: String, p_device_id: String = "") -> void:
	iface_name = p_name
	device_id = p_device_id
	mac_address = IPv4Address.generate_mac()

func configure(ip: String, mask: String, gw: String = "") -> void:
	ipv4_address = ip
	subnet_mask = mask
	gateway = gw

func get_cidr() -> int:
	if subnet_mask == "":
		return 0
	return IPv4Address.mask_to_cidr(subnet_mask)

func get_subnet() -> Subnet:
	if not is_configured():
		return null
	return Subnet.new(ipv4_address, get_cidr())

func is_configured() -> bool:
	return ipv4_address != "" and subnet_mask != "" and IPv4Address.is_valid(ipv4_address) and IPv4Address.is_valid(subnet_mask)

func to_dict() -> Dictionary:
	return {
		"iface_name": iface_name,
		"mac_address": mac_address,
		"ipv4_address": ipv4_address,
		"subnet_mask": subnet_mask,
		"gateway": gateway,
		"is_enabled": is_enabled,
		"is_linked": is_linked,
		"rx_bytes": rx_bytes,
		"tx_bytes": tx_bytes,
		"device_id": device_id
	}

func from_dict(data: Dictionary) -> void:
	iface_name = data.get("iface_name", "")
	mac_address = data.get("mac_address", IPv4Address.generate_mac())
	ipv4_address = data.get("ipv4_address", "")
	subnet_mask = data.get("subnet_mask", "")
	gateway = data.get("gateway", "")
	is_enabled = data.get("is_enabled", true)
	is_linked = data.get("is_linked", false)
	rx_bytes = data.get("rx_bytes", 0)
	tx_bytes = data.get("tx_bytes", 0)
	device_id = data.get("device_id", "")
