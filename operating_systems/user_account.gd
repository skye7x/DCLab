class_name UserAccount extends RefCounted

var username: String
var password_hash: String = ""
var is_root: bool = false
var home_directory: String
var shell: String = "/bin/dcsh"

func _init(p_username: String, p_is_root: bool = false):
	username = p_username
	is_root = p_is_root
	if is_root:
		home_directory = "/root"
	else:
		home_directory = "/home/" + username

func to_dict() -> Dictionary:
	return {
		"username": username,
		"password_hash": password_hash,
		"is_root": is_root,
		"home_directory": home_directory,
		"shell": shell
	}

static func from_dict(data: Dictionary) -> UserAccount:
	var account = UserAccount.new(data.get("username", "user"), data.get("is_root", false))
	account.password_hash = data.get("password_hash", "")
	account.home_directory = data.get("home_directory", "/home/" + account.username)
	account.shell = data.get("shell", "/bin/dcsh")
	return account
