class_name TerrainPolyGenerator2D
extends Node2D

@export_node_path(Node) var terrainator_path
@onready var terrainator: Terrainator = get_node(terrainator_path)

@export_node_path(Control) var ui_path
@onready var ui: Control = get_node(ui_path)

var highlighted_cell = -1

func generate():
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
		area.z_index = -1
		add_child(area)
		area.connect("pressed", cell_clicked)
	
	for idx in terrainator.feature_rivers.get_river_count():
		var line := Line2D.new()
		line.name = "River_%d" % idx
		line.gradient = preload("res://resources/river_gradient.tres")
		line.width_curve = preload("res://resources/river_volume_curve.tres")
		line.z_index = -1
		
		var river := terrainator.feature_rivers.get_river(idx)
		for v in river:
			line.add_point(terrainator.voronator.get_vertex(v))
		
		add_child(line)
	
	queue_redraw()

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
	if highlighted_cell != -1:
		for cell in terrainator.voronator.adjacent_polygons(highlighted_cell):
			if has_node("Cell_%d" % cell):
				draw_cell(cell, Color.DARK_ORANGE, false)
		draw_cell(highlighted_cell, Color.RED, false)

		for vertex in terrainator.voronator.vertex_indices(highlighted_cell):
			draw_circle(terrainator.voronator.get_vertex(vertex), .5, Color.DIM_GRAY)

			if terrainator.feature_elevation.downslope[vertex] != -1:
				draw_line(terrainator.voronator.get_vertex(vertex), terrainator.voronator.get_vertex(terrainator.feature_elevation.downslope[vertex]), Color.GREEN, 1.5)
				draw_circle(terrainator.voronator.get_vertex(terrainator.feature_elevation.downslope[vertex]), 1.5, Color.GREEN)
		for vertex in terrainator.voronator.vertex_indices(highlighted_cell):
			draw_string(preload("res://m5x7.ttf"), terrainator.voronator.get_vertex(vertex), str(terrainator.feature_elevation.distance_to_coast[vertex]), HORIZONTAL_ALIGNMENT_LEFT, -1, 4)

		var poly = terrainator.voronator.polygon(highlighted_cell)
		var tris = Geometry2D.triangulate_polygon(poly)
		for idx in tris.size():
			var point = draw_line(poly[tris[idx]], poly[tris[(idx + 1) % tris.size()]], Color.YELLOW)
	
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
		color.v *= 0.5 + elevation / 2.0
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
