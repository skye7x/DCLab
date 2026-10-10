class_name RoutingTable
extends RefCounted

var routes: Array = []

func add_route(network: String, cidr: int, iface_name: String, gateway: String, metric: int) -> void:
	# Check if exists
	for i in range(routes.size()):
		var r = routes[i]
		if r.network == network and r.cidr == cidr:
			routes[i] = {"network": network, "cidr": cidr, "interface_name": iface_name, "gateway": gateway, "metric": metric}
			return
	
	routes.append({"network": network, "cidr": cidr, "interface_name": iface_name, "gateway": gateway, "metric": metric})

func remove_route(network: String, cidr: int) -> void:
	for i in range(routes.size()):
		if routes[i].network == network and routes[i].cidr == cidr:
			routes.remove_at(i)
			return

func find_route(dest_ip: String) -> Dictionary:
	var best_match: Dictionary = {}
	var best_cidr: int = -1
	var best_metric: int = 999999
	
	for route in routes:
		var mask = IPv4Address.cidr_to_mask(route.cidr)
		if IPv4Address.is_same_subnet(route.network, dest_ip, mask):
			if route.cidr > best_cidr or (route.cidr == best_cidr and route.metric < best_metric):
				best_match = route
				best_cidr = route.cidr
				best_metric = route.metric
				
	return best_match

func get_all_routes() -> Array:
	return routes.duplicate()

func clear() -> void:
	routes.clear()

func to_dict() -> Dictionary:
	return {"routes": routes.duplicate(true)}

func from_dict(data: Dictionary) -> void:
	if data.has("routes"):
		routes = data["routes"].duplicate(true)
