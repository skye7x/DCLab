class_name HttpService extends Service

var web_root: String = "/www"
var default_document: String = "index.html"

func _init():
	super("http", 80, "tcp")
	cpu_usage = 2.0
	ram_usage_mb = 150.0

func start() -> String:
	is_running = true
	cpu_usage = 2.0
	ram_usage_mb = 150.0
	return "HTTP Server started"

func stop() -> String:
	is_running = false
	cpu_usage = 0.0
	ram_usage_mb = 0.0
	return "HTTP Server stopped"

func handle_request(request_data: Dictionary) -> Dictionary:
	if not is_running:
		return {"status": 503, "body": "Service Unavailable"}
		
	var path: String = request_data.get("path", "/")
	var method: String = request_data.get("method", "GET")
	
	var tree = Engine.get_main_loop()
	if not tree or not tree.root or not tree.root.has_node("SimEngine"):
		return {"status": 500, "body": "Internal Server Error - No Engine"}
		
	var engine = tree.root.get_node("SimEngine")
	var device = engine.get_device(device_id)
	if not device or not (device is Computer):
		return {"status": 500, "body": "Internal Server Error - Invalid Device"}
		
	var os = device.operating_system
	if not os:
		return {"status": 500, "body": "Internal Server Error - No OS"}
		
	var fs = os.file_system
	var target_file = web_root + path
	if path == "/" or path.ends_with("/"):
		target_file = web_root + "/" + default_document
		
	var file_content = null
	if fs and fs.has_method("read_file"):
		if fs.exists(target_file) and not fs.is_dir(target_file):
			file_content = fs.read_file(target_file)
	elif os.get("file_system") is Dictionary and os.file_system.has(target_file):
		file_content = os.file_system[target_file]
		
	if file_content != null:
		return {"status": 200, "body": file_content}
	else:
		return {"status": 404, "body": "<html><body><h1>404 Not Found</h1></body></html>"}

func to_dict() -> Dictionary:
	var d = super.to_dict()
	d["web_root"] = web_root
	d["default_document"] = default_document
	return d
