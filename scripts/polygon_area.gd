class_name PolygonArea
extends Area2D

signal pressed(idx)

var idx: int = -1
var poly: PackedVector2Array
var color: Color
var vertex_colors: PackedColorArray

var mouse_over = false

func _ready():
	var collision: CollisionPolygon2D = CollisionPolygon2D.new()
	collision.name = "Collision"
	collision.polygon = poly
	add_child(collision)
	
	var polygon: Polygon2D = Polygon2D.new()
	polygon.name = "Polygon"
	polygon.polygon = poly
	polygon.color = color
	polygon.vertex_colors = vertex_colors
	add_child(polygon)
	
	var notifier: VisibleOnScreenNotifier2D = VisibleOnScreenNotifier2D.new()
	notifier.name = "VisibilityNotifier"
	var bb = Rect2(poly[0], Vector2(0, 0)).grow(5)
	for p in poly:
		bb = bb.merge(Rect2(p, Vector2(0, 0)).grow(5))
	notifier.rect = bb
	notifier.connect("screen_entered", func(): polygon.visible = true)
	notifier.connect("screen_exited", func(): polygon.visible = false)
	add_child(notifier)
	
	input_pickable = true

func _mouse_enter():
	mouse_over = true

func _mouse_exit():
	mouse_over = false

func _unhandled_input(event : InputEvent):
	# kinda defies the purpose of _on_input_event
	# but it looks like it only responds to mouse events
	# cant use mouse entered/exit events bc of the camera
	mouse_over = Geometry2D.is_point_in_polygon(get_global_mouse_position(), poly)
	if event.is_action_released("ui_click") && mouse_over:
		get_viewport().set_input_as_handled()
		_input_event(get_viewport(), event, 0)

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int):
	if event.is_action_released("ui_click"):
		emit_signal("pressed", idx)
