class_name CommandHistory extends RefCounted

var _undo_stack: Array = []
var _redo_stack: Array = []
var _max_history: int = 100

func push_command(cmd: Command):
	cmd.execute()
	_undo_stack.append(cmd)
	_redo_stack.clear()
	
	if _undo_stack.size() > _max_history:
		_undo_stack.pop_front()

func undo() -> bool:
	if not can_undo():
		return false
		
	var cmd: Command = _undo_stack.pop_back()
	cmd.undo()
	_redo_stack.append(cmd)
	return true

func redo() -> bool:
	if not can_redo():
		return false
		
	var cmd: Command = _redo_stack.pop_back()
	cmd.execute()
	_undo_stack.append(cmd)
	return true

func can_undo() -> bool:
	return _undo_stack.size() > 0

func can_redo() -> bool:
	return _redo_stack.size() > 0

func clear():
	_undo_stack.clear()
	_redo_stack.clear()

func get_undo_description() -> String:
	if can_undo():
		return _undo_stack.back().get_description()
	return ""

func get_redo_description() -> String:
	if can_redo():
		return _redo_stack.back().get_description()
	return ""

# ---------------------------------------------------------
# Concrete Commands
# ---------------------------------------------------------

static func _get_engine():
	var tree = Engine.get_main_loop()
	if tree and tree.root and tree.root.has_node("SimEngine"):
		return tree.root.get_node("SimEngine")
	return null

static func _restore_interface_links(engine, link: EthernetLink) -> void:
	var src_dev = engine.get_device(link.source_device_id)
	if src_dev and src_dev.network_interfaces.has(link.source_interface_name):
		src_dev.network_interfaces[link.source_interface_name].is_linked = true
		src_dev.network_interfaces[link.source_interface_name].link = link
	var dst_dev = engine.get_device(link.dest_device_id)
	if dst_dev and dst_dev.network_interfaces.has(link.dest_interface_name):
		dst_dev.network_interfaces[link.dest_interface_name].is_linked = true
		dst_dev.network_interfaces[link.dest_interface_name].link = link

static func _emit_created(link: EthernetLink) -> void:
	var tree = Engine.get_main_loop()
	var bus = tree.root.get_node_or_null("/root/EventBus") if tree and tree.root else null
	if bus and bus.has_signal("connection_created"):
		bus.connection_created.emit(link)

class AddDeviceCommand extends Command:
	var device_data: Dictionary
	var device_id: String
	
	func _init(p_device):
		device_data = p_device.to_dict()
		device_id = p_device.id
		description = "Add " + p_device.display_name
		
	func execute():
		var engine = CommandHistory._get_engine()
		if engine and engine.has_method("add_device"):
			# Assuming ProjectSerializer is available globally or via class_name
			var dev = ProjectSerializer._create_device_from_dict(device_data)
			engine.add_device(dev)
			
	func undo():
		var engine = CommandHistory._get_engine()
		if engine and engine.has_method("remove_device"):
			engine.remove_device(device_id)

class RemoveDeviceCommand extends Command:
	var device_data: Dictionary
	var device_id: String
	var connection_data: Array = []
	
	func _init(p_device, p_connections: Array = []):
		device_data = p_device.to_dict()
		device_id = p_device.id
		description = "Remove " + p_device.display_name
		for link in p_connections:
			if link.source_device_id == device_id or link.dest_device_id == device_id:
				connection_data.append(link.to_dict())
				
	func execute():
		var engine = CommandHistory._get_engine()
		if engine and engine.has_method("remove_device"):
			engine.remove_device(device_id)
			
	func undo():
		var engine = CommandHistory._get_engine()
		if engine and engine.has_method("add_device"):
			var dev = ProjectSerializer._create_device_from_dict(device_data)
			engine.add_device(dev)
			for l_data in connection_data:
				var link = EthernetLink.new(
					l_data.get("id", ""),
					l_data.get("source_device_id", ""),
					l_data.get("source_interface_name", ""),
					l_data.get("dest_device_id", ""),
					l_data.get("dest_interface_name", "")
				)
				link.from_dict(l_data)
				engine.connections.append(link)
				CommandHistory._restore_interface_links(engine, link)

class MoveDeviceCommand extends Command:
	var device_id: String
	var old_pos: Vector2
	var new_pos: Vector2
	
	func _init(p_device_id: String, p_old: Vector2, p_new: Vector2):
		device_id = p_device_id
		old_pos = p_old
		new_pos = p_new
		description = "Move Device"
		
	func execute():
		var engine = CommandHistory._get_engine()
		if engine and engine.devices.has(device_id):
			engine.devices[device_id].position = new_pos
			
	func undo():
		var engine = CommandHistory._get_engine()
		if engine and engine.devices.has(device_id):
			engine.devices[device_id].position = old_pos

class AddConnectionCommand extends Command:
	var link_data: Dictionary
	var link_id: String
	
	func _init(p_link):
		link_data = p_link.to_dict()
		link_id = p_link.id
		description = "Connect devices"
		
	func execute():
		var engine = CommandHistory._get_engine()
		if engine:
			var link = EthernetLink.new(
				link_data.get("id", ""),
				link_data.get("source_device_id", ""),
				link_data.get("source_interface_name", ""),
				link_data.get("dest_device_id", ""),
				link_data.get("dest_interface_name", "")
			)
			link.from_dict(link_data)
			engine.connections.append(link)
			CommandHistory._restore_interface_links(engine, link)
			CommandHistory._emit_created(link)
			
	func undo():
		var engine = CommandHistory._get_engine()
		if engine and engine.has_method("remove_connection"):
			engine.remove_connection(link_id)

class RemoveConnectionCommand extends Command:
	var link_data: Dictionary
	var link_id: String
	
	func _init(p_link):
		link_data = p_link.to_dict()
		link_id = p_link.id
		description = "Disconnect devices"
		
	func execute():
		var engine = CommandHistory._get_engine()
		if engine and engine.has_method("remove_connection"):
			engine.remove_connection(link_id)
			
	func undo():
		var engine = CommandHistory._get_engine()
		if engine:
			var link = EthernetLink.new(
				link_data.get("id", ""),
				link_data.get("source_device_id", ""),
				link_data.get("source_interface_name", ""),
				link_data.get("dest_device_id", ""),
				link_data.get("dest_interface_name", "")
			)
			link.from_dict(link_data)
			engine.connections.append(link)
			CommandHistory._restore_interface_links(engine, link)
			CommandHistory._emit_created(link)

class RenameDeviceCommand extends Command:
	var device_id: String
	var old_name: String
	var new_name: String
	
	func _init(p_device_id: String, p_old: String, p_new: String):
		device_id = p_device_id
		old_name = p_old
		new_name = p_new
		description = "Rename to " + p_new
		
	func execute():
		var engine = CommandHistory._get_engine()
		if engine and engine.devices.has(device_id):
			engine.devices[device_id].display_name = new_name
			
	func undo():
		var engine = CommandHistory._get_engine()
		if engine and engine.devices.has(device_id):
			engine.devices[device_id].display_name = old_name
