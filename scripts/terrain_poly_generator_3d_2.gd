extends Node3D

@export_node_path(Node) var terrainator_path
@onready var terrainator: Terrainator = get_node(terrainator_path)

@export_node_path(Control) var ui_path
@onready var ui: Control = get_node(ui_path)

@export var map_scale = Vector3(.1, .1, .1)
@export var additional_depth = 4.0

func generate():
	var center = terrainator.area.position + terrainator.area.size / 2
	var offset = -Vector3(center.x, 0, center.y)
	
	for poly_idx in terrainator.voronator.poly_count():
		var csg_poly = CSGPolygon3D.new()
		csg_poly.name = "Island_Poly_%d" % poly_idx
		
		if terrainator.feature_basic_types.is_cell_ocean(poly_idx):
			continue
		
		var poly = terrainator.voronator.polygon(poly_idx)
		var poly_indices = terrainator.voronator.vertex_indices(poly_idx)
		var hull = Geometry2D.convex_hull(poly)
		
		var tris = Geometry2D.triangulate_polygon(hull)
		if tris.size() > 0:
			csg_poly.polygon = PackedVector2Array(Array(hull).map(func(vec): return (vec + Vector2(offset.x, offset.z)) * Vector2(map_scale.x, map_scale.y)))
			var elevation = terrainator.feature_elevation.cell_elevation[poly_idx]
			elevation *= 5
			elevation += 0.01 + additional_depth
			csg_poly.material = preload("res://materials/mat.material")
			csg_poly.depth = elevation
			csg_poly.position.z = elevation - additional_depth
			add_child(csg_poly)
		else:
			push_error("Could not build mesh for poly")

