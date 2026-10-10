class_name DeviceIcons
extends RefCounted

static func draw_device(canvas: CanvasItem, device_type: String, rect: Rect2, color: Color, is_powered: bool = true) -> void:
	var draw_color = color if is_powered else color.darkened(0.5)
	var status_color = Color.GREEN if is_powered else Color.RED
	
	match device_type:
		'pc':
			# Monitor screen
			var screen_rect = Rect2(rect.position.x, rect.position.y, rect.size.x, rect.size.y * 0.7)
			canvas.draw_rect(screen_rect, draw_color, true)
			canvas.draw_rect(screen_rect, Color.WHITE, false, 2.0)
			# Stand
			var stand_rect = Rect2(rect.position.x + rect.size.x * 0.4, rect.position.y + rect.size.y * 0.7, rect.size.x * 0.2, rect.size.y * 0.3)
			canvas.draw_rect(stand_rect, draw_color.darkened(0.2), true)
			# Power indicator
			canvas.draw_circle(Vector2(screen_rect.end.x - 6, screen_rect.end.y - 6), 3.0, status_color)
			
		'server':
			# Rack
			canvas.draw_rect(rect, draw_color, true)
			canvas.draw_rect(rect, Color.WHITE, false, 2.0)
			# Rack lines
			for i in range(1, 4):
				var y = rect.position.y + (rect.size.y / 4.0) * i
				canvas.draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Color.BLACK, 2.0)
			# Status
			canvas.draw_circle(Vector2(rect.position.x + 8, rect.position.y + 8), 3.0, status_color)
			
		'router':
			# Circle with arrows/cross
			var center = rect.get_center()
			var radius = min(rect.size.x, rect.size.y) / 2.0
			canvas.draw_circle(center, radius, draw_color)
			canvas.draw_arc(center, radius, 0, TAU, 32, Color.WHITE, 2.0)
			
			# Cross arrows
			var arrow_len = radius * 0.6
			canvas.draw_line(center - Vector2(0, arrow_len), center + Vector2(0, arrow_len), Color.WHITE, 2.0)
			canvas.draw_line(center - Vector2(arrow_len, 0), center + Vector2(arrow_len, 0), Color.WHITE, 2.0)
			canvas.draw_circle(center, 4.0, status_color)
			
		'switch':
			var switch_rect = Rect2(rect.position.x, rect.position.y + rect.size.y*0.25, rect.size.x, rect.size.y * 0.5)
			canvas.draw_rect(switch_rect, draw_color, true)
			canvas.draw_rect(switch_rect, Color.WHITE, false, 2.0)
			# Ports
			var port_size = switch_rect.size.x / 6.0
			for i in range(5):
				var px = switch_rect.position.x + port_size * i + port_size * 0.2
				var py = switch_rect.position.y + switch_rect.size.y * 0.3
				canvas.draw_rect(Rect2(px, py, port_size*0.6, port_size*0.6), Color.BLACK, true)
			canvas.draw_circle(Vector2(switch_rect.position.x + 6, switch_rect.position.y + 6), 2.0, status_color)
			
		'firewall':
			# Shield shape approximation using polygons
			var pts = PackedVector2Array([
				Vector2(rect.position.x, rect.position.y),
				Vector2(rect.end.x, rect.position.y),
				Vector2(rect.end.x, rect.position.y + rect.size.y * 0.6),
				Vector2(rect.position.x + rect.size.x * 0.5, rect.end.y),
				Vector2(rect.position.x, rect.position.y + rect.size.y * 0.6)
			])
			canvas.draw_polygon(pts, PackedColorArray([draw_color]))
			canvas.draw_polyline(pts, Color.WHITE, 2.0)
			canvas.draw_circle(Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + 10), 3.0, status_color)
			
		'storage':
			# Cylinder
			canvas.draw_rect(Rect2(rect.position.x, rect.position.y + rect.size.y * 0.1, rect.size.x, rect.size.y * 0.8), draw_color, true)
			
			# Draw ellipses (approximated with rects for simplicity here, ideally arc)
			var top_rect = Rect2(rect.position.x, rect.position.y, rect.size.x, rect.size.y * 0.2)
			var bot_rect = Rect2(rect.position.x, rect.end.y - rect.size.y * 0.2, rect.size.x, rect.size.y * 0.2)
			canvas.draw_rect(top_rect, draw_color.lightened(0.2), true)
			canvas.draw_rect(bot_rect, draw_color.darkened(0.2), true)
			
			canvas.draw_rect(rect, Color.WHITE, false, 2.0)
			canvas.draw_circle(Vector2(rect.position.x + 10, rect.position.y + rect.size.y * 0.5), 3.0, status_color)
			
		_:
			# Fallback generic box
			canvas.draw_rect(rect, draw_color, true)
			canvas.draw_rect(rect, Color.WHITE, false, 2.0)
			canvas.draw_circle(rect.get_center(), 4.0, status_color)
