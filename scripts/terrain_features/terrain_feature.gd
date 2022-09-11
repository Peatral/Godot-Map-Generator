class_name TerrainFeature
extends Node

@export var feature_seed : int :
	set(value):
		seed(value)
		feature_seed = value

func _generate_features(centers: PackedVector2Array, voronator: Voronator) -> void:
	pass
