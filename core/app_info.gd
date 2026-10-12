extends RefCounted
## Single source of truth for the running app's version.

const VERSION_PATH := "res://gdVer.dclver"
const REMOTE_URL := "https://raw.githubusercontent.com/skye7x/DCLab/main/version.json"
## Last resort only: used when gdVer.dclver is missing (export include_filter
## must contain "*.dclver"). Keep in sync with gdVer.dclver when bumping.
const FALLBACK_VERSION := "0.4.0"

static func version() -> String:
	var f = FileAccess.open(VERSION_PATH, FileAccess.READ)
	if f == null:
		push_warning("AppInfo: %s unreadable, using FALLBACK_VERSION %s" % [VERSION_PATH, FALLBACK_VERSION])
		return FALLBACK_VERSION
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if data is Dictionary and data.has("version"):
		return str(data["version"])
	push_warning("AppInfo: %s has no version field, using FALLBACK_VERSION %s" % [VERSION_PATH, FALLBACK_VERSION])
	return FALLBACK_VERSION

static func display_version() -> String:
	return "v" + version()
