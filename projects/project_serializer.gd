class_name ProjectSerializer extends RefCounted

static func serialize_project(engine, project: ProjectData) -> Dictionary:
	var data = {
		"version": 1,
		"project": project.to_dict(),
		"devices": [],
		"connections": []
	}
	
	if engine:
		for dev in engine.devices.values():
			data["devices"].append(dev.to_dict())
			
		for link in engine.connections:
			data["connections"].append(link.to_dict())
			
	return data

static func deserialize_project(data: Dictionary, engine) -> ProjectData:
	if engine and engine.has_method("clear"):
		engine.clear()
		
	var project = ProjectData.from_dict(data.get("project", {}))
	
	if engine:
		if data.has("devices"):
			for d_data in data["devices"]:
				var dev = _create_device_from_dict(d_data)
				if dev:
					engine.add_device(dev)
					
		if data.has("connections"):
			for l_data in data["connections"]:
				var link = EthernetLink.new(
					l_data.get("id", ""),
					l_data.get("source_device_id", ""),
					l_data.get("source_interface_name", ""),
					l_data.get("dest_device_id", ""),
					l_data.get("dest_interface_name", "")
				)
				link.from_dict(l_data)
				engine.connections.append(link)
				
				# Link interfaces
				var src_dev = engine.get_device(link.source_device_id)
				if src_dev and src_dev.network_interfaces.has(link.source_interface_name):
					src_dev.network_interfaces[link.source_interface_name].is_linked = true
					src_dev.network_interfaces[link.source_interface_name].link = link
				var dst_dev = engine.get_device(link.dest_device_id)
				if dst_dev and dst_dev.network_interfaces.has(link.dest_interface_name):
					dst_dev.network_interfaces[link.dest_interface_name].is_linked = true
					dst_dev.network_interfaces[link.dest_interface_name].link = link
				
				var tree = Engine.get_main_loop()
				if tree and tree.root and tree.root.has_node("EventBus"):
					tree.root.get_node("EventBus").connection_created.emit(link)
				
	return project

static func _create_device_from_dict(data: Dictionary) -> Device:
	var dev: Device = null
	var d_type = data.get("device_type", "")
	var d_id = data.get("id", "")
	var d_name = data.get("display_name", "Device")
	
	match d_type:
		"pc":
			dev = Computer.new(d_id, d_name, "pc")
		"server":
			dev = Server.new(d_id, d_name)
		"router":
			dev = RouterDevice.new(d_id, d_name)
		"switch":
			dev = SwitchDevice.new(d_id, d_name)
		"firewall":
			dev = FirewallDevice.new(d_id, d_name)
		"storage":
			dev = StorageDevice.new(d_id, d_name)
		_:
			dev = Device.new(d_id, d_name, d_type)
			
	if dev:
		dev.from_dict(data)
		
	return dev
