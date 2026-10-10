class_name Service extends RefCounted
# Base service class.

var service_name: String
var port: int
var protocol: String = "tcp"
var is_running: bool = false
var auto_start: bool = false
var cpu_usage: float = 0.0
var ram_usage_mb: float = 0.0
var device_id: String = ""

func _init(p_name: String, p_port: int, p_protocol: String = "tcp"):
	service_name = p_name
	port = p_port
	protocol = p_protocol

func start() -> String:
	is_running = true
	# CPU/RAM usage overridden by subclasses, but set defaults here
	cpu_usage = 1.0
	ram_usage_mb = 10.0
	return "Service started"

func stop() -> String:
	is_running = false
	cpu_usage = 0.0
	ram_usage_mb = 0.0
	return "Service stopped"

func restart() -> String:
	stop()
	return start()

func handle_request(request_data: Dictionary) -> Dictionary:
	return {"status": "error", "body": "not implemented"}

func get_status_string() -> String:
	return "RUNNING" if is_running else "STOPPED"

func to_dict() -> Dictionary:
	return {
		"service_type": service_name,
		"port": port,
		"protocol": protocol,
		"is_running": is_running,
		"auto_start": auto_start,
		"device_id": device_id
	}

static func from_dict(data: Dictionary) -> Service:
	var srv: Service = null
	var s_type = data.get("service_type", "")
	
	match s_type:
		"http":
			srv = HttpService.new()
		"ssh":
			srv = SshService.new()
		"database":
			srv = DatabaseService.new()
		"dns":
			srv = DnsService.new()
		_:
			srv = Service.new(s_type, data.get("port", 0), data.get("protocol", "tcp"))
	
	if srv:
		srv.port = data.get("port", srv.port)
		srv.protocol = data.get("protocol", srv.protocol)
		srv.is_running = data.get("is_running", false)
		srv.auto_start = data.get("auto_start", false)
		srv.device_id = data.get("device_id", "")
		if srv is DnsService and data.has("records"):
			srv.records = data["records"]
		if srv.is_running:
			srv.start()
			
	return srv
