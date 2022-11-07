class_name TerrainFeatureElevation
extends TerrainFeature


var distance_to_coast: PackedInt32Array

var vertex_elevation: PackedFloat32Array
var cell_elevation: PackedFloat32Array

var downslope: PackedInt32Array = PackedInt32Array()


@export_subgroup("Terrain Features")
@export var basic_types: TerrainFeatureBasicTypes


func _generate_features(centers: PackedVector2Array, voronator: Voronator) -> void:
	distance_to_coast.resize(voronator.vertex_count())
	vertex_elevation.resize(voronator.vertex_count())
	cell_elevation.resize(voronator.poly_count())
	downslope.resize(voronator.vertex_count())
	distance_to_coast.fill(-1)
	vertex_elevation.fill(0)
	cell_elevation.fill(0)
	downslope.fill(-1)
	
	_apply_vertex_elevation(voronator, basic_types)
	_apply_cell_elevation(voronator)


func _get_finished_message() -> String:
	return "UI_INFO_APPLIED_ELEVATION"


# Applies the elevation to all land vertices
func _apply_vertex_elevation(voronator: Voronator, basic_types: TerrainFeatureBasicTypes) -> void:
	# perform bfs (dijkstra) starting with full coastline
	# visit neighbor if we can reach it within a smaller layer (or the layer isnt set)
	# apply layer as elevation if it isnt set or lower than before
	# Lakes:
	# push to beginning and dont increase the layer
	
	var todo = Array()
	var max_dist = -1
	
	for idx in voronator.vertex_count():
		if !basic_types.is_vertex_coast(idx):
			continue
		todo.append(idx)
		distance_to_coast[idx] = 0
	
	while todo.size() > 0:
		var current = todo[0]
		todo.remove_at(0)
		if max_dist < distance_to_coast[current]:
			max_dist = distance_to_coast[current]
		for neighbor in voronator.adjacent_vertices(current):
			if basic_types.is_vertex_ocean(neighbor):
				continue
			var lake = basic_types.is_vertex_lake(neighbor)
			var new_distance = (0 if lake else 1) + distance_to_coast[current]
			if distance_to_coast[neighbor] == -1 || new_distance < distance_to_coast[neighbor]:
				downslope[neighbor] = current
				distance_to_coast[neighbor] = new_distance
				if lake:
					todo.push_front(neighbor)
				else:
					todo.push_back(neighbor)
	
	for vertex in voronator.vertex_count():
		if distance_to_coast[vertex] == -1:
			distance_to_coast[vertex] = 0
		vertex_elevation[vertex] = distance_to_coast[vertex] / float(max_dist)
	
	emit_signal("finished")


# Applies the elevation to cells based on their vertices
func _apply_cell_elevation(voronator: Voronator) -> void:
	for cell in voronator.poly_count():
		var poly = voronator.vertex_indices(cell)
		var avg = 0
		for p in poly:
			avg += vertex_elevation[p]
		avg /= poly.size()
		cell_elevation[cell] = avg
