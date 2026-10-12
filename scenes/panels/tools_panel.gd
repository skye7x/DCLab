extends PanelContainer

const MODE_POINTER := 0
const MODE_CONNECTOR := 1
const MODE_DELETE := 2

var _workspace_ref = null
var _btn_pointer: Button
var _btn_connector: Button
var _btn_delete: Button
var _status_label: Label

func _ready() -> void:
	custom_minimum_size.x = 150

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "TOOLS"
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color("#a1a1a1"))
	vbox.add_child(title)

	_btn_pointer = _make_mode_btn("pointer", "Pointer", "Select / move devices (V)", MODE_POINTER)
	_btn_connector = _make_mode_btn("link", "Connector", "Click source, then target to cable them (C)", MODE_CONNECTOR)
	_btn_delete = _make_mode_btn("trash", "Delete", "Click a device to remove it (X)", MODE_DELETE)

	vbox.add_child(_btn_pointer)
	vbox.add_child(_btn_connector)
	vbox.add_child(_btn_delete)

	vbox.add_child(HSeparator.new())

	_status_label = Label.new()
	_status_label.text = "Pointer mode"
	_status_label.add_theme_font_size_override("font_size", 10)
	_status_label.add_theme_color_override("font_color", Color("#8f8f8f"))
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_status_label)

	var hint := Label.new()
	hint.text = "Tip: select a device, press C, then click the target."
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color("#6f6f6f"))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(hint)

	if EventBus and EventBus.has_signal("tool_mode_changed"):
		EventBus.tool_mode_changed.connect(_on_tool_mode_changed)

	_sync_from_workspace()

func _make_mode_btn(icon_name: String, text: String, tip: String, mode: int) -> Button:
	var b := Button.new()
	var tex = load("res://resIcons/%s.svg" % icon_name)
	if tex:
		b.icon = tex
	b.text = text
	b.tooltip_text = tip
	b.toggle_mode = true
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_constant_override("icon_separation", 8)
	b.custom_minimum_size = Vector2(0, 30)
	b.pressed.connect(_on_mode_pressed.bind(mode))
	return b

func _on_mode_pressed(mode: int) -> void:
	if _workspace_ref and _workspace_ref.has_method("set_tool_mode"):
		_workspace_ref.set_tool_mode(mode)
	_sync_from_workspace()

func _on_tool_mode_changed(_mode: int) -> void:
	_sync_from_workspace()

func _sync_from_workspace() -> void:
	var mode := MODE_POINTER
	if _workspace_ref and _workspace_ref.has_method("get_tool_mode"):
		mode = _workspace_ref.get_tool_mode()
	_btn_pointer.set_pressed_no_signal(mode == MODE_POINTER)
	_btn_connector.set_pressed_no_signal(mode == MODE_CONNECTOR)
	_btn_delete.set_pressed_no_signal(mode == MODE_DELETE)
	match mode:
		MODE_CONNECTOR:
			_status_label.text = "Connector mode: click a device to start a cable, then click the target."
		MODE_DELETE:
			_status_label.text = "Delete mode: click a device to remove it."
		_:
			_status_label.text = "Pointer mode: click to select, drag to move."
