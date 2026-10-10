class_name FileSystem extends RefCounted

var root: FileNode

func _init():
	root = FileNode.new("/", true)
	_create_default_structure()

func _create_default_structure():
	# /etc/ (with hosts, hostname, resolv.conf files)
	var etc = FileNode.new("etc", true)
	root.add_child_node(etc)
	etc.add_child_node(FileNode.new("hosts", false, "127.0.0.1 localhost\n"))
	etc.add_child_node(FileNode.new("hostname", false, "localhost\n"))
	etc.add_child_node(FileNode.new("resolv.conf", false, "nameserver 8.8.8.8\n"))
	
	# /etc/services/ (directory)
	etc.add_child_node(FileNode.new("services", true))
	
	# /home/ 
	var home = FileNode.new("home", true)
	root.add_child_node(home)
	
	# /home/admin/
	home.add_child_node(FileNode.new("admin", true))
	
	# /var/
	var var_dir = FileNode.new("var", true)
	root.add_child_node(var_dir)
	
	# /var/log/ (with syslog file)
	var log_dir = FileNode.new("log", true)
	var_dir.add_child_node(log_dir)
	log_dir.add_child_node(FileNode.new("syslog", false, ""))
	
	# /tmp/
	root.add_child_node(FileNode.new("tmp", true))
	
	# /www/ (with index.html)
	var www = FileNode.new("www", true)
	root.add_child_node(www)
	www.add_child_node(FileNode.new("index.html", false, "<html><body><h1>Hello from DCLab</h1></body></html>"))
	
	# /bin/ (directory)
	root.add_child_node(FileNode.new("bin", true))
	
	# /proc/ (directory)
	root.add_child_node(FileNode.new("proc", true))

func resolve_path(current_dir: String, path: String) -> String:
	var final_path: String = path
	
	if not final_path.begins_with("/"):
		if current_dir.ends_with("/"):
			final_path = current_dir + path
		else:
			final_path = current_dir + "/" + path
			
	var parts = final_path.split("/", false)
	var resolved_parts: Array = []
	
	for part in parts:
		if part == ".":
			continue
		elif part == "..":
			if resolved_parts.size() > 0:
				resolved_parts.pop_back()
		else:
			resolved_parts.append(part)
			
	var result: String = "/" + "/".join(resolved_parts)
	return result

func get_node_at(path: String) -> FileNode:
	if path == "/" or path == "":
		return root
		
	var parts = path.split("/", false)
	var curr: FileNode = root
	
	for part in parts:
		if curr.is_directory and curr.has_child(part):
			curr = curr.get_child(part)
		else:
			return null
			
	return curr

func create_file(path: String, content: String = "") -> String:
	var last_slash: int = path.rfind("/")
	if last_slash == -1:
		return "Invalid path"
		
	var dir_path: String = path.substr(0, last_slash)
	if dir_path == "":
		dir_path = "/"
		
	var file_name: String = path.substr(last_slash + 1)
	if file_name == "":
		return "Invalid file name"
		
	var parent_dir: FileNode = get_node_at(dir_path)
	if parent_dir == null:
		return "Directory does not exist"
	if not parent_dir.is_directory:
		return "Not a directory"
	if parent_dir.has_child(file_name):
		return "File already exists"
		
	var new_file: FileNode = FileNode.new(file_name, false, content)
	parent_dir.add_child_node(new_file)
	return ""

func create_directory(path: String) -> String:
	var last_slash: int = path.rfind("/")
	if last_slash == -1:
		return "Invalid path"
		
	var dir_path: String = path.substr(0, last_slash)
	if dir_path == "":
		dir_path = "/"
		
	var dir_name: String = path.substr(last_slash + 1)
	if dir_name == "":
		return "Invalid directory name"
		
	var parent_dir: FileNode = get_node_at(dir_path)
	if parent_dir == null:
		return "Directory does not exist"
	if not parent_dir.is_directory:
		return "Not a directory"
	if parent_dir.has_child(dir_name):
		return "Directory already exists"
		
	var new_dir: FileNode = FileNode.new(dir_name, true)
	parent_dir.add_child_node(new_dir)
	return ""

func delete_node(path: String) -> String:
	if path == "/":
		return "Cannot delete root directory"
		
	var node: FileNode = get_node_at(path)
	if node == null:
		return "File or directory not found"
		
	var parent: FileNode = node.parent
	if parent != null:
		parent.remove_child_node(node.node_name)
		return ""
	return "Cannot delete node without parent"

func list_directory(path: String) -> Array:
	var node: FileNode = get_node_at(path)
	if node != null and node.is_directory:
		return node.children.values()
	return []

func read_file(path: String) -> String:
	var node: FileNode = get_node_at(path)
	if node == null:
		return "File not found"
	if node.is_directory:
		return "Is a directory"
	return node.content

func write_file(path: String, content: String) -> String:
	var node: FileNode = get_node_at(path)
	if node == null:
		return create_file(path, content)
	if node.is_directory:
		return "Is a directory"
	node.content = content
	node.size_bytes = content.length()
	return ""

func exists(path: String) -> bool:
	return get_node_at(path) != null

func is_dir(path: String) -> bool:
	var node: FileNode = get_node_at(path)
	return node != null and node.is_directory

func to_dict() -> Dictionary:
	return {
		"root": root.to_dict()
	}

static func from_dict(data: Dictionary) -> FileSystem:
	var fs = FileSystem.new()
	if data.has("root"):
		fs.root = FileNode.from_dict(data["root"])
	return fs
