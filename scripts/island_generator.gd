extends Node2D

var thread: Thread
var terrainator: Terrainator

var highlighted_cell = -1

@onready var island: Node2D = $Island

@onready var ui: Control = $UILayer/IslandGeneratorUI

func _ready():
	terrainator = Terrainator.new(get_viewport().get_visible_rect())
	terrainator.connect("finished_generation", gen_finished)
	terrainator.connect("started_generation", func(): ui.print_text(tr("UI_INFO_STARTED_GENERATION"), true))
	terrainator.connect("started_voronator", func(): ui.print_text(tr("UI_INFO_STARTED_VORONATOR"), true))
	terrainator.connect("ran_island_function", func(): ui.print_text(tr("UI_INFO_RAN_ISLAND_FUNCTION"), true))
	terrainator.connect("marked_ocean", func(): ui.print_text(tr("UI_INFO_MARKED_OCEAN"), true))
	terrainator.connect("marked_coasts", func(): ui.print_text(tr("UI_INFO_MARKED_COASTS"), true))
	terrainator.connect("marked_corners", func(): ui.print_text(tr("UI_INFO_MARKED_CORNERS"), true))
	terrainator.connect("applied_elevation", func(): ui.print_text(tr("UI_INFO_APPLIED_ELEVATION"), true))
	terrainator.connect("generation_error", func(): ui.print_text(tr("UI_INFO_GENERATION_ERROR"), true))
	
	get_tree().paused = true

func generate():
	if thread || terrainator.state != Terrainator.State.IDLE:
		printerr("Tried to start generation process while it was running or finished...")
		return
	ui.print_text(tr("UI_INFO_USING_SEED") % terrainator.terrain_seed)
	thread = Thread.new()
	thread.start(terrainator.generate)
	queue_redraw()

func gen_finished():
	ui.print_text(tr("UI_INFO_GENERATION_FINISHED"), true)
	ui.animation_player.play("ui_black_fade")
	get_tree().paused = false
	call_deferred("generate_polygon_areas")

func cell_clicked(idx: int):
	if terrainator.cells[idx].ocean:
		idx = -1
	highlighted_cell = idx
	var text = ""
	if highlighted_cell != -1:
		var data = terrainator.cells[highlighted_cell]
		text = "Index: %d\n" % highlighted_cell
		text += "Ocean\n" if data.water && data.ocean else "Lake\n" if data.water else "Coast\n" if data.coast else "Land\n"
		text += "Elevation: %f\n" % data.elevation
		text += "Neighbors:\n"
		for neighbor in terrainator.voronator.adjacent_polygons(highlighted_cell):
			text += "%d\n" % neighbor
	else:
		text = "Invalid index: %d" % idx
	ui.print_text(text)
	queue_redraw()

func generate_polygon_areas():
	for poly_idx in terrainator.voronator.poly_count():
		if terrainator.cells[poly_idx].ocean:
			continue
		
		var poly = Geometry2D.convex_hull(terrainator.voronator.polygon(poly_idx))
		
		var area: PolygonArea = PolygonArea.new()
		area.name = "Cell_%d" % poly_idx
		area.idx = poly_idx
		area.poly = poly
		area.color = cell_fill_color(poly_idx)
		island.add_child(area)
		area.connect("pressed", cell_clicked)

func _draw():
	if thread && thread.is_alive():
		return
	
	if highlighted_cell != -1:
		for cell in terrainator.voronator.adjacent_polygons(highlighted_cell):
			if island.has_node("Cell_%d" % cell):
				draw_cell(cell, Color.DARK_ORANGE, false)
		draw_cell(highlighted_cell, Color.RED, false)

func cell_fill_color(idx: int) -> Color:
	var data = terrainator.cells[idx]
	var color = Color.RED
	if data.water:
		color = Color.html("33335b") if data.ocean else Color.html("5b84ad")
	else:
		color = Color.html("618b55").lerp(Color.WHITE_SMOKE, data.elevation)
	return color

func draw_cell(idx: int, color: Color, filled: bool):
	var cell = terrainator.voronator.polygon(idx)
	if cell.size() > 2:
		# The convex hull should be a renderable poly and nearly indestiguishable
		var poly = Geometry2D.convex_hull(cell)
		if filled:
			draw_polygon(poly, [color])
		else:
			draw_polyline(poly, color, 2)

func _on_generate_pressed(seed_text):
	ui.seed_input_holder.visible = false
	if seed_text.length() > 0:
		if seed_text.is_valid_int():
			terrainator.terrain_seed = seed_text.to_int()
		else:
			terrainator.terrain_seed = seed_text.to_lower().hash()
	else:
		terrainator.terrain_seed = int(Time.get_unix_time_from_system())
	ui.seed_label.terrain_seed = terrainator.terrain_seed
	generate()
