class_name EmailService extends Service

var mail_root: String = "/mail"
var smtp_port: int = 25
var imap_port: int = 143

func _init():
	super("email", smtp_port, "tcp")
	cpu_usage = 3.0
	ram_usage_mb = 200.0

func start() -> String:
	is_running = true
	cpu_usage = 3.0
	ram_usage_mb = 200.0
	return "Email Server started"

func stop() -> String:
	is_running = false
	cpu_usage = 0.0
	ram_usage_mb = 0.0
	return "Email Server stopped"

func handle_request(request_data: Dictionary) -> Dictionary:
	if not is_running:
		return {"status": 503, "message": "Service Unavailable"}
	
	var from_addr: String = request_data.get("from", "")
	var to_addr: String = request_data.get("to", "")
	var subject: String = request_data.get("subject", "")
	var body: String = request_data.get("body", "")
	
	var tree = Engine.get_main_loop()
	if not tree or not tree.root or not tree.root.has_node("SimEngine"):
		return {"status": 500, "message": "Internal Server Error - No Engine"}
	
	var engine = tree.root.get_node("SimEngine")
	var device = engine.get_device(device_id)
	if not device or not (device is Computer):
		return {"status": 500, "message": "Invalid Device"}
	
	var os = device.operating_system
	if not os:
		return {"status": 500, "message": "No OS"}
	
	var fs = os.file_system
	var mail_dir = mail_root + "/inbox"
	
	# Ensure mail directory exists
	if not fs.exists(mail_dir):
		fs.create_directory(mail_dir)
	
	# Store the email
	var email_file = mail_dir + "/email_" + str(SimTime.total_elapsed).replace(".", "_") + ".eml"
	fs.write_file(email_file, "From: " + from_addr + "\nTo: " + to_addr + "\nSubject: " + subject + "\n\n" + body)
	
	return {"status": 250, "message": "Mail delivered", "file": email_file}

func to_dict() -> Dictionary:
	var d = super.to_dict()
	d["mail_root"] = mail_root
	return d