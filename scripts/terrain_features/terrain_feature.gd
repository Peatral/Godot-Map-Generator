class_name TerrainFeature
extends Node


signal finished()


@export var feature_seed : int :
	set(value):
		seed(value)
		feature_seed = value

@export var area: Rect2


func _generate_features(centers: PackedVector2Array, voronator: Voronator) -> void:
	pass


func _get_finished_message() -> String:
	return "UI_INFO_GENERATION_ERROR"
