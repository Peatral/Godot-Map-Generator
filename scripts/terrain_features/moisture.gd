class_name TerrainFeatureMoisture
extends TerrainFeature


var distance_to_seed = PackedInt32Array()
var moisture = PackedFloat32Array()


@export_subgroup("Terrain Features")
@export var basic_types: TerrainFeatureBasicTypes
@export var rivers: TerrainFeatureRivers


func _generate_features(centers: PackedVector2Array, voronator: Voronator) -> void:
	distance_to_seed.resize(voronator.cell_count())
	distance_to_seed.fill(-1)
	moisture.resize(voronator.cell_count())
	moisture.fill(-1)
	
	var max_dist = -1
	var todo = PackedInt32Array()
	
	var seeds = find_moisture_seeds(voronator)
	for seed in seeds:
		todo.append(seed)
		distance_to_seed[seed] = 0
	
	while todo.size() > 0:
		var current = todo[0]
		if max_dist < distance_to_seed[current]:
			max_dist = distance_to_seed[current]
		for neighbor in voronator.adjacent_cells(current):
			if basic_types.is_cell_ocean(neighbor):
				continue
			var new_distance = distance_to_seed[current] + 1
			if distance_to_seed[neighbor] == -1 || new_distance < distance_to_seed[neighbor]:
				distance_to_seed[neighbor] = new_distance
				todo.append(neighbor)
		todo.remove_at(0)
	
	for cell in voronator.cell_count():
		if basic_types.cell_water[cell]:
			distance_to_seed[cell] = 0
		moisture[cell] = float(1.0 - pow(distance_to_seed[cell] / float(max_dist), 0.5))
		if is_nan(moisture[cell]):
			moisture[cell] = 0.0
	
	emit_signal("finished")


func _get_finished_message() -> String:
	return "UI_INFO_GENERATED_MOISTURE"


# Finds all cells that spread moisture (riverbanks, lakeshores, etc.)
func find_moisture_seeds(voronator: Voronator) -> PackedInt32Array:
	var seeds = PackedInt32Array()
	for cell in find_riverbanks(voronator):
		add_to_set(seeds, cell)
	for cell in find_lakeshores(voronator):
		add_to_set(seeds, cell)
	return seeds


# Finds all cells that are riverbanks
func find_riverbanks(voronator: Voronator) -> PackedInt32Array:
	var riverbanks = PackedInt32Array()
	for idx in rivers.get_river_count():
		var river = rivers.get_river(idx)
		for vertex in river:
			for cell in voronator.get_surrounding_cells(vertex):
				add_to_set(riverbanks, cell)
	return riverbanks


# Finds all cells that are lakeshores
func find_lakeshores(voronator: Voronator) -> PackedInt32Array:
	var lakeshores = PackedInt32Array()
	for cell in voronator.cell_count():
		if basic_types.is_cell_lake(cell):
			add_to_set(lakeshores, cell)
	return lakeshores


static func add_to_set(set, value):
	if !set.has(value):
		set.append(value)
