class_name FtpService extends Service

var ftp_root: String = "/ftp"
var allow_anonymous: bool = true
var allow_upload: bool = false

func _init():
	super("ftp", 21, "tcp")
	cpu_usage = 1.5
	ram_usage_mb = 80.0

func start() -> String:
	is_running = true
	cpu_usage = 1.5
	ram_usage_mb = 80.0
	return "FTP Server started"

func stop() -> String:
	is_running = false
	cpu_usage = 0.0
	ram_usage_mb = 0.0
	return "FTP Server stopped"

func handle_request(request_data: Dictionary) -> Dictionary:
	if not is_running:
		return {"status": 503, "message": "Service Unavailable"}
	
	var command: String = request_data.get("command", "")
	var path: String = request_data.get("path", "/")
	var user: String = request_data.get("user", "anonymous")
	var content: String = request_data.get("content", "")
	
	if not allow_anonymous and user == "anonymous":
		return {"status": 530, "message": "Login incorrect"}
	
	var tree = Engine.get_main_loop()
	if not tree or not tree.root or not tree.root.has_node("SimEngine"):
		return {"status": 500, "message": "Internal Server Error"}
	
	var engine = tree.root.get_node("SimEngine")
	var device = engine.get_device(device_id)
	if not device or not (device is Computer):
		return {"status": 500, "message": "Invalid Device"}
	
	var os = device.operating_system
	if not os:
		return {"status": 500, "message": "No OS"}
	
	var fs = os.file_system
	var target_path = ftp_root + path
	
	match command:
		"LIST":
			if not fs.exists(target_path):
				return {"status": 550, "message": "No such file or directory"}
			if not fs.is_dir(target_path):
				return {"status": 550, "message": "Not a directory"}
			var files = fs.list_directory(target_path)
			var listing = []
			for f in files:
				if f is FileNode:
					listing.append({"name": f.node_name, "is_dir": f.is_directory, "size": f.size_bytes})
			return {"status": 226, "message": "Transfer complete", "data": listing}
		
		"RETR":
			if not fs.exists(target_path):
				return {"status": 550, "message": "File not found"}
			if fs.is_dir(target_path):
				return {"status": 550, "message": "Is a directory"}
			var file_content = fs.read_file(target_path)
			return {"status": 226, "message": "Transfer complete", "data": file_content}
		
		"STOR":
			if not allow_upload:
				return {"status": 550, "message": "Upload not allowed"}
			fs.write_file(target_path, content)
			return {"status": 226, "message": "Transfer complete"}
		
		"MKD":
			if not allow_upload:
				return {"status": 550, "message": "Upload not allowed"}
			fs.create_directory(target_path)
			return {"status": 257, "message": "Directory created"}
		
		"RMD":
			if not allow_upload:
				return {"status": 550, "message": "Upload not allowed"}
			if not fs.exists(target_path):
				return {"status": 550, "message": "No such directory"}
			fs.delete_node(target_path)
			return {"status": 250, "message": "Directory removed"}
		
		"DELE":
			if not allow_upload:
				return {"status": 550, "message": "Upload not allowed"}
			if not fs.exists(target_path):
				return {"status": 550, "message": "File not found"}
			fs.delete_node(target_path)
			return {"status": 250, "message": "File deleted"}
		
		_:
			return {"status": 502, "message": "Command not implemented"}

func to_dict() -> Dictionary:
	var d = super.to_dict()
	d["ftp_root"] = ftp_root
	d["allow_anonymous"] = allow_anonymous
	d["allow_upload"] = allow_upload
	return d
