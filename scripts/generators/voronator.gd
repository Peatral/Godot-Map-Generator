extends Object

class_name Voronator

var delaunator : Delaunator

# All the corners of the voronoi cells
# a cell references this by index
var points : PackedVector2Array = PackedVector2Array()

# The list of voronoi polygons
# a cell is at the index of its center point ( -> points[index])
var polygons : PackedInt32Array = PackedInt32Array()
var polygon_start_indices : PackedInt32Array = PackedInt32Array()
var last_polygon_end : int = 0 # used while building the polygons

# The list of polygons touching the point at the index
var touches_voronoi_point : Array = []

func _init(centers : PackedVector2Array):
	delaunator = Delaunator.new(centers)
	if delaunator.error:
		printerr("Delaunator couldn't run, stopping generation...")
		return
	
	polygon_start_indices.resize(centers.size())
	delaunator.for_each_voronoi_cell(centers, add_voronoi_cell)

func add_voronoi_cell(center : int, vertices : PackedVector2Array):
	var indices = PackedInt32Array()
	for vertex in vertices:
		if points.has(vertex):
			indices.append(points.find(vertex))
		else:
			points.append(vertex)
			touches_voronoi_point.append([])
			indices.append(points.size() - 1)
	for index in indices:
		if !touches_voronoi_point[index].has(center):
			touches_voronoi_point[index].append(center)
	polygons.append_array(indices)
	polygon_start_indices[center] = last_polygon_end
	last_polygon_end += indices.size()

# Returns all neighboring polygons to the given polygon
func adjacent_polygons(v : int) -> PackedInt32Array:
	return PackedInt32Array(Array(delaunator.edges_around_point(delaunator.index[v])).map(func(e): return delaunator.triangles[e]))

func vertex_indices(v : int) -> PackedInt32Array:
	if v >= polygon_start_indices.size():
		return PackedInt32Array()
	return polygons.slice(polygon_start_indices[v], polygon_start_indices[v + 1] if v + 1 < polygon_start_indices.size() else last_polygon_end)

func polygon(v : int) -> PackedVector2Array:
	return PackedVector2Array(Array(vertex_indices(v)).map(func(p): return points[p]))

func poly_count() -> int:
	return polygon_start_indices.size()

func vertex_count() -> int:
	return points.size()
