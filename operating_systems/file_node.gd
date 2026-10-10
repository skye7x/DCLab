class_name FileNode extends RefCounted

var node_name: String
var is_directory: bool
var content: String = ""
var children: Dictionary = {}
var parent: FileNode = null
var permissions: String = "rwxr-xr-x"
var owner: String = "root"
var size_bytes: int = 0

func _init(p_name: String, p_is_dir: bool = false, p_content: String = ""):
	node_name = p_name
	is_directory = p_is_dir
	content = p_content
	if not is_directory:
		size_bytes = content.length()

func add_child_node(child: FileNode) -> bool:
	if not is_directory:
		return false
	if children.has(child.node_name):
		return false
	children[child.node_name] = child
	child.parent = self
	return true

func remove_child_node(name: String) -> bool:
	if not is_directory:
		return false
	if children.has(name):
		children.erase(name)
		return true
	return false

func get_child(name: String) -> FileNode:
	if is_directory and children.has(name):
		return children[name]
	return null

func has_child(name: String) -> bool:
	return is_directory and children.has(name)

func get_full_path() -> String:
	var path: String = node_name
	var curr: FileNode = parent
	while curr != null:
		if curr.node_name == "/":
			path = "/" + path
		else:
			path = curr.node_name + "/" + path
		curr = curr.parent
	if node_name == "/":
		return "/"
	return path

func to_dict() -> Dictionary:
	var dict := {
		"node_name": node_name,
		"is_directory": is_directory,
		"content": content,
		"permissions": permissions,
		"owner": owner,
		"size_bytes": size_bytes,
		"children": {}
	}
	if is_directory:
		for child_name in children:
			dict["children"][child_name] = children[child_name].to_dict()
	return dict

static func from_dict(data: Dictionary) -> FileNode:
	var node = FileNode.new(data.get("node_name", ""), data.get("is_directory", false), data.get("content", ""))
	node.permissions = data.get("permissions", "rwxr-xr-x")
	node.owner = data.get("owner", "root")
	node.size_bytes = data.get("size_bytes", 0)
	
	if node.is_directory and data.has("children"):
		var child_dict: Dictionary = data["children"]
		for child_name in child_dict:
			var child_node = FileNode.from_dict(child_dict[child_name])
			node.add_child_node(child_node)
			
	return node
