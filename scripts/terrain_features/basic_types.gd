class_name TerrainFeatureBasicTypes
extends TerrainFeature

var vertex_ocean = []
var vertex_water = []
var vertex_coast = []

var cell_ocean = []
var cell_water = []
var cell_coast = []

@export var area: Rect2

@export_subgroup("Noise")
@export var use_feature_seed: bool = true
@export var noise: Noise

func _generate_features(centers: PackedVector2Array, voronator: Voronator) -> void:
	if use_feature_seed:
		noise.seed = feature_seed
	
	cell_ocean.resize(voronator.poly_count())
	cell_water.resize(voronator.poly_count())
	cell_coast.resize(voronator.poly_count())
	cell_ocean.fill(false)
	cell_water.fill(false)
	cell_coast.fill(false)
	
	vertex_ocean.resize(voronator.vertex_count())
	vertex_water.resize(voronator.vertex_count())
	vertex_coast.resize(voronator.vertex_count())
	vertex_ocean.fill(false)
	vertex_water.fill(false)
	vertex_coast.fill(false)
	
	_run__island_function_vertices(voronator)
	apply_water_to_cells(voronator)
	_mark_ocean(centers, voronator)
	_mark_coast(voronator)
	_mark_vertices(voronator)

# Runs the island function for all vertices
func _run__island_function_vertices(voronator: Voronator) -> void:
	for idx in voronator.vertex_count():
		var vertex = voronator.get_vertex(idx)
		vertex_water[idx] = !_island_function(vertex)

# Decides wether a point is water or land
func _island_function(pos: Vector2) -> bool:
	return clamp(noise.get_noise_2d(pos.x, pos.y) + _falloff(pos), -1, 1) > 0

# Calculates a _falloff so that the corners and edges are in the water
func _falloff(point: Vector2) -> float:
	var center = area.position + area.size / 2
	var distance = (point - center).length()
	var angle = (point - center).angle()
	var max_distance = sqrt(pow(cos(angle) * area.size.x / 2, 2) + pow(sin(angle) * area.size.y / 2, 2))
	return clamp((distance / max_distance) * -2 + 1, -1, 1)

# Applies water to cells based on its vertices
func apply_water_to_cells(voronator: Voronator) -> void:
	for idx in voronator.poly_count():
		cell_water[idx] = Array(voronator.vertex_indices(idx)).map(func(p): return vertex_water[p]).has(true)

# Tries to return a vertex from the top left corner
func _top_left_corner(centers: PackedVector2Array) -> int:
	var idx = 0
	var minimal = centers[0]
	for point in centers.size():
		if centers[point].x <= minimal.x + area.size.x / 10 && centers[point].y <= minimal.y + area.size.y / 10:
			minimal = centers[point]
			idx = point
	return idx

# Marks all adjacent water cells as ocean starting from the top left corner (flood fill)
func _mark_ocean(centers: PackedVector2Array, voronator: Voronator) -> void:
	var todo = PackedInt32Array()
	var layers = PackedInt32Array()
	layers.resize(voronator.poly_count())
	layers.fill(-1)
	
	var startpoint = _top_left_corner(centers)
	todo.append(startpoint)
	layers[startpoint] = 0
	while todo.size() > 0:
		var current = todo[0]
		cell_ocean[current] = true
		for poly in voronator.adjacent_polygons(current):
			if layers[poly] == -1 && !todo.has(poly) && cell_water[poly]:
				todo.append(poly)
				layers[poly] = layers[current] + 1
		todo.remove_at(0)

# Marks cells as coast cells when they are land and next to the ocean
func _mark_coast(voronator: Voronator) -> void:
	for idx in voronator.poly_count():
		if cell_water[idx] || cell_ocean[idx]:
			continue
		for neighbor in voronator.adjacent_polygons(idx):
			if cell_ocean[neighbor] && cell_water[neighbor]:
				cell_coast[idx] = true
				break

# Marks the terrain type off all vertices based on the surrounding cells
func _mark_vertices(voronator: Voronator) -> void:
	for vertex in voronator.vertex_count():
		var neighbors = voronator.get_surrounding_polygons(vertex)
		
		var all_water = true
		var all_ocean = true
		var has_ocean = false
		var has_land = false
		for neighbor in neighbors:
			if !all_water && !all_ocean && has_ocean && has_land:
				break
			if !cell_water[neighbor]:
				all_water = false
				has_land = true
			if !cell_ocean[neighbor]:
				all_ocean = false
			if cell_ocean[neighbor]:
				has_ocean = true
		
		vertex_water[vertex] = all_water
		vertex_ocean[vertex] = all_water && all_ocean
		vertex_coast[vertex] = has_ocean && has_land

func is_vertex_lake(idx: int) -> bool:
	return vertex_water[idx] && !vertex_ocean[idx]

func is_vertex_ocean(idx: int) -> bool:
	return vertex_water[idx] && vertex_ocean[idx]

func is_vertex_coast(idx: int) -> bool:
	return vertex_coast[idx] && !is_vertex_ocean(idx) && !is_vertex_lake(idx)

func is_cell_lake(idx: int) -> bool:
	return cell_water[idx] && !cell_ocean[idx]

func is_cell_ocean(idx: int) -> bool:
	return cell_water[idx] && cell_ocean[idx]

func is_cell_coast(idx: int) -> bool:
	return cell_coast[idx] && !is_cell_ocean(idx) && !is_cell_lake(idx)
