class_name TerrainFeatureRivers
extends TerrainFeature


var rivers := PackedInt32Array()
var volumes := PackedInt32Array()
var river_start_indices := PackedInt32Array()
var max_volume := 0


@export_range(0.0, 1.0) var vertex_river_chance: float = 0.01

@export_subgroup("Terrain Features")
@export var basic_types: TerrainFeatureBasicTypes
@export var elevation: TerrainFeatureElevation


func _generate_features(centers: PackedVector2Array, voronator: Voronator) -> void:
	_generate_rivers(voronator)
	
	emit_signal("finished")


func _get_finished_message() -> String:
	return "UI_INFO_GENERATED_RIVERS"


# Picks random vertices and follows the path downhill to the ocean to generate rivers
func _generate_rivers(voronator: Voronator) -> void:
	var last_river_idx = 0
	for vertex in voronator.vertex_count():
		if basic_types.is_vertex_ocean(vertex) || basic_types.is_vertex_coast(vertex):
			continue
		if randf() > 1 - vertex_river_chance && !rivers.has(vertex):
			river_start_indices.append(last_river_idx)
			var river = PackedInt32Array()
			river.append(vertex)
			var volume = PackedInt32Array()
			volume.append(0)
			var next = elevation.downslope[vertex]
			while next != -1:
				river.append(next)
				var segment_volume := volume.size()
				volume.append(segment_volume)
				if max_volume < segment_volume:
					max_volume = segment_volume
#				if rivers.has(next):
#					break
				next = elevation.downslope[next]
			rivers.append_array(river)
			volumes.append_array(volume)
			last_river_idx += river.size()


func get_river_count() -> int:
	return river_start_indices.size()


func get_river(idx: int) -> PackedInt32Array:
	return rivers.slice(river_start_indices[idx], river_start_indices[idx + 1] if idx < river_start_indices.size() - 1 else rivers.size())


func get_volume(idx: int) -> PackedInt32Array:
	return volumes.slice(river_start_indices[idx], river_start_indices[idx + 1] if idx < river_start_indices.size() - 1 else volumes.size())
