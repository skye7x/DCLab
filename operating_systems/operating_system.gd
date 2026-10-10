class_name OperatingSystem extends RefCounted

var os_name: String = "DCLinux"
var hostname: String = "localhost"
var users: Array = []
var processes: Array = []
var file_system: FileSystem
var env_vars: Dictionary = {}
var current_user: UserAccount
var device_id: String = ""
var _next_pid: int = 1

func _init(p_hostname: String = "localhost", p_device_id: String = ""):
	hostname = p_hostname
	device_id = p_device_id
	file_system = FileSystem.new()
	
	var root_user = add_user("root", true)
	current_user = root_user
	
	env_vars["PATH"] = "/bin:/usr/bin"
	env_vars["HOME"] = root_user.home_directory
	env_vars["HOSTNAME"] = hostname
	env_vars["USER"] = root_user.username
	
	file_system.write_file("/etc/hostname", hostname + "\n")

func add_user(username: String, is_root: bool = false) -> UserAccount:
	var user = UserAccount.new(username, is_root)
	users.append(user)
	if not is_root and not file_system.exists(user.home_directory):
		file_system.create_directory(user.home_directory)
	return user

func get_user(username: String) -> UserAccount:
	for user in users:
		if user.username == username:
			return user
	return null

func remove_user(username: String) -> bool:
	for i in range(users.size()):
		if users[i].username == username:
			if users[i].is_root:
				return false
			users.remove_at(i)
			return true
	return false

func set_password(username: String, password: String) -> bool:
	var user = get_user(username)
	if not user:
		return false
	# Simple non-reversible-ish hash for the lab (NOT real security)
	var hash = 5381
	for i in range(password.length()):
		hash = ((hash << 5) + hash + password.unicode_at(i)) & 0x7FFFFFFF
	user.password_hash = "sha1:%08x" % hash
	return true

func authenticate(username: String, password: String) -> bool:
	var user = get_user(username)
	if not user:
		return false
	if user.password_hash == "":
		return true  # no password set
	var hash = 5381
	for i in range(password.length()):
		hash = ((hash << 5) + hash + password.unicode_at(i)) & 0x7FFFFFFF
	return user.password_hash == "sha1:%08x" % hash

func switch_user(username: String) -> String:
	var user = get_user(username)
	if not user:
		return "su: user %s does not exist" % username
	current_user = user
	env_vars["HOME"] = user.home_directory
	env_vars["USER"] = user.username
	return ""

func add_process(name: String, cpu: float = 0.0, ram: float = 0.0) -> ProcessInfo:
	var process = ProcessInfo.new(get_next_pid(), name, cpu, ram)
	processes.append(process)
	return process

func remove_process(pid: int):
	for i in range(processes.size()):
		if processes[i].pid == pid:
			processes.remove_at(i)
			return

func get_processes() -> Array:
	return processes

func get_next_pid() -> int:
	var pid = _next_pid
	_next_pid += 1
	return pid

func to_dict() -> Dictionary:
	var users_data = []
	for u in users:
		users_data.append(u.to_dict())
	var processes_data = []
	for p in processes:
		processes_data.append(p.to_dict())
		
	return {
		"os_name": os_name,
		"hostname": hostname,
		"users": users_data,
		"processes": processes_data,
		"file_system": file_system.to_dict(),
		"env_vars": env_vars,
		"current_user_name": current_user.username if current_user else "root",
		"device_id": device_id,
		"_next_pid": _next_pid
	}

func from_dict(data: Dictionary):
	os_name = data.get("os_name", "DCLinux")
	hostname = data.get("hostname", "localhost")
	device_id = data.get("device_id", "")
	_next_pid = data.get("_next_pid", 1)
	env_vars = data.get("env_vars", {})
	
	users.clear()
	for ud in data.get("users", []):
		users.append(UserAccount.from_dict(ud))
		
	var curr_name = data.get("current_user_name", "root")
	current_user = get_user(curr_name)
	
	processes.clear()
	for pd in data.get("processes", []):
		var p = ProcessInfo.new(pd.get("pid", 0), pd.get("process_name", ""), pd.get("cpu_percent", 0.0), pd.get("ram_mb", 0.0))
		p.is_running = pd.get("is_running", true)
		p.owner = pd.get("owner", "root")
		processes.append(p)
		
	if data.has("file_system"):
		file_system = FileSystem.from_dict(data["file_system"])
