extends Node3D

@export_node_path(Node) var terrainator_path
@onready var terrainator: Terrainator = get_node(terrainator_path)

@export_node_path(Control) var ui_path
@onready var ui: Control = get_node(ui_path)

@export var map_scale = Vector3(.1, .1, .1)

var generated_surfaces = 0

func generate():
	var center = terrainator.area.position + terrainator.area.size / 2
	var offset = -Vector3(center.x, 0, center.y)
	
	var meshinstance: MeshInstance3D
	var mesh: ArrayMesh
	for poly_idx in terrainator.voronator.cell_count():
		if generated_surfaces % 256 == 0:
			meshinstance = MeshInstance3D.new()
			mesh = ArrayMesh.new()
			meshinstance.name = "IslandSurface_Chunk_%d" % int(floor(generated_surfaces / 256))
		
		if terrainator.feature_basic_types.is_cell_ocean(poly_idx):
			continue
		
		var poly = terrainator.voronator.polygon_of_cell(poly_idx)
		var poly_indices = terrainator.voronator.vertices_of_cell(poly_idx)
		var hull = Geometry2D.convex_hull(poly)
		var hull_indices := PackedInt32Array()
		
		for vec in hull:
			var vertex_index_in_poly = poly.find(vec)
			if vertex_index_in_poly != -1:
				hull_indices.append(poly_indices[vertex_index_in_poly])
			else:
				# if this happens we had a weird (!!!!!) poly, this should not happen
				hull_indices.append(-1)
				push_error("Convex hull contained unknown vector")
		
		var tris = Geometry2D.triangulate_polygon(hull)
		if tris.size() > 0:
			var vertices := PackedVector3Array()
			var normals := PackedVector3Array()
			for idx in tris.size():
				var point_2d = hull[tris[idx]]
				var vertex_idx = hull_indices[tris[idx]]
				var point = (offset + Vector3(point_2d.x, 0, point_2d.y)) * map_scale
#				var elevation = terrainator.feature_elevation.cell_elevation[poly_idx]
				var elevation = terrainator.feature_elevation.vertex_elevation[vertex_idx]
				elevation *= 5 
				elevation += 0.01
				point.y = elevation
				vertices.append(point)
				normals.append(Vector3.UP)
#				normals.append(Vector3())
			
			var arrays = []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = vertices
			arrays[Mesh.ARRAY_NORMAL] = normals

			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			mesh.surface_set_material(mesh.get_surface_count() - 1, preload("res://mat.material"))
			generated_surfaces += 1
		else:
			push_error("Could not build mesh for poly")
	
		if (generated_surfaces - 1) % 256 == 0 && mesh.get_surface_count() > 0:
			meshinstance.mesh = mesh
			add_child(meshinstance)

