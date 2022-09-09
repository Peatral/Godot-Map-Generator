extends Object

class_name Terrainator

var voronator : Voronator

var cells : Array = []
var corners : Array = []
var centers : PackedVector2Array

var area : Rect2

signal started_generation()
signal started_voronator()
signal ran_island_function()
signal marked_ocean()
signal marked_coasts()
signal marked_corners()
signal applied_elevation()
signal finished_generation()

# Take a look at http://www-cs-students.stanford.edu/~amitp/game-programming/polygon-map-generation/
# 
# Currently implemented:
# 1. Polygons
# 2. Map representation (more or less)
# 3. Islands
# 
# Being worked on:
# 4. Elevation (move from cell based to corner based
# 
# Todo:
# 5. Rivers (probably will store river edges separately)
# 6. Moisture
# 7. Biomes
# 8. Noisy edges
# 9. More noise
# 10. Smooth biome transitions
# 11. Distorted biome transitions

# A terrain generator using the voronator as a base

func _init(p_area : Rect2):
	area = p_area

# Call to start generation process
func generate():
	emit_signal("started_generation")
	centers = PoissonDiscSampling.calculate(area.size, 10, 10)
	voronator = Voronator.new(centers)
	
	corners.resize(voronator.vertex_count())
	cells.resize(voronator.poly_count())

	emit_signal("started_voronator")
	run_island_function()
	emit_signal("ran_island_function")
	mark_ocean()
	emit_signal("marked_ocean")
	mark_coast()
	emit_signal("marked_coasts")
	mark_corners()
	emit_signal("marked_corners")
	apply_elevation()
	emit_signal("applied_elevation")
	emit_signal("finished_generation")

func island_function(pos : Vector2) -> bool:
	var noise = FastNoiseLite.new()
	return clamp(noise.get_noise_2d(pos.x, pos.y) + falloff(pos), -1, 1) > 0

func run_island_function():
	for corner in voronator.vertex_count():
		var data = TerrainData.new()
		data.water = !island_function(voronator.points[corner])
		corners[corner] = data
	for cell in cells.size():
		var data = TerrainData.new()
		data.water = Array(voronator.vertex_indices(cell)).map(func(p): return corners[p].water).has(true)
		cells[cell] = data

# Technically not the corner lol (but close enough)
func top_left_corner() -> int:
	var idx = 0
	var min = centers[0]
	for point in centers.size():
		if centers[point].x <= min.x + area.size.x / 10 && centers[point].y <= min.y + area.size.y / 10:
			min = centers[point]
			idx = point
	return idx

func falloff(point : Vector2) -> float:
	var center = area.position + area.size / 2
	var distance = (point - center).length()
	var angle = (point - center).angle()
	var max_distance = sqrt(pow(cos(angle) * area.size.x / 2, 2) + pow(sin(angle) * area.size.y / 2, 2))
	return clamp((distance / max_distance) * -2 + 1, -1, 1)

func delaunator_bfs(startpoint : int, condition : Callable, action : Callable = func(point, layer): pass) -> void:
	var todo = PackedInt32Array()
	var layers = PackedInt32Array()
	layers.resize(centers.size())
	layers.fill(-1)
	
	todo.append(startpoint)
	layers[startpoint] = 0
	while todo.size() > 0:
		var current = todo[0]
		var result = action.call(current, layers[current])
		if result != null && result:
			return
		for point in voronator.adjacent_polygons(current):
			if layers[point] == -1 && !todo.has(point) && condition.call(current, point, layers[current]):
				todo.append(point)
				layers[point] = layers[current] + 1
		todo.remove_at(0)

func mark_ocean() -> void:
	delaunator_bfs(top_left_corner(), func(current, point, layer): return cells[point].water, 
		func(point, layer):
			cells[point].ocean = true
			return false
	)

func mark_coast() -> void:
	for idx in cells.size():
		var cell = cells[idx]
		if cell.water || cell.ocean:
			continue
		for neighbor in voronator.adjacent_polygons(idx):
			var neighbor_cell = cells[neighbor]
			if neighbor_cell.ocean && neighbor_cell.water:
				cell.coast = true
				break

func mark_corners() -> void:
	for corner in corners.size():
		var data : TerrainData = corners[corner]
		var cells = voronator.touches_voronoi_point[corner]
		var all_water = cells.all(func(c): return cells[c].water)
		var all_land = cells.all(func(c): return !cells[c].water)
		var all_ocean = cells.all(func(c): return cells[c].ocean)
		data.water = all_water
		data.ocean = all_water && all_ocean
		data.coast = !all_water && !all_land

func apply_elevation() -> void:
	var landmass = PackedInt32Array()
	var dists = PackedInt32Array()
	dists.resize(cells.size())
	dists.fill(-1)
	for idx in cells.size():
		var cell : TerrainData = cells[idx]
		if cell.water:
			continue
		landmass.append(idx)
		delaunator_bfs(idx, func(current, point, layer): return true, 
			func(point, layer): 
				if cells[point].coast: 
					dists[idx] = layer
					return true
				return false)
	var max_dist = Array(dists).max()
	for idx in landmass:
		var cell = cells[idx]
		cell.distance_to_ocean = dists[idx]
		cell.elevation = dists[idx] / float(max_dist)

class TerrainData:
	var elevation : float = 0
	var distance_to_ocean : int = -1
	var water : bool = false
	var ocean : bool = false
	var coast : bool = false
