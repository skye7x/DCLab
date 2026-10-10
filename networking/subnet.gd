class_name Subnet
extends RefCounted

var network_address: String
var cidr: int
var subnet_mask: String
var broadcast_address: String
var first_host: String
var last_host: String
var total_hosts: int

func _init(ip: String, p_cidr: int) -> void:
	cidr = p_cidr
	subnet_mask = IPv4Address.cidr_to_mask(cidr)
	network_address = IPv4Address.get_network(ip, subnet_mask)
	broadcast_address = IPv4Address.get_broadcast(ip, subnet_mask)
	
	var net_int = IPv4Address.to_int(network_address)
	var bcast_int = IPv4Address.to_int(broadcast_address)
	
	if cidr == 32:
		first_host = network_address
		last_host = network_address
		total_hosts = 1
	elif cidr == 31:
		first_host = network_address
		last_host = broadcast_address
		total_hosts = 2
	else:
		first_host = IPv4Address.from_int(net_int + 1)
		last_host = IPv4Address.from_int(bcast_int - 1)
		total_hosts = max(0, bcast_int - net_int - 1)

func contains(ip: String) -> bool:
	return IPv4Address.is_same_subnet(network_address, ip, subnet_mask)

func to_label() -> String:
	return "%s/%d" % [network_address, cidr]

func to_dict() -> Dictionary:
	return {
		"network_address": network_address,
		"cidr": cidr,
		"subnet_mask": subnet_mask,
		"broadcast_address": broadcast_address,
		"first_host": first_host,
		"last_host": last_host,
		"total_hosts": total_hosts
	}

static func from_cidr(ip: String, cidr: int) -> Subnet:
	return Subnet.new(ip, cidr)
