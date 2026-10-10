class_name Command extends RefCounted
# Base undo/redo command

var description: String = "Unknown Command"

func execute():
	pass

func undo():
	pass

func get_description() -> String:
	return description
