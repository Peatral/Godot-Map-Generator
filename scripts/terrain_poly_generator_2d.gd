class_name TerrainPolyGenerator2D
extends Node2D


@export var terrainator: Terrainator
@export var ui: Control

var highlighted_cell = -1

var feature_basic_types: TerrainFeatureBasicTypes
var feature_elevation: TerrainFeatureElevation
var feature_rivers: TerrainFeatureRivers
var feature_moisture: TerrainFeatureMoisture
var feature_biomes: TerrainFeatureBiomes


func _ready():
	for feature in terrainator.get_features():
		if feature is TerrainFeatureBasicTypes:
			feature_basic_types = feature
		elif feature is TerrainFeatureElevation:
			feature_elevation = feature
		elif feature is TerrainFeatureRivers:
			feature_rivers = feature
		elif feature is TerrainFeatureMoisture:
			feature_moisture = feature
		elif feature is TerrainFeatureBiomes:
			feature_biomes = feature


func generate():
	for poly_idx in terrainator.voronator.poly_count():
		if feature_basic_types.is_cell_ocean(poly_idx):
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
	
	for idx in feature_rivers.get_river_count():
		var line := Line2D.new()
		line.name = "River_%d" % idx
		line.gradient = preload("res://resources/river_gradient.tres")
		line.width_curve = preload("res://resources/river_volume_curve.tres")
		line.z_index = -1
		
		var river: PackedInt32Array = feature_rivers.get_river(idx)
		for v in river:
			line.add_point(terrainator.voronator.get_vertex(v))
		
		add_child(line)
	
	queue_redraw()


func cell_clicked(idx: int):
	if feature_basic_types.is_cell_ocean(idx):
		idx = -1
	highlighted_cell = idx
	var text = ""
	if highlighted_cell != -1:
		var ocean = feature_basic_types.cell_ocean[idx]
		var lake = feature_basic_types.is_cell_lake(idx)
		var coast = feature_basic_types.is_cell_coast(idx)
		var elevation = feature_elevation.cell_elevation[idx]
		var moisture = feature_moisture.moisture[idx]
		var biome = feature_biomes.get_biome(idx)
		text = "Index: %d\n" % highlighted_cell
		text += "Ocean\n" if ocean else "Lake\n" if lake else "Coast\n" if coast else "Land\n"
		text += "Elevation: %f\n" % elevation
		text += "Moisture: %f\n" % moisture
		text += "Biome: %s\n" % tr(biome.name)
		text += "Poly:\n"
		for vertex in terrainator.voronator.vertex_indices(highlighted_cell):
			text += "%d (%f)\n" % [vertex, feature_elevation.vertex_elevation[vertex]]
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

			if feature_elevation.downslope[vertex] != -1:
				draw_line(terrainator.voronator.get_vertex(vertex), terrainator.voronator.get_vertex(feature_elevation.downslope[vertex]), Color.GREEN, 1.5)
				draw_circle(terrainator.voronator.get_vertex(feature_elevation.downslope[vertex]), 1.5, Color.GREEN)
		for vertex in terrainator.voronator.vertex_indices(highlighted_cell):
			draw_string(preload("res://assets/fonts/m5x7.ttf"), terrainator.voronator.get_vertex(vertex), str(feature_elevation.distance_to_coast[vertex]), HORIZONTAL_ALIGNMENT_LEFT, -1, 4)

		var poly = terrainator.voronator.polygon(highlighted_cell)
		var tris = Geometry2D.triangulate_polygon(poly)
		for idx in tris.size():
			draw_line(poly[tris[idx]], poly[tris[(idx + 1) % tris.size()]], Color.YELLOW)


func cell_fill_color(idx: int) -> Color:
	var color = feature_biomes.biome_list[feature_biomes.biomes[idx]].color
	
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
