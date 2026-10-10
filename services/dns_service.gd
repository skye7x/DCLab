class_name DnsService extends Service

var records: Dictionary = {}       # hostname -> ip
var ttl_default: int = 300

func _init():
	super("dns", 53, "udp")

func start() -> String:
	is_running = true
	cpu_usage = 0.5
	ram_usage_mb = 25.0
	return "DNS Server started"

func stop() -> String:
	is_running = false
	cpu_usage = 0.0
	ram_usage_mb = 0.0
	return "DNS Server stopped"

func add_record(hostname: String, ip: String) -> void:
	records[hostname.to_lower()] = ip

func remove_record(hostname: String) -> bool:
	return records.erase(hostname.to_lower())

func resolve(hostname: String) -> String:
	return records.get(hostname.to_lower(), "")

func handle_request(request_data: Dictionary) -> Dictionary:
	if not is_running:
		return {"status": "refused", "body": "Connection refused"}
	var qtype = request_data.get("type", "A")
	if qtype == "A":
		var name = request_data.get("name", "")
		var ip = resolve(name)
		if ip != "":
			return {"status": "success", "body": ip, "ttl": ttl_default}
		return {"status": "nxdomain", "body": "NXDOMAIN"}
	return {"status": "error", "body": "Unsupported query type"}

func to_dict() -> Dictionary:
	var d = super.to_dict()
	d["records"] = records.duplicate()
	d["ttl_default"] = ttl_default
	return d
