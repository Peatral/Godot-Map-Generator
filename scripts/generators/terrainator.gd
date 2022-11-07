# Generates a terrain
class_name Terrainator
extends Node

signal started_generation()
signal finished_stage(message: String)
signal finished_generation()
signal generation_error()


enum State {
	IDLE,
	RUNNING,
	ERROR,
	FINISHED
}

var state: State = State.IDLE

var voronator: Voronator

# The location of the cell centers
var centers: PackedVector2Array

@export var area: Rect2

@export var terrain_seed: int = 0

@export_subgroup("Poisson Disc Sampling", "poisson_")
@export var poisson_min_distance = 10
@export var poisson_max_tries = 10


# Take a look at http://www-cs-students.stanford.edu/~amitp/game-programming/polygon-map-generation/
# 
# Currently implemented:
# 1. Polygons
# 2. Map representation (more or less)
# 3. Islands
# 4. Elevation
# 5. Rivers
# 6. Moisture
# 7. Biomes
# 
# Being worked on:
# -
#
# Todo:
# 8. Noisy edges
# 9. More noise
# 10. Smooth biome transitions
# 11. Distorted biome transitions

# A terrain generator using the voronator as a base

# Call to start generation process
func generate():
	if state != State.IDLE:
		return
	
	state = State.RUNNING
	
	seed(terrain_seed)

	emit_signal("started_generation")
	centers = PoissonDiscSampling.calculate(area.size, poisson_min_distance, poisson_max_tries, true, terrain_seed)
	voronator = Voronator.new(centers)
	
	for feature in get_children():
		if not feature is TerrainFeature:
			continue
		
		feature.feature_seed = terrain_seed
		feature.area = area
		
		feature._generate_features(centers, voronator)
		emit_signal("finished_stage", feature._get_finished_message())
	
	state = State.FINISHED
	emit_signal("finished_generation")


func get_features() -> Array[TerrainFeature]:
	var array = []
	
	for child in get_children():
		if not child is TerrainFeature:
			continue
		array.append(child)
	
	return array
