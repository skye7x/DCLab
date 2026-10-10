extends Line2D
class_name ConnectionLine

var link_id: String = ''
var link_ref = null # type: EthernetLink
var source_node: Node2D = null
var dest_node: Node2D = null
var is_active: bool = false
var _packet_visuals: Array = []

func _ready() -> void:
	width = 2.0
	default_color = Color(0.4, 0.4, 0.4)
	antialiased = true
	z_index = -1

func setup(link, src_node: Node2D, dst_node: Node2D) -> void:
	link_ref = link
	link_id = link.id
	source_node = src_node
	dest_node = dst_node
	update_positions()

func _process(_delta: float) -> void:
	update_positions()

func update_positions() -> void:
	if source_node and dest_node:
		clear_points()
		add_point(source_node.position)
		add_point(dest_node.position)
		
		if not link_ref:
			return
			
		if not link_ref.is_enabled:
			default_color = Color(0.3, 0.3, 0.3)
			# Ideal representation would be dashed, but we'll use flat color here for simplicity
		elif is_active:
			default_color = Color(0.3, 0.7, 0.3)
		else:
			default_color = Color(0.4, 0.6, 0.4)

func show_packet_animation(protocol: String = 'ICMP', speed: float = 0.5) -> void:
	if source_node and dest_node:
		# Need to dynamically load PacketVisual if we are not injecting it,
		# or just draw directly. Since we have a PacketVisual class:
		var PacketVisScene = load("res://scenes/connections/packet_visual.gd")
		if PacketVisScene:
			var pv = PacketVisScene.new()
			add_child(pv)
			pv.setup(source_node.position, dest_node.position, protocol, speed)

func set_active(active: bool) -> void:
	is_active = active
