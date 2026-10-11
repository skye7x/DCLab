extends Node

func _ready() -> void:
	var engine: Node = SimEngine
	var pc1 = DeviceFactory.create("pc", "pc1", "PC1")
	pc1.network_interfaces["eth0"].configure("192.168.1.10", "255.255.255.0", "")
	pc1.is_powered_on = true
	engine.add_device(pc1)

	var os = pc1.operating_system
	var cp_class = load("res://terminal/command_processor.gd")
	var cp = cp_class.new("pc1", os)
	cp.engine_ref = engine

	# Add a group
	var out1 = cp.process_input("groups add admins")
	print("groups add: '", out1, "'")
	var ok1 = os.groups.has("admins")

	# List groups
	var out2 = cp.process_input("groups")
	print("groups list: '", out2, "'")
	var ok2 = out2.contains("admins")

	# Add another group
	var out3 = cp.process_input("groups add developers")
	print("groups add2: '", out3, "'")
	var ok3 = os.groups.has("developers")

	# List groups again
	var out4 = cp.process_input("groups")
	print("groups list2: '", out4, "'")
	var ok4 = out4.contains("developers") and out4.contains("admins")

	# Remove a group
	var out5 = cp.process_input("groups rm admins")
	print("groups rm: '", out5, "'")
	var ok5 = not os.groups.has("admins")

	var ok = ok1 and ok2 and ok3 and ok4 and ok5
	print("GROUPS_TEST: " + ("PASS" if ok else "FAIL"))
	get_tree().quit(0 if ok else 1)