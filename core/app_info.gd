extends RefCounted
## Single source of truth for the running app's version.

const VERSION_PATH := "res://gdVer.dclver"
const REMOTE_URL := "https://raw.githubusercontent.com/skye7x/DCLab/main/version.json"

static func version() -> String:
	var f = FileAccess.open(VERSION_PATH, FileAccess.READ)
	if f == null:
		return "0.0.0"
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if data is Dictionary and data.has("version"):
		return str(data["version"])
	return "0.0.0"

static func display_version() -> String:
	return "v" + version()
