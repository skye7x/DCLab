extends Node2D
class_name GridRenderer

var grid_size: int = 32
var grid_color: Color = Color(1, 1, 1, 0.045)
var major_grid_every: int = 4
var major_grid_color: Color = Color(1, 1, 1, 0.09)
var axis_color: Color = Color(0.196, 0.569, 1.0, 0.35)
var visible_grid: bool = true
var adaptive_grid: bool = true

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not visible_grid:
		return

	var vp = get_viewport_rect()
	var cam = get_viewport().get_camera_2d()
	if not cam:
		return

	var cam_pos = cam.global_position
	var cam_zoom = cam.zoom

	var view_size = vp.size / cam_zoom
	var top_left = cam_pos - (view_size / 2.0)
	var bottom_right = cam_pos + (view_size / 2.0)

	# Adaptive step based on zoom level to avoid dense aliasing
	var step = grid_size
	var alpha_multiplier = 1.0

	if adaptive_grid:
		if cam_zoom.x < 0.25:
			step = grid_size * 8
			alpha_multiplier = 0.7
		elif cam_zoom.x < 0.5:
			step = grid_size * 4
			alpha_multiplier = 0.8
		elif cam_zoom.x < 0.8:
			step = grid_size * 2
			alpha_multiplier = 0.9
		elif cam_zoom.x > 4.0:
			alpha_multiplier = 1.2

	var start_x: int = int(floor(top_left.x / float(step)) * float(step))
	var end_x: int = int(ceil(bottom_right.x / float(step)) * float(step))
	var start_y: int = int(floor(top_left.y / float(step)) * float(step))
	var end_y: int = int(ceil(bottom_right.y / float(step)) * float(step))

	# Apply alpha multiplier to colors
	var adj_grid_color = Color(grid_color.r, grid_color.g, grid_color.b, grid_color.a * alpha_multiplier)
	var adj_major_color = Color(major_grid_color.r, major_grid_color.g, major_grid_color.b, major_grid_color.a * alpha_multiplier)
	var adj_axis_color = Color(axis_color.r, axis_color.g, axis_color.b, axis_color.a * alpha_multiplier)

	# Draw vertical lines
	for x in range(start_x, end_x + step, step):
		var is_axis = (x == 0)
		var is_major = (x % (grid_size * major_grid_every) == 0) and not is_axis
		var color = adj_axis_color if is_axis else (adj_major_color if is_major else adj_grid_color)
		var width = 2.5 if is_axis else (1.5 if is_major else 1.0)
		draw_line(Vector2(x, start_y), Vector2(x, end_y), color, width)

	# Draw horizontal lines
	for y in range(start_y, end_y + step, step):
		var is_axis = (y == 0)
		var is_major = (y % (grid_size * major_grid_every) == 0) and not is_axis
		var color = adj_axis_color if is_axis else (adj_major_color if is_major else adj_grid_color)
		var width = 2.5 if is_axis else (1.5 if is_major else 1.0)
		draw_line(Vector2(start_x, y), Vector2(end_x, y), color, width)
