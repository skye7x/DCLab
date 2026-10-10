class_name ProjectData extends RefCounted

var version: int = 1
var project_name: String = "Untitled Project"
var created_at: String = ""
var modified_at: String = ""
var metadata: Dictionary = {}

func _init(p_name: String = "Untitled Project"):
	project_name = p_name
	var time_dict = Time.get_datetime_dict_from_system()
	created_at = "%d-%02d-%02dT%02d:%02d:%02d" % [time_dict.year, time_dict.month, time_dict.day, time_dict.hour, time_dict.minute, time_dict.second]
	modified_at = created_at

func to_dict() -> Dictionary:
	return {
		"version": version,
		"project_name": project_name,
		"created_at": created_at,
		"modified_at": modified_at,
		"metadata": metadata
	}

static func from_dict(data: Dictionary) -> ProjectData:
	var proj = ProjectData.new(data.get("project_name", "Untitled Project"))
	proj.version = data.get("version", 1)
	proj.created_at = data.get("created_at", proj.created_at)
	proj.modified_at = data.get("modified_at", proj.modified_at)
	proj.metadata = data.get("metadata", {})
	return proj
