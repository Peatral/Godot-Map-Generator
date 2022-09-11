class_name Biome
extends Resource

@export var name: String = ""
@export_color_no_alpha var color: Color = Color.WHITE
@export var height_probability: Curve
@export var moisture_probability: Curve

func get_probability_vector(height: float, moisture: float) -> Vector2:
	var height_point = height_probability.sample(height)
	var moisture_point = moisture_probability.sample(moisture)
	return Vector2(height_point, moisture_point)
