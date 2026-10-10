class_name DeviceFactory
extends RefCounted

const TYPE_DEFS := {
	"router": {"label": "Router", "color": Color(0.85, 0.45, 0.2)},
	"switch": {"label": "Switch", "color": Color(0.2, 0.65, 0.6)},
	"firewall": {"label": "Firewall", "color": Color(0.8, 0.25, 0.3)},
	"pc": {"label": "PC", "color": Color(0.25, 0.55, 0.8)},
	"server": {"label": "Server", "color": Color(0.35, 0.55, 0.85)},
	"storage": {"label": "NAS / Storage", "color": Color(0.65, 0.4, 0.75)},
}

static func get_label(type: String) -> String:
	return TYPE_DEFS.get(type, {}).get("label", type.capitalize())

static func get_color(type: String) -> Color:
	return TYPE_DEFS.get(type, {}).get("color", Color(0.5, 0.5, 0.5))

static func create(type: String, id: String, name: String = "") -> Device:
	var device: Device = null
	var dev_name = name if name != "" else get_label(type)
	match type:
		"router":
			device = RouterDevice.new(id, dev_name)
		"switch":
			device = SwitchDevice.new(id, dev_name)
		"firewall":
			device = FirewallDevice.new(id, dev_name)
		"pc":
			device = Computer.new(id, dev_name, "pc")
			device.add_interface("eth0")
			device.install_os("DCLinux")
		"server":
			device = Server.new(id, dev_name)
			device.add_interface("eth0")
			device.install_os("DCLinux")
			var http = HttpService.new()
			device.add_service(http)
			http.start()
		"storage":
			device = StorageDevice.new(id, dev_name)
	return device
