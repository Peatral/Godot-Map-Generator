## Wrapper to the delaunator to handle the voronoi cells more efficiently
## Vertex is always the index in the vertices array, point is the actual position of said vertex.
class_name Voronator
extends RefCounted

## The delaunator this Voronator uses
var delaunator: Delaunator

## All the corners of the voronoi cells
## a cell references this by index
var vertices: PackedVector2Array = PackedVector2Array()

## The list of voronoi cells
## a cell is at the index of its center point ( -> vertices[index])
var cells: PackedInt32Array = PackedInt32Array()
var cell_start_indices: PackedInt32Array = PackedInt32Array()
var last_cell_end: int = 0 # used while building the cells

## The list of cells touching the point at the index
var touches_vertex: Array = []

## Represents the lerp amount between circumcenter and centroid
var centroid_lerp = 0.1

## Generates voronoi cells based on a delaunay triangulation of the given vertices
func _init(centers: PackedVector2Array, p_centroid_lerp):
	delaunator = Delaunator.new()
	delaunator.triangulate(centers)
	centroid_lerp = p_centroid_lerp
	cell_start_indices.resize(centers.size())
	
	for p in centers.size():
		var tris := Array(delaunator.triangles_around_point(p))
		var vertices: PackedVector2Array = PackedVector2Array(tris.map(func(t): return delaunator.triangle_center(centers, t, centroid_lerp)))
		_add_voronoi_cell(p, vertices)

## Add a voronoi cell internally and updates the touches_vertex array
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
	cells.append_array(indices)
	cell_start_indices[center] = last_cell_end
	last_cell_end += indices.size()

## Returns all neighboring cells to the given cell
func adjacent_cells(cell: int) -> PackedInt32Array:
	return PackedInt32Array(Array(delaunator.edges_around_point(cell)).map(func(edge): return delaunator.get_triangles()[edge]))

## Returns the vertices of a cell
func vertices_of_cell(cell: int) -> PackedInt32Array:
	if cell >= cell_start_indices.size():
		return PackedInt32Array()
	return cells.slice(cell_start_indices[cell], cell_start_indices[cell + 1] if cell + 1 < cell_start_indices.size() else last_cell_end)

## Returns the actual points of a cell
func polygon_of_cell(cell: int) -> PackedVector2Array:
	return PackedVector2Array(Array(vertices_of_cell(cell)).map(func(p): return vertices[p]))

## Returns the amount of voronoi cells in the current graph
func cell_count() -> int:
	return cell_start_indices.size()

## Returns the adjacent vertices to a given voronoi vertex
## Seems kinda inefficient but because there are so few neighbors it should be fine
func adjacent_vertices(vertex: int) -> PackedInt32Array:
	var adjacent_polys: Array = touches_vertex[vertex]
	var adjacents: PackedInt32Array = PackedInt32Array()
	for poly in adjacent_polys.map(func(p): return vertices_of_cell(p)):
		for p in poly.size():
			if poly[(p + 1) % poly.size()] == vertex && !adjacents.has(poly[p]):
				adjacents.append(poly[p])
	return adjacents

## Returns the amount of voronoi vertices in the current graph
func vertex_count() -> int:
	return vertices.size()

## Returns a given vertex by index (used for encapsulation)
func get_vertex_position(vertex: int) -> Vector2:
	return vertices[vertex]

## Returns the indices of the cells surrounding a given vertex
func get_surrounding_cells(vertex: int) -> Array:
	return touches_vertex[vertex]
