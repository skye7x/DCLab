class_name ArpTable
extends RefCounted

var entries: Dictionary = {}

func add_entry(ip: String, mac: String) -> void:
	entries[ip] = mac

func lookup(ip: String) -> String:
	return entries.get(ip, "")

func remove_entry(ip: String) -> void:
	if entries.has(ip):
		entries.erase(ip)

func clear() -> void:
	entries.clear()

func get_all_entries() -> Dictionary:
	return entries.duplicate()

func to_dict() -> Dictionary:
	return {"entries": entries.duplicate()}
