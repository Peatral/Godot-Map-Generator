extends Node2D

var thread : Thread
var terrainator : Terrainator

var highlighted_cell = -1

func _ready():
	terrainator = Terrainator.new(get_viewport().get_visible_rect())
	terrainator.connect("finished_generation", gen_finished)
	terrainator.connect("started_generation", func(): print("started gen"))
	terrainator.connect("started_voronator", func(): print("started voronator"))
	terrainator.connect("ran_island_function", func(): print("ran island function"))
	terrainator.connect("marked_ocean", func(): print("marked ocean"))
	terrainator.connect("marked_coasts", func(): print("marked coasts"))
	terrainator.connect("marked_corners", func(): print("marked corners"))
	terrainator.connect("applied_elevation", func(): print("applied elevation"))
	
	thread = Thread.new()
	thread.start(terrainator.generate)
	queue_redraw()

func gen_finished():
	print("generation finished")
	queue_redraw()

func _draw():
	if thread.is_alive():
		return
	for idx in terrainator.cells.size():
		var data = terrainator.cells[idx]
		var color = Color.RED
		if data.water:
			color = Color.html("33335b") if data.ocean else Color.html("5b84ad")
		else:
			color = Color.html("618b55").lerp(Color.WHITE_SMOKE, data.elevation)
		
		draw_cell(idx, color, true)
	
	if highlighted_cell != -1:
		for cell in terrainator.voronator.adjacent_polygons(highlighted_cell):
			draw_cell(cell, Color.DARK_ORANGE, false)
		draw_cell(highlighted_cell, Color.RED, false)

func draw_cell(idx : int, color : Color, filled : bool):
	var cell = terrainator.voronator.polygon(idx)
	if cell.size() > 2:
		# The convex hull should be a renderable poly and nearly indestiguishable
		var poly = Geometry2D.convex_hull(cell)
		if filled:
			draw_polygon(poly, [color])
		else:
			draw_polyline(poly, color, 1)

func _input(event):
	if event is InputEventMouseButton && event.pressed:
		var pos = get_viewport().get_mouse_position()
		for cell in terrainator.centers.size():
			var poly = terrainator.voronator.polygon(cell)
			if Geometry2D.is_point_in_polygon(pos, poly):
				highlighted_cell = cell
				break
		var text = ""
		if highlighted_cell != -1:
			var data = terrainator.cells[highlighted_cell]
			text = "Index: %d\n" % highlighted_cell
			text += "Ocean\n" if data.water && data.ocean else "Lake\n" if data.water else "Coast\n" if data.coast else "Land\n"
			text += "Elevation: %f\n" % data.elevation
			text += "Neighbors:\n"
			for neighbor in terrainator.voronator.adjacent_polygons(highlighted_cell):
				text += "%d\n" % neighbor
		$CanvasLayer/Control/RichTextLabel.text = text
		queue_redraw()
