class_name PoissonDiscSampling
extends RefCounted


static func calculate(canvas_size: Vector2, radius: float, max_try_limit: int, has_seed: bool = false, point_seed: int = 0) -> PackedVector2Array:
	if has_seed:
		seed(point_seed)
	
	var cell_size: float = radius / sqrt(2)

	# number of columns / rows
	var grid_size: Vector2i = Vector2i(floor(canvas_size.x / cell_size), floor(canvas_size.y / cell_size))

	# initialize grid
	var grid: PackedInt32Array = PackedInt32Array()
	grid.resize(grid_size.x * grid_size.y)
	grid.fill(-1)
	var points: PackedVector2Array = PackedVector2Array()
	var active_list: PackedVector2Array = PackedVector2Array()
	
	var start_point: Vector2 = Vector2(canvas_size.x / 2, canvas_size.y / 2);
	var s: Vector2i = _pds_to_grid(start_point, cell_size);

	# put the start point in grid and active list
	points.push_back(start_point)
	grid[s.x + s.y * grid_size.x] = 0;
	active_list.push_back(start_point);
	
	while active_list.size() > 0:
		var index: int = randi_range(0, active_list.size() - 1)
		var active_point: Vector2 = active_list[index]
		
		var sample: Vector2
		var sample_grid_index: int
		var ok: bool = false
		
		for n in max_try_limit:
			var random_angle: float = randf() * 2 * PI
			var random_distance: int = randi_range(int(radius), int(2 * radius))
			
			sample = Vector2(
				active_point.x + random_distance * cos(random_angle), 
				active_point.y + random_distance * sin(random_angle)
			)
			
			var sample_grid_position: Vector2i = _pds_to_grid(sample, cell_size)
			sample_grid_index = sample_grid_position.x + sample_grid_position.y * grid_size.x
			
			if sample_grid_position.x < 0 || sample_grid_position.y < 0 || sample_grid_position.x >= grid_size.x || sample_grid_position.y >= grid_size.y || grid[sample_grid_index] != -1:
				continue
			
			if _pds_is_neighbor_ok(sample_grid_position, sample, grid, grid_size, points, radius):
				ok = true
				break
		
		if ok:
			points.push_back(sample)
			grid[sample_grid_index] = points.size() - 1
			active_list.push_back(sample)
		else:
			active_list.remove_at(index)
	return points

static func _pds_to_grid(v: Vector2, cell_size: float) -> Vector2i:
	return Vector2i(floor(v.x / cell_size), floor(v.y / cell_size));

static func _pds_is_neighbor_ok(grid_pos: Vector2i, sample: Vector2, grid: PackedInt32Array, grid_size: Vector2i, points: PackedVector2Array, radius: float) -> bool:
	for y in range(-1, 2):
		for x in range(-1, 2):
			if x == 0 && y == 0:
				continue
			var checking_index = (grid_pos.x + x) + (grid_pos.y + y) * grid_size.x
			if checking_index >= 0 && checking_index < grid.size() && grid[checking_index] != -1:
				var distance_sqr: float = sample.distance_squared_to(points[grid[checking_index]])
				if distance_sqr < radius * radius:
					return false
	return true
