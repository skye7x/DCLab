extends SceneTree

func _init():
	var engine = load("res://core/simulation/simulation_engine.gd").new()
	root.add_child(engine)
	var r = DeviceFactory.create("router", "r1", "Router1")
	r.add_interface("eth0")
	r.add_interface("eth1")
	r.network_interfaces["eth0"].configure("192.168.1.1", "255.255.255.0", "")
	r.network_interfaces["eth1"].configure("10.0.0.1", "255.255.255.0", "")
	r.is_powered_on = true
	engine.add_device(r)
	var c1 = DeviceFactory.create("pc", "pc1", "PC1")
	c1.network_interfaces["eth0"].configure("192.168.1.10", "255.255.255.0", "192.168.1.1")
	c1.is_powered_on = true
	engine.add_device(c1)
	var c2 = DeviceFactory.create("pc", "pc2", "PC2")
	c2.network_interfaces["eth0"].configure("10.0.0.10", "255.255.255.0", "10.0.0.1")
	c2.is_powered_on = true
	engine.add_device(c2)
	engine.create_connection("pc1", "eth0", "r1", "eth0")
	engine.create_connection("r1", "eth1", "pc2", "eth0")

	var os1 = c1.operating_system
	var cp = CommandProcessor.new("pc1", os1)
	cp.engine_ref = engine
	var out = cp.process_input("traceroute 10.0.0.10")
	print("--- traceroute output ---")
	print(out)
	print("--- ping output ---")
	print(cp.process_input("ping 10.0.0.10 -c 2"))

	var ok = out.contains("Router1") and out.contains("PC2") and out.contains("10.0.0.10")
	print("TRACEROUTE_TEST: " + ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
