class_name HexSampling
extends RefCounted


static func calculate(area: Vector2, min_distance: float) -> PackedVector2Array:
	var row_height = sqrt(3) / 2 * min_distance
	var points = PackedVector2Array()
	for row in int(area.y / row_height + 1):
		var row_offset: float = (0.0 if int(row) % 2 == 0 else min_distance / 2.0)
		for col in int(area.x / min_distance + 1):
			points.append(Vector2(col * min_distance + row_offset, row * row_height))
	return points
