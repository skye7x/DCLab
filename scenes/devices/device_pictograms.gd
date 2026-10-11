class_name DevicePictograms
extends RefCounted

## Draws professional network topology pictograms for devices
static func draw_device(canvas: CanvasItem, device_type: String, rect: Rect2, color: Color, is_powered: bool = true) -> void:
	var draw_color = color if is_powered else color.darkened(0.55)
	var stroke_color = Color(0.95, 0.95, 0.95, 0.9) if is_powered else Color(0.5, 0.5, 0.5, 0.7)
	var status_color = Color(0.2, 0.9, 0.3) if is_powered else Color(0.9, 0.25, 0.25)

	match device_type:
		"router":
			_draw_router_pictogram(canvas, rect, draw_color, stroke_color, status_color, is_powered)
		"switch":
			_draw_switch_pictogram(canvas, rect, draw_color, stroke_color, status_color, is_powered)
		"firewall":
			_draw_firewall_pictogram(canvas, rect, draw_color, stroke_color, status_color, is_powered)
		"server":
			_draw_server_pictogram(canvas, rect, draw_color, stroke_color, status_color, is_powered)
		"pc":
			_draw_pc_pictogram(canvas, rect, draw_color, stroke_color, status_color, is_powered)
		"storage":
			_draw_storage_pictogram(canvas, rect, draw_color, stroke_color, status_color, is_powered)
		_:
			_draw_generic_pictogram(canvas, rect, draw_color, stroke_color, status_color)


static func _draw_router_pictogram(canvas: CanvasItem, rect: Rect2, col: Color, stroke: Color, status: Color, is_powered: bool) -> void:
	var center = rect.get_center()
	var radius = minf(rect.size.x, rect.size.y) * 0.44

	# Router body: circular puck / disc
	canvas.draw_circle(center, radius, col)
	canvas.draw_arc(center, radius, 0.0, TAU, 36, stroke, 2.0)
	# Inner decorative ring
	canvas.draw_arc(center, radius * 0.85, 0.0, TAU, 36, col.lightened(0.2), 1.0)

	# 4 Standard Router In/Out Arrows
	var arr_len = radius * 0.62
	var head_len = radius * 0.22
	var head_w = radius * 0.16

	# Horizontal: Outward arrows (left and right pointing OUT)
	# Left pointing out
	_draw_arrow(canvas, center - Vector2(radius * 0.15, 0), center - Vector2(arr_len, 0), stroke, 2.0, head_len, head_w)
	# Right pointing out
	_draw_arrow(canvas, center + Vector2(radius * 0.15, 0), center + Vector2(arr_len, 0), stroke, 2.0, head_len, head_w)

	# Vertical: Inward arrows (top and bottom pointing IN toward center)
	# Top pointing in
	_draw_arrow(canvas, center - Vector2(0, arr_len), center - Vector2(0, radius * 0.18), stroke, 2.0, head_len, head_w)
	# Bottom pointing in
	_draw_arrow(canvas, center + Vector2(0, arr_len), center + Vector2(0, radius * 0.18), stroke, 2.0, head_len, head_w)

	# Center routing core
	canvas.draw_circle(center, 4.0, col.darkened(0.4))
	canvas.draw_circle(center, 2.5, status)


static func _draw_switch_pictogram(canvas: CanvasItem, rect: Rect2, col: Color, stroke: Color, status: Color, is_powered: bool) -> void:
	# Standard network switch: rectangular chassis with opposing bidirectional switching arrows
	var h = rect.size.y * 0.58
	var sw_rect = Rect2(rect.position.x, rect.position.y + (rect.size.y - h) * 0.5, rect.size.x, h)

	# Chassis body
	canvas.draw_rect(sw_rect, col, true)
	canvas.draw_rect(sw_rect, stroke, false, 2.0)

	# Top face shading
	var top_strip = Rect2(sw_rect.position.x + 2, sw_rect.position.y + 2, sw_rect.size.x - 4, 3)
	canvas.draw_rect(top_strip, col.lightened(0.25), true)

	# Switching arrows (2 bidirectional horizontal tracks)
	var left_x = sw_rect.position.x + sw_rect.size.x * 0.18
	var right_x = sw_rect.end.x - sw_rect.size.x * 0.18
	var y1 = sw_rect.position.y + sw_rect.size.y * 0.32
	var y2 = sw_rect.position.y + sw_rect.size.y * 0.68

	# Top arrow: pointing right ->
	_draw_arrow(canvas, Vector2(left_x, y1), Vector2(right_x, y1), stroke, 2.0, 7.0, 5.0)
	# Bottom arrow: pointing left <-
	_draw_arrow(canvas, Vector2(right_x, y2), Vector2(left_x, y2), stroke, 2.0, 7.0, 5.0)

	# Port status LEDs along the bottom edge
	var led_count = 6
	var led_spacing = sw_rect.size.x / (led_count + 1)
	for i in range(led_count):
		var lx = sw_rect.position.x + led_spacing * (i + 1)
		var ly = sw_rect.end.y - 4
		var led_col = status if is_powered and (i % 2 == 0 or i == 1) else Color(0.2, 0.3, 0.2)
		canvas.draw_rect(Rect2(lx - 2, ly - 2, 4, 3), led_col, true)


static func _draw_firewall_pictogram(canvas: CanvasItem, rect: Rect2, col: Color, stroke: Color, status: Color, is_powered: bool) -> void:
	# Standard network firewall: A brick wall (masonry pattern)
	var pad = 4.0
	var wall = Rect2(rect.position.x + pad, rect.position.y + pad, rect.size.x - pad * 2.0, rect.size.y - pad * 2.0)

	# Wall background (brick red/orange body)
	canvas.draw_rect(wall, col, true)
	canvas.draw_rect(wall, stroke, false, 2.0)

	var mortar_col = stroke.darkened(0.15)
	mortar_col.a = 0.85
	var num_rows = 4
	var row_h = wall.size.y / num_rows

	# Horizontal mortar lines
	for r in range(1, num_rows):
		var y = wall.position.y + r * row_h
		canvas.draw_line(Vector2(wall.position.x, y), Vector2(wall.end.x, y), mortar_col, 1.5)

	# Vertical staggered brick joints
	for r in range(num_rows):
		var y_top = wall.position.y + r * row_h
		var y_bot = y_top + row_h
		var offset = (r % 2) * 0.5
		var bricks_in_row = 3
		for b in range(1, bricks_in_row + 1):
			var x = wall.position.x + ((float(b) - offset) / bricks_in_row) * wall.size.x
			if x > wall.position.x + 2 and x < wall.end.x - 2:
				canvas.draw_line(Vector2(x, y_top), Vector2(x, y_bot), mortar_col, 1.5)

	# Security indicator badge / shield crest at center
	var badge_w = 12.0
	var badge_h = 14.0
	var badge_center = wall.get_center()
	var badge_pts = PackedVector2Array([
		Vector2(badge_center.x - badge_w / 2.0, badge_center.y - badge_h / 2.0),
		Vector2(badge_center.x + badge_w / 2.0, badge_center.y - badge_h / 2.0),
		Vector2(badge_center.x + badge_w / 2.0, badge_center.y + 1.0),
		Vector2(badge_center.x, badge_center.y + badge_h / 2.0),
		Vector2(badge_center.x - badge_w / 2.0, badge_center.y + 1.0)
	])
	canvas.draw_polygon(badge_pts, PackedColorArray([Color(0.1, 0.12, 0.16, 0.95)]))
	canvas.draw_polyline(badge_pts, stroke, 1.5)
	canvas.draw_circle(badge_center + Vector2(0, -1), 2.5, status)


static func _draw_server_pictogram(canvas: CanvasItem, rect: Rect2, col: Color, stroke: Color, status: Color, is_powered: bool) -> void:
	# Standard server: multi-unit rack server chassis with drive bays and status panel
	var pad_x = 4.0
	var srv_rect = Rect2(rect.position.x + pad_x, rect.position.y + 2, rect.size.x - pad_x * 2.0, rect.size.y - 4.0)

	# Chassis body
	canvas.draw_rect(srv_rect, col, true)
	canvas.draw_rect(srv_rect, stroke, false, 2.0)

	# Rack ears (left/right brackets)
	var ear_w = 3.0
	canvas.draw_rect(Rect2(srv_rect.position.x - ear_w, srv_rect.position.y + 4, ear_w, 8), stroke, true)
	canvas.draw_rect(Rect2(srv_rect.position.x - ear_w, srv_rect.end.y - 12, ear_w, 8), stroke, true)
	canvas.draw_rect(Rect2(srv_rect.end.x, srv_rect.position.y + 4, ear_w, 8), stroke, true)
	canvas.draw_rect(Rect2(srv_rect.end.x, srv_rect.end.y - 12, ear_w, 8), stroke, true)

	# 3 Rack unit bays
	var bay_count = 3
	var bay_h = (srv_rect.size.y - 8) / bay_count
	for i in range(bay_count):
		var by = srv_rect.position.y + 4 + i * bay_h
		var b_rect = Rect2(srv_rect.position.x + 4, by + 1, srv_rect.size.x - 8, bay_h - 2)
		# Drive sled background
		canvas.draw_rect(b_rect, col.darkened(0.35), true)
		canvas.draw_rect(b_rect, col.lightened(0.2), false, 1.0)

		# Drive handles
		canvas.draw_line(Vector2(b_rect.position.x + 6, b_rect.get_center().y), Vector2(b_rect.end.x - 22, b_rect.get_center().y), stroke, 1.5)

		# Sled LEDs
		var led_c = status if is_powered else Color(0.4, 0.4, 0.4)
		canvas.draw_circle(Vector2(b_rect.end.x - 12, b_rect.get_center().y), 2.0, led_c)
		canvas.draw_circle(Vector2(b_rect.end.x - 5, b_rect.get_center().y), 1.5, Color.CYAN if is_powered else Color.TRANSPARENT)


static func _draw_pc_pictogram(canvas: CanvasItem, rect: Rect2, col: Color, stroke: Color, status: Color, is_powered: bool) -> void:
	# Standard PC / workstation: monitor with inner display, stand base, and mini desktop chassis
	var m_w = rect.size.x * 0.88
	var m_h = rect.size.y * 0.58
	var m_x = rect.position.x + (rect.size.x - m_w) * 0.5
	var m_y = rect.position.y + 3.0
	var monitor_rect = Rect2(m_x, m_y, m_w, m_h)

	# Monitor outer frame
	canvas.draw_rect(monitor_rect, col, true)
	canvas.draw_rect(monitor_rect, stroke, false, 2.0)

	# Inner display screen (dark glass screen)
	var screen_rect = monitor_rect.grow(-3.5)
	var screen_bg = Color(0.06, 0.08, 0.12) if is_powered else Color(0.04, 0.04, 0.05)
	canvas.draw_rect(screen_rect, screen_bg, true)

	# Screen prompt graphic: terminal '>' and cursor line
	if is_powered:
		var p_x = screen_rect.position.x + 4.0
		var p_y = screen_rect.position.y + screen_rect.size.y * 0.45
		# '>' prompt symbol
		canvas.draw_line(Vector2(p_x, p_y - 3), Vector2(p_x + 4, p_y), Color(0.3, 0.85, 0.4), 1.5)
		canvas.draw_line(Vector2(p_x + 4, p_y), Vector2(p_x, p_y + 3), Color(0.3, 0.85, 0.4), 1.5)
		# Horizontal command line / cursor
		canvas.draw_line(Vector2(p_x + 7, p_y), Vector2(p_x + 18, p_y), Color(0.7, 0.9, 0.8), 1.5)
		canvas.draw_line(Vector2(p_x + 4, p_y + 6), Vector2(p_x + 24, p_y + 6), Color(0.4, 0.6, 0.8), 1.0)

	# Power indicator LED on monitor bezel
	canvas.draw_circle(Vector2(monitor_rect.end.x - 5, monitor_rect.end.y - 2.5), 1.5, status)

	# Monitor neck / stand
	var stand_w = 6.0
	var stand_h = rect.size.y * 0.18
	var stand_rect = Rect2(rect.get_center().x - stand_w / 2.0, monitor_rect.end.y, stand_w, stand_h)
	canvas.draw_rect(stand_rect, col.darkened(0.25), true)
	canvas.draw_rect(stand_rect, stroke, false, 1.0)

	# Monitor foot base
	var base_w = rect.size.x * 0.52
	var base_h = 3.5
	var base_rect = Rect2(rect.get_center().x - base_w / 2.0, stand_rect.end.y, base_w, base_h)
	canvas.draw_rect(base_rect, stroke, true)

	# Keyboard silhouette line under the base
	var kb_w = rect.size.x * 0.64
	var kb_y = rect.end.y - 2.0
	canvas.draw_line(Vector2(rect.get_center().x - kb_w / 2.0, kb_y), Vector2(rect.get_center().x + kb_w / 2.0, kb_y), col.lightened(0.2), 2.0)


static func _draw_storage_pictogram(canvas: CanvasItem, rect: Rect2, col: Color, stroke: Color, status: Color, is_powered: bool) -> void:
	# Standard storage / NAS: cylindrical multi-disk database / disk platter stack
	var pad_x = 6.0
	var w = rect.size.x - pad_x * 2.0
	var h = rect.size.y - 6.0
	var sx = rect.position.x + pad_x
	var sy = rect.position.y + 3.0

	var disk_count = 3
	var disk_h = h / disk_count
	var ellipse_h = disk_h * 0.45

	for i in range(disk_count):
		var dy = sy + i * disk_h
		var d_rect = Rect2(sx, dy + ellipse_h * 0.5, w, disk_h - ellipse_h * 0.5)

		# Disk barrel
		canvas.draw_rect(d_rect, col, true)
		canvas.draw_line(Vector2(sx, d_rect.position.y), Vector2(sx, d_rect.end.y), stroke, 2.0)
		canvas.draw_line(Vector2(sx + w, d_rect.position.y), Vector2(sx + w, d_rect.end.y), stroke, 2.0)

		# Top ellipse of each disk
		var center_top = Vector2(sx + w * 0.5, dy + ellipse_h * 0.5)
		_draw_ellipse(canvas, center_top, w * 0.5, ellipse_h * 0.5, col.lightened(0.2), stroke, 1.5)

		# Disk activity light
		var led_y = dy + disk_h * 0.65
		canvas.draw_circle(Vector2(sx + w - 8, led_y), 2.0, status if is_powered else Color(0.3, 0.3, 0.3))

	# Bottom ellipse border
	var center_bot = Vector2(sx + w * 0.5, sy + h)
	_draw_ellipse_arc(canvas, center_bot, w * 0.5, ellipse_h * 0.5, stroke, 2.0)


static func _draw_generic_pictogram(canvas: CanvasItem, rect: Rect2, col: Color, stroke: Color, status: Color) -> void:
	canvas.draw_rect(rect, col, true)
	canvas.draw_rect(rect, stroke, false, 2.0)
	canvas.draw_circle(rect.get_center(), 4.0, status)


# Helper to draw an arrow with line and triangle arrowhead
static func _draw_arrow(canvas: CanvasItem, from: Vector2, to: Vector2, col: Color, width: float, head_len: float, head_w: float) -> void:
	var dir = (to - from).normalized()
	if dir.length_squared() < 0.001:
		return
	var normal = Vector2(-dir.y, dir.x)
	var arrow_tip = to
	var arrow_base = to - dir * head_len

	# Shaft
	canvas.draw_line(from, arrow_base, col, width)

	# Head triangle
	var pts = PackedVector2Array([
		arrow_tip,
		arrow_base + normal * (head_w * 0.5),
		arrow_base - normal * (head_w * 0.5)
	])
	canvas.draw_polygon(pts, PackedColorArray([col]))


# Helper to draw filled ellipse with outline
static func _draw_ellipse(canvas: CanvasItem, center: Vector2, rx: float, ry: float, fill_col: Color, stroke_col: Color, stroke_w: float) -> void:
	var segments = 24
	var pts = PackedVector2Array()
	for i in range(segments):
		var a = (float(i) / segments) * TAU
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	canvas.draw_polygon(pts, PackedColorArray([fill_col]))
	pts.append(pts[0])
	canvas.draw_polyline(pts, stroke_col, stroke_w)


# Helper to draw bottom half of ellipse arc
static func _draw_ellipse_arc(canvas: CanvasItem, center: Vector2, rx: float, ry: float, stroke_col: Color, stroke_w: float) -> void:
	var segments = 16
	var pts = PackedVector2Array()
	for i in range(segments + 1):
		var a = (float(i) / segments) * PI
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	canvas.draw_polyline(pts, stroke_col, stroke_w)
