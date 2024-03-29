class_name TerrainFeatureBiomes
extends TerrainFeature


@export var biome_list: Array[Biome] = []

@export_subgroup("Noise")
@export var use_feature_seed: bool = true
@export var noise: Noise

@export_subgroup("Terrain Features")
@export var basic_types: TerrainFeatureBasicTypes
@export var elevation: TerrainFeatureElevation
@export var moisture: TerrainFeatureMoisture


var biomes: PackedInt32Array = PackedInt32Array()


func _generate_features(centers: PackedVector2Array, voronator: Voronator) -> void:
	if use_feature_seed:
		noise.seed = feature_seed
	
	biomes.resize(voronator.cell_count())
	biomes.fill(0)
	
	# This is currently unused but tracks how often a biome got picked
	var biome_distribution = []
	biome_distribution.resize(biome_list.size())
	biome_distribution.fill(0)
	
	for cell in voronator.cell_count():
		if basic_types.is_cell_ocean(cell):
			continue
		
		var cell_elevation = elevation.cell_elevation[cell]
		var cell_moisture = moisture.moisture[cell]
		
		var probs = 0
		
		var calced_biome_probs = {}
		
		for idx in biome_list.size():
			var biome = biome_list[idx]
			var prob = biome.get_probability_vector(cell_elevation, cell_moisture)
			if prob.x > 0 && prob.y > 0:
				calced_biome_probs[idx] = prob.x + prob.y
				probs += prob.x + prob.y
		
		if calced_biome_probs.keys().size() == 0:
			#printerr("Did not find a fitting biome for elevation %f and moisture %f" % [cell_elevation, cell_moisture])
			continue
		elif calced_biome_probs.keys().size() == 1:
			biomes[cell] = calced_biome_probs.keys()[0]
			biome_distribution[biomes[cell]] += 1
			continue
		
		
		var poly = voronator.vertices_of_cell(cell)
		var avg = Vector2()
		for p in poly:
			avg += voronator.get_vertex_position(p)
		avg /= poly.size()
		
		var random = noise.get_noise_2d(avg.x, avg.y) * probs
		var offset = 0
		for idx in calced_biome_probs.keys():
			var prob_to_check = calced_biome_probs[idx] + offset
			if random < prob_to_check:
				biomes[cell] = idx
				biome_distribution[idx] += 1
			else:
				offset += calced_biome_probs[idx]
	
	emit_signal("finished")


func _get_finished_message() -> String:
	return "UI_INFO_GENERATED_BIOMES"


func get_biome(idx: int) -> Biome:
	return biome_list[biomes[idx]]
