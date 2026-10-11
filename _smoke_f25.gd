extends Node

func _ready() -> void:
	var engine: Node = SimEngine
	var srv = DeviceFactory.create("server", "srv1", "Server1")
	srv.network_interfaces["eth0"].configure("192.168.1.5", "255.255.255.0", "")
	srv.is_powered_on = true
	engine.add_device(srv)

	var os = srv.operating_system
	var cp_class = load("res://terminal/command_processor.gd")
	var cp = cp_class.new("srv1", os)
	cp.engine_ref = engine

	# Send an email
	var out1 = cp.process_input("email send user2@test.com \"Test Subject\" \"Hello World\"")
	print("email send: '", out1, "'")
	var ok1 = out1.contains("250 Mail")

	# List emails
	var out2 = cp.process_input("email list")
	print("email list: '", out2, "'")
	var ok2 = out2.contains("Hello World") or out2.contains("no emails")

	var ok = ok1 and ok2
	print("EMAIL_TEST: " + ("PASS" if ok else "FAIL"))
	get_tree().quit(0 if ok else 1)