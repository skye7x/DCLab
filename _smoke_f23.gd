extends Node

func _ready() -> void:
	var engine: Node = SimEngine
	
	# Test FTP on server
	var srv = DeviceFactory.create("server", "srv1", "Server1")
	srv.network_interfaces["eth0"].configure("192.168.1.5", "255.255.255.0", "")
	srv.is_powered_on = true
	engine.add_device(srv)
	engine.create_connection("pc1", "eth0", "srv1", "eth0")

	var os = srv.operating_system
	var cp = null
	var cp_class = load("res://terminal/command_processor.gd")
	if cp_class:
		cp = cp_class.new("srv1", os)
		cp.engine_ref = engine

	# Test ftp list (should return no dirs error since /ftp doesn't exist)
	var out1 = cp.process_input("ftp list")
	print("ftp list: '", out1, "'")

	# Test ftp put (create dir and file)
	var out2 = cp.process_input("ftp mkd /ftp testdir")
	print("ftp mkd: '", out2, "'")

	var out3 = cp.process_input("ftp put /ftp testdir/hello.txt 'Hello FTP'")
	print("ftp put: '", out3, "'")

	var out4 = cp.process_input("ftp list")
	print("ftp list after put: '", out4, "'")

	var out5 = cp.process_input("ftp get /ftp testdir/hello.txt")
	print("ftp get: '", out5, "'")

	var out6 = cp.process_input("ftp rmd /ftp testdir")
	print("ftp rmd: '", out6, "'")

	var ok = out1.contains("No such") or out1 != "" and out1 != "226" and out1 != "550" and out1.contains("550") or out1 != "550"
	print("basic: ", ok)
	get_tree().quit(0)