class_name Delaunator
extends RefCounted

var triangles: PackedInt32Array
var halfedges: PackedInt32Array

var index

var error: bool = false

# Based off of https://mapbox.github.io/delaunator/

func _init(points: PackedVector2Array):
	triangles = Geometry2D.triangulate_delaunay(points)
	
	if !all_tri_cw(points):
		printerr("Not all triangles are clockwise!")
		error = true
		return
	
	halfedges.resize(triangles.size())
	halfedges.fill(-1)
	
	# maps an index of an edge onto its two points
	# this is actually the only time an edge gets grouped with its endpoints
	# probably as efficient as it gets withour reimplementing delauny
	var edge_index = {}
	
	for tri in range(floor(triangles.size() / 3.0)):
		for edge in edges_of_triangle(tri):
			# we already found the fitting halfedge
			if halfedges[edge] != -1:
				continue
			
			var p = triangles[edge]
			var q = triangles[next_halfedge(edge)]
			
			# we put the edge into the index
			edge_index[Vector2i(p, q)] = edge
			# and if we have the other one in the index we can just link them up
			if edge_index.has(Vector2i(q, p)):
				_link(edge, edge_index[Vector2i(q, p)])

func _link(a: int, b: int) -> void:
	halfedges[a] = b
	if b != -1: halfedges[b] = a

static func edges_of_triangle(t: int) -> Array:
	return [3 * t, 3 * t + 1, 3 * t + 2]

static func triangle_of_edge(e: int) -> int:
	return int(floor(e / 3.0))

static func next_halfedge(e: int) -> int:
	return e - 2 if e % 3 == 2 else e + 1

static func prev_halfedge(e: int) -> int:
	return e + 2 if e % 3 == 0 else e - 1

func for_each_triangle_edge(points: PackedVector2Array, callback: Callable) -> void:
	for e in triangles.size():
		if e > halfedges[e]:
			var p = points[triangles[e]]
			var q = points[triangles[next_halfedge(e)]]
			callback.call(e, p, q)

func points_of_triangle(t: int) -> PackedInt32Array:
	return PackedInt32Array(edges_of_triangle(t).map(func(e): return triangles[e]))

func for_each_triangle(points: PackedVector2Array, callback: Callable) -> void:
	for t in triangles.size() / 3.0:
		callback.call(t, Array(points_of_triangle(t)).map(func(p): return points[p]))

func triangles_adjacent_to_triangle(t: int) -> PackedInt32Array:
	var adjacent_triangles = PackedInt32Array()
	for e in edges_of_triangle(t):
		var opposite = halfedges[e]
		if opposite >= 0:
			adjacent_triangles.append(triangle_of_edge(opposite))
	return adjacent_triangles

static func circumcenter(a: Vector2, b: Vector2, c: Vector2) -> Vector2:
	var ad = a.x * a.x + a.y * a.y
	var bd = b.x * b.x + b.y * b.y
	var cd = c.x * c.x + c.y * c.y
	var D = 2 * (a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y))
	return Vector2(
		1 / D * (ad * (b.y - c.y) + bd * (c.y - a.y) + cd * (a.y - b.y)),
		1 / D * (ad * (c.x - b.x) + bd * (a.x - c.x) + cd * (b.x - a.x)),
	);

func triangle_center(points: PackedVector2Array, t: int) -> Vector2:
	var vertices = Array(points_of_triangle(t)).map(func (p): return points[p])
	return circumcenter(vertices[0], vertices[1], vertices[2]);

func for_each_voronoi_edge(points: PackedVector2Array, callback: Callable):
	for e in triangles.size():
		if e < halfedges[e]:
			var p = triangle_center(points, triangle_of_edge(e))
			var q = triangle_center(points, triangle_of_edge(halfedges[e]))
			callback.call(e, p, q)

func edges_around_point(start: int) -> PackedInt32Array:
	var result = PackedInt32Array()
	var incoming = start
	
	result.append(incoming);
	var outgoing = next_halfedge(incoming)
	incoming = halfedges[outgoing]
	
	while incoming != -1 && incoming != start:
		result.append(incoming);
		outgoing = next_halfedge(incoming)
		incoming = halfedges[outgoing]
	
	return result;

func for_each_voronoi_cell(points: PackedVector2Array, callback: Callable) -> void:
	if !index:
		index = {}
		for e in triangles.size():
			var endpoint = triangles[next_halfedge(e)]
			if !index.has(endpoint) || halfedges[e] == -1:
				index[endpoint] = e
	
	for p in points.size():
		var incoming = index[p]
		var edges = edges_around_point(incoming)
		var tris = Array(edges).map(triangle_of_edge)
		var vertices: PackedVector2Array = PackedVector2Array(tris.map(func(t): return triangle_center(points, t)))
		callback.call(p, vertices)

# Other utility stuff
func all_tri_cw(points: PackedVector2Array) -> bool:
	for tri_index in range(floor(triangles.size() / 3.0)):
		var edges = edges_of_triangle(tri_index)
		var poly = edges.map(func(e): return points[triangles[e]])
		if !Geometry2D.is_polygon_clockwise(poly):
			poly.reverse()
			if !Geometry2D.is_polygon_clockwise(poly):
				return false
			for i in poly.size():
				triangles[edges[i]] = poly[i]
			print("flipped tri")
	return true

func tri_count() -> int:
	return int(floor(triangles.size() / 3.0))
