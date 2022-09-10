extends Camera2D

var previous_mouse_position: Vector2 = Vector2(0, 0);
var can_drag: bool = false;
var dragged: bool = false;

func _ready():
	position = get_viewport_rect().size / 2
	offset = - get_viewport_rect().size / 2

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_click"):
		previous_mouse_position = get_viewport().get_mouse_position()
		can_drag = true
	elif event.is_action_released("ui_click"):
		if dragged:
			get_viewport().set_input_as_handled()
			dragged = false
		can_drag = false
	elif event is InputEventMouseMotion && can_drag:
		var move = (previous_mouse_position - event.position) / zoom
		if move.length() > 3 || dragged:
			get_viewport().set_input_as_handled()
			dragged = true
			position += move
			previous_mouse_position = event.position
	
	elif event.is_action_released("ui_zoom_in"):
		modify_zoom(.1)
	elif event.is_action_released("ui_zoom_out"):
		modify_zoom(-.1)

func _process(_delta):
	var v = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	var h = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var move = Vector2(h, v).normalized() * 10
	if can_drag && move.length() > 0:
		dragged = true
		position += move

func modify_zoom(val):
	zoom = Vector2(clamp(zoom.x + val, 1, 10), clamp(zoom.y + val, 1, 10))
	offset = - get_viewport_rect().size / 2 / zoom
