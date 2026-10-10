extends Control

signal new_project_requested()
signal open_project_requested()
signal open_sample_requested()

func _ready() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0.07, 0.07, 0.09)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Subtle vignette-ish accent bar at top
	var accent_bar = ColorRect.new()
	accent_bar.color = Color(0.30, 0.55, 0.95, 0.9)
	accent_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	accent_bar.custom_minimum_size.y = 3
	accent_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(accent_bar)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var card = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.11, 0.11, 0.13, 0.97)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.border_color = Color(0.25, 0.27, 0.32)
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.content_margin_left = 36
	sb.content_margin_right = 36
	sb.content_margin_top = 32
	sb.content_margin_bottom = 28
	card.add_theme_stylebox_override("panel", sb)
	center.add_child(card)

	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size.x = 380
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)

	var title = Label.new()
	title.text = "DCLab"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Interactive IT Infrastructure Simulator"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.55, 0.55, 0.62))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	var sep1 = Control.new()
	sep1.custom_minimum_size.y = 28
	vbox.add_child(sep1)

	var btn_new = Button.new()
	btn_new.text = "  New Project"
	btn_new.custom_minimum_size = Vector2(0, 42)
	btn_new.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn_new.pressed.connect(func(): new_project_requested.emit())
	vbox.add_child(btn_new)

	var btn_open = Button.new()
	btn_open.text = "  Open Project…"
	btn_open.custom_minimum_size = Vector2(0, 42)
	btn_open.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn_open.pressed.connect(func(): open_project_requested.emit())
	vbox.add_child(btn_open)

	var sep2 = Control.new()
	sep2.custom_minimum_size.y = 18
	vbox.add_child(sep2)

	var sample_lbl = Label.new()
	sample_lbl.text = "  SAMPLE PROJECTS"
	sample_lbl.add_theme_font_size_override("font_size", 10)
	sample_lbl.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
	vbox.add_child(sample_lbl)

	var btn_sample = Button.new()
	btn_sample.text = "  Small Office"
	btn_sample.custom_minimum_size = Vector2(0, 42)
	btn_sample.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn_sample.pressed.connect(func(): open_sample_requested.emit())
	vbox.add_child(btn_sample)

	var sep3 = Control.new()
	sep3.custom_minimum_size.y = 24
	vbox.add_child(sep3)

	var version = Label.new()
	version.text = "v0.1.0 — scroll to zoom, middle-drag to pan the canvas"
	version.add_theme_font_size_override("font_size", 11)
	version.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(version)
