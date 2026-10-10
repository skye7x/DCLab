class_name StorageDevice
extends Device

var total_capacity_mb: int = 1024000
var used_mb: int = 0
var storage_type: String = "nas"
var operating_system = null
var shares: Array = []

func _init(p_id: String = "", p_name: String = "Storage") -> void:
	super(p_id, p_name, "storage")
	add_interface("eth0")
	operating_system = LinuxSystem.new(p_name, p_id)
	operating_system.os_name = "DCNAS"
	shares.append({"name": "public", "path": "/volume1/public", "size_mb": 102400, "read_only": false})
	used_mb = 102400

func get_usage_percent() -> float:
	if total_capacity_mb == 0:
		return 0.0
	return float(used_mb) / float(total_capacity_mb) * 100.0

func add_share(share_name: String, size_mb: int, read_only: bool = false) -> String:
	for s in shares:
		if s.name == share_name:
			return "Share already exists"
	if used_mb + size_mb > total_capacity_mb:
		return "Not enough free space"
	shares.append({"name": share_name, "path": "/volume1/" + share_name, "size_mb": size_mb, "read_only": read_only})
	used_mb += size_mb
	return ""

func remove_share(share_name: String) -> String:
	for i in range(shares.size()):
		if shares[i].name == share_name:
			used_mb = maxi(0, used_mb - int(shares[i].size_mb))
			shares.remove_at(i)
			return ""
	return "Share not found"

func get_share(share_name: String):
	for s in shares:
		if s.name == share_name:
			return s
	return null

func to_dict() -> Dictionary:
	var dict: Dictionary = super.to_dict()
	dict["total_capacity_mb"] = total_capacity_mb
	dict["used_mb"] = used_mb
	dict["storage_type"] = storage_type
	dict["shares"] = shares.duplicate(true)
	if operating_system:
		dict["operating_system"] = operating_system.to_dict()
	return dict

func from_dict(data: Dictionary) -> void:
	super.from_dict(data)
	total_capacity_mb = data.get("total_capacity_mb", 1024000)
	used_mb = data.get("used_mb", 0)
	storage_type = data.get("storage_type", "nas")
	shares = data.get("shares", [])
	if shares.is_empty():
		shares.append({"name": "public", "path": "/volume1/public", "size_mb": 102400, "read_only": false})
	if data.has("operating_system") and data["operating_system"] is Dictionary:
		operating_system = LinuxSystem.new(display_name, id)
		operating_system.from_dict(data["operating_system"])
	elif operating_system == null:
		operating_system = LinuxSystem.new(display_name, id)
		operating_system.os_name = "DCNAS"
