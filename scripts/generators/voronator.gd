# Wrapper to the delaunator to handle the voronoi cells more efficiently
class_name Voronator
extends RefCounted


var delaunator: Delaunator

var error: bool = false

# All the corners of the voronoi cells
# a cell references this by index
var vertices: PackedVector2Array = PackedVector2Array()

# The list of voronoi polygons
# a cell is at the index of its center point ( -> vertices[index])
var polygons: PackedInt32Array = PackedInt32Array()
var polygon_start_indices: PackedInt32Array = PackedInt32Array()
var last_polygon_end: int = 0 # used while building the polygons

# The list of polygons touching the point at the index
var touches_vertex: Array = []

# Generates voronoi cells (polygons) based on a delaunay triangulation of the given vertices
func _init(centers: PackedVector2Array):
	delaunator = Delaunator.new(centers)
	if delaunator.error:
		printerr("Delaunator couldn't run, stopping generation...")
		error = true
		return
	
	polygon_start_indices.resize(centers.size())
	delaunator.for_each_voronoi_cell(centers, _add_voronoi_cell)

# Add a voronoi cell internally and updates the touches_vertex array
func _add_voronoi_cell(center: int, points: PackedVector2Array):
	var indices = PackedInt32Array()
	for vertex in points:
		if vertices.has(vertex):
			indices.append(vertices.find(vertex))
		else:
			vertices.append(vertex)
			touches_vertex.append([])
			indices.append(vertices.size() - 1)
	for index in indices:
		if !touches_vertex[index].has(center):
			touches_vertex[index].append(center)
	polygons.append_array(indices)
	polygon_start_indices[center] = last_polygon_end
	last_polygon_end += indices.size()

# Returns all neighboring polygons to the given polygon
func adjacent_polygons(v: int) -> PackedInt32Array:
	return PackedInt32Array(Array(delaunator.edges_around_point(delaunator.index[v])).map(func(e): return delaunator.triangles[e]))

# Returns the point indices of a polygon
func vertex_indices(v: int) -> PackedInt32Array:
	if v >= polygon_start_indices.size():
		return PackedInt32Array()
	return polygons.slice(polygon_start_indices[v], polygon_start_indices[v + 1] if v + 1 < polygon_start_indices.size() else last_polygon_end)

# Returns the actual vertices of a polygon
func polygon(v: int) -> PackedVector2Array:
	return PackedVector2Array(Array(vertex_indices(v)).map(func(p): return vertices[p]))

# Returns the amount of voronoi cells in the current graph
func poly_count() -> int:
	return polygon_start_indices.size()

# Returns the adjacent vertices to a given voronoi vertex
# Seems kinda inefficient but because there are so few neighbors it should be fine
func adjacent_vertices(point: int) -> PackedInt32Array:
	var adjacent_polys: Array = touches_vertex[point]
	var adjacents: PackedInt32Array = PackedInt32Array()
	for poly in adjacent_polys.map(func(p): return vertex_indices(p)):
		for p in poly.size():
			if poly[(p + 1) % poly.size()] == point && !adjacents.has(poly[p]):
				adjacents.append(poly[p])
	return adjacents

# Returns the amount of voronoi vertices in the current graph
func vertex_count() -> int:
	return vertices.size()

# Returns a given vertex by index (used for encapsulation)
func get_vertex(index: int) -> Vector2:
	return vertices[index]

# Returns the indices of the polygons surrounding a given vertex
func get_surrounding_polygons(index: int) -> Array:
	return touches_vertex[index]
