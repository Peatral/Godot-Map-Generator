extends Node2D

var gnerator_task_id: int = -1

var highlighted_cell = -1

@onready var island: Node2D = $Island
@onready var ui: Control = $UILayer/IslandGeneratorUI
@onready var terrainator: Terrainator = $Terrainator

func _ready():
	terrainator.area = get_viewport().get_visible_rect()
	terrainator.connect("finished_generation", gen_finished)
	terrainator.connect("applied_basic_types", func(): ui.print_text(tr("UI_INFO_APPLIED_BASIC_TYPES"), true))
	terrainator.connect("applied_elevation", func(): ui.print_text(tr("UI_INFO_APPLIED_ELEVATION"), true))
	terrainator.connect("generated_rivers", func(): ui.print_text(tr("UI_INFO_GENERATED_RIVERS"), true))
	terrainator.connect("generated_moisture", func(): ui.print_text(tr("UI_INFO_GENERATED_MOISTURE"), true))
	terrainator.connect("generated_biomes", func(): ui.print_text(tr("UI_INFO_GENERATED_BIOMES"), true))
	terrainator.connect("started_generation", func(): ui.print_text(tr("UI_INFO_STARTED_GENERATION"), true))
	terrainator.connect("generation_error", func(): ui.print_text(tr("UI_INFO_GENERATION_ERROR"), true))
	
	get_tree().paused = true

func generate():
	if (gnerator_task_id != -1 && !WorkerThreadPool.is_task_completed(gnerator_task_id)) || terrainator.state != Terrainator.State.IDLE:
		printerr("Tried to start generation process while it was running or finished...")
		return
	ui.print_text(tr("UI_INFO_USING_SEED") % terrainator.terrain_seed)
	gnerator_task_id = WorkerThreadPool.add_task(terrainator.generate, true, "Generate Terrain")

func gen_finished():
	ui.print_text(tr("UI_INFO_GENERATION_FINISHED"), true)
	ui.animation_player.play("ui_black_fade")
	get_tree().paused = false
	call_deferred("generate_polygon_areas")
	queue_redraw()

func generate_polygon_areas():
	for poly_idx in terrainator.voronator.poly_count():
		if terrainator.feature_basic_types.is_cell_ocean(poly_idx):
			continue
		
		var poly = Geometry2D.convex_hull(terrainator.voronator.polygon(poly_idx))
		
		if poly.size() <= 2:
			continue
		
		var area: PolygonArea = PolygonArea.new()
		area.name = "Cell_%d" % poly_idx
		area.idx = poly_idx
		area.poly = poly
		area.color = cell_fill_color(poly_idx)
		island.add_child(area)
		area.connect("pressed", cell_clicked)

func cell_clicked(idx: int):
	if terrainator.feature_basic_types.is_cell_ocean(idx):
		idx = -1
	highlighted_cell = idx
	var text = ""
	if highlighted_cell != -1:
		var ocean = terrainator.feature_basic_types.cell_ocean[idx]
		var lake = terrainator.feature_basic_types.is_cell_lake(idx)
		var coast = terrainator.feature_basic_types.is_cell_coast(idx)
		var elevation = terrainator.feature_elevation.cell_elevation[idx]
		var moisture = terrainator.feature_moisture.moisture[idx]
		var biome = terrainator.feature_biomes.get_biome(idx)
		text = "Index: %d\n" % highlighted_cell
		text += "Ocean\n" if ocean else "Lake\n" if lake else "Coast\n" if coast else "Land\n"
		text += "Elevation: %f\n" % elevation
		text += "Moisture: %f\n" % moisture
		text += "Biome: %s\n" % tr(biome.name)
		text += "Poly:\n"
		for vertex in terrainator.voronator.vertex_indices(highlighted_cell):
			text += "%d (%f)\n" % [vertex, terrainator.feature_elevation.vertex_elevation[vertex]]
	else:
		text = "Invalid index: %d" % idx
	ui.print_text(text)
	queue_redraw()

func _draw():
	if gnerator_task_id != -1 && !WorkerThreadPool.is_task_completed(gnerator_task_id):
		return
	
	if terrainator && terrainator.feature_rivers:
		for idx in terrainator.feature_rivers.get_river_count():
			var river = terrainator.feature_rivers.get_river(idx)
			var river_volume = terrainator.feature_rivers.get_volume(idx)
			var river_vertices = PackedVector2Array()
			for v in river:
				river_vertices.append(terrainator.voronator.get_vertex(v))
			for i in river_vertices.size() - 1:
				draw_line(river_vertices[i], river_vertices[i+1], Color.html("5b84ad"), sqrt(river_volume[i] + 1))
	
	if highlighted_cell != -1:
		for cell in terrainator.voronator.adjacent_polygons(highlighted_cell):
			if island.has_node("Cell_%d" % cell):
				draw_cell(cell, Color.DARK_ORANGE, false)
		draw_cell(highlighted_cell, Color.RED, false)
		
		for vertex in terrainator.voronator.vertex_indices(highlighted_cell):
			draw_circle(terrainator.voronator.get_vertex(vertex), .5, Color.DIM_GRAY)
			
			if terrainator.feature_elevation.downslope[vertex] != -1:
				draw_line(terrainator.voronator.get_vertex(vertex), terrainator.voronator.get_vertex(terrainator.feature_elevation.downslope[vertex]), Color.GREEN, 1.5)
				draw_circle(terrainator.voronator.get_vertex(terrainator.feature_elevation.downslope[vertex]), 1.5, Color.GREEN)
		for vertex in terrainator.voronator.vertex_indices(highlighted_cell):
			draw_string(preload("res://m5x7.ttf"), terrainator.voronator.get_vertex(vertex), str(terrainator.feature_elevation.distance_to_coast[vertex]), HORIZONTAL_ALIGNMENT_LEFT, -1, 4)

func cell_fill_color(idx: int) -> Color:
	var color = terrainator.feature_biomes.biome_list[terrainator.feature_biomes.biomes[idx]].color
	
	var feature_basic_types = terrainator.feature_basic_types
	var feature_elevation = terrainator.feature_elevation
	
	var ocean = feature_basic_types.is_cell_ocean(idx)
	var lake = feature_basic_types.is_cell_lake(idx)
	var elevation = feature_elevation.cell_elevation[idx]
	
	if lake:
		color = Color.html("5b84ad")
	elif ocean:
		color = Color.html("33335b")
	else:
		color.v = 0.75 + elevation / 4.0
	return color

func draw_cell(idx: int, color: Color, filled: bool):
	var cell = terrainator.voronator.polygon(idx)
	if cell.size() > 2:
		# The convex hull should be a renderable poly and nearly indestiguishable
		var poly = Geometry2D.convex_hull(cell)
		if filled:
			draw_polygon(poly, [color])
		else:
			draw_polyline(poly, color, 1)

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
