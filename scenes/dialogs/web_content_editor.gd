extends Window

var _device_id: String = ""
var _file_list: ItemList
var _editor: TextEdit
var _status_label: Label
var _fs = null

func setup(p_device_id: String) -> void:
	_device_id = p_device_id
	if _file_list:
		_refresh_file_list()

func _ready() -> void:
	title = "Web Content Editor"
	size = Vector2i(720, 520)
	min_size = Vector2i(500, 350)
	unresizable = false

	var bg = ColorRect.new()
	bg.color = Color(0.07, 0.07, 0.09)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin = MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 10)
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# Header
	var header = Label.new()
	header.text = "Website files under /www/  (index.html is the default document)"
	header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	vbox.add_child(header)

	# Main area: file list + editor
	var hbox = HBoxContainer.new()
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(hbox)

	# Left: file list
	var left = VBoxContainer.new()
	left.custom_minimum_size.x = 180
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 4)
	hbox.add_child(left)

	var list_header = Label.new()
	list_header.text = "Files"
	list_header.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	left.add_child(list_header)

	_file_list = ItemList.new()
	_file_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_file_list.item_selected.connect(_on_file_selected)
	left.add_child(_file_list)

	var file_btns = HBoxContainer.new()
	file_btns.add_theme_constant_override("separation", 4)
	left.add_child(file_btns)

	var btn_new = Button.new()
	btn_new.text = "New"
	btn_new.tooltip_text = "Create a new file"
	btn_new.pressed.connect(_on_new_file)
	file_btns.add_child(btn_new)

	var btn_del = Button.new()
	btn_del.text = "Del"
	btn_del.tooltip_text = "Delete selected file"
	btn_del.pressed.connect(_on_delete_file)
	file_btns.add_child(btn_del)

	# Right: editor
	var right = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 4)
	hbox.add_child(right)

	var editor_header = Label.new()
	editor_header.text = "Content"
	editor_header.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	right.add_child(editor_header)

	_editor = TextEdit.new()
	_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_editor.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	_editor.add_theme_color_override("background_color", Color(0.08, 0.08, 0.1))
	right.add_child(_editor)

	# Bottom buttons
	var bot = HBoxContainer.new()
	bot.add_theme_constant_override("separation", 6)
	vbox.add_child(bot)

	var btn_save = Button.new()
	btn_save.text = " Save "
	btn_save.pressed.connect(_on_save)
	bot.add_child(btn_save)

	var btn_refresh = Button.new()
	btn_refresh.text = " Refresh "
	btn_refresh.pressed.connect(_refresh_file_list)
	bot.add_child(btn_refresh)

	_status_label = Label.new()
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
	bot.add_child(_status_label)

	close_requested.connect(queue_free)
	if _device_id != "":
		_refresh_file_list()

func _get_fs() -> bool:
	if _fs:
		return true
	var tree = Engine.get_main_loop()
	var engine = tree.root.get_node_or_null("SimEngine") if tree and tree.root else null
	var dev = engine.get_device(_device_id) if engine else null
	if dev and "operating_system" in dev and dev.operating_system:
		_fs = dev.operating_system.file_system
		return _fs != null
	return false

func _refresh_file_list() -> void:
	if not _file_list:
		return
	_file_list.clear()
	if not _get_fs():
		_set_status("No filesystem available", Color(0.9, 0.4, 0.4))
		return
	# Ensure /www exists
	if not _fs.exists("/www"):
		_fs.create_directory("/www")
	var files = _fs.list_directory("/www")
	for f in files:
		if f is FileNode and not f.is_directory:
			_file_list.add_item(f.node_name)
	if files.is_empty():
		_set_status("/www is empty — click New to create index.html", Color(0.7, 0.7, 0.5))
	else:
		_set_status("Loaded %d file(s)" % files.size(), Color(0.5, 0.8, 0.5))

func _on_file_selected(index: int) -> void:
	var fname = _file_list.get_item_text(index)
	if not _get_fs():
		return
	var full_path = "/www/" + fname
	if _fs.exists(full_path):
		var content = _fs.read_file(full_path)
		_editor.text = content
		_set_status("Editing " + full_path, Color(0.6, 0.7, 0.9))

func _on_new_file() -> void:
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "New file name (e.g. index.html, about.html):"
	var le = LineEdit.new()
	le.text = "index.html"
	dialog.add_child(le)
	# Position the LineEdit below the text
	le.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	le.position.y += 20
	dialog.confirmed.connect(func():
		var fname = le.text.strip_edges()
		if fname.is_empty():
			return
		if not _get_fs():
			return
		var full_path = "/www/" + fname
		if not _fs.exists("/www"):
			_fs.create_directory("/www")
		if _fs.exists(full_path):
			_set_status(fname + " already exists", Color(0.9, 0.6, 0.3))
			return
		_fs.write_file(full_path, "<!DOCTYPE html>\n<html>\n<head><title>New Page</title></head>\n<body>\n<h1>" + fname + "</h1>\n</body>\n</html>\n")
		_refresh_file_list()
		# Select the new file
		for i in range(_file_list.item_count):
			if _file_list.get_item_text(i) == fname:
				_file_list.select(i)
				_on_file_selected(i)
				break
	)
	add_child(dialog)
	dialog.popup_centered()

func _on_delete_file() -> void:
	var sel = _file_list.get_selected_items()
	if sel.is_empty():
		_set_status("Select a file to delete", Color(0.9, 0.6, 0.3))
		return
	var fname = _file_list.get_item_text(sel[0])
	if fname == "index.html":
		_set_status("Cannot delete index.html (default document)", Color(0.9, 0.4, 0.4))
		return
	if not _get_fs():
		return
	_fs.delete_node("/www/" + fname)
	_editor.text = ""
	_refresh_file_list()
	_set_status("Deleted " + fname, Color(0.7, 0.7, 0.5))

func _on_save() -> void:
	var sel = _file_list.get_selected_items()
	if sel.is_empty():
		_set_status("Select a file to save", Color(0.9, 0.6, 0.3))
		return
	var fname = _file_list.get_item_text(sel[0])
	if not _get_fs():
		return
	_fs.write_file("/www/" + fname, _editor.text)
	_set_status("Saved /www/" + fname, Color(0.5, 0.85, 0.5))

func _set_status(msg: String, color: Color) -> void:
	if _status_label:
		_status_label.text = msg
		_status_label.add_theme_color_override("font_color", color)
