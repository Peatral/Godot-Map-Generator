# Generates a terrain
class_name Terrainator
extends Node

signal started_generation()
signal finished_stage(message: String, duration: float)
signal finished_generation(accumulative_time: float)
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

# Don't export a group with the same name as a class!
@export_subgroup("Voronoi", "voronator_")
@export var voronator_centroid_lerp = 0.1

@export_subgroup("Poisson Disc Sampling", "poisson_")
@export var poisson_min_distance: float = 10
@export var poisson_max_tries: int = 10


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
	
	var accumulative_time: float = 0.0
	
	var start = Time.get_ticks_usec()
	centers = PoissonDiscSampling.calculate(area.size, poisson_min_distance, poisson_max_tries, terrain_seed)
	var end = Time.get_ticks_usec()
	var duration: float = (end - start) / 1000000.0
	accumulative_time += duration
	emit_signal("finished_stage", "UI_INFO_SAMPLED_POINTS", duration)
	
	if centers.size() <= 0:
		state = State.ERROR
		push_error("PDS has to generate points to be triangulated")
		emit_signal("generation_error")
		return
	
	start = Time.get_ticks_usec()
	voronator = Voronator.new(centers, voronator_centroid_lerp)
	end = Time.get_ticks_usec()
	duration = (end - start) / 1000000.0
	accumulative_time += duration
	emit_signal("finished_stage", "UI_INFO_TRIANGULATED_POINTS", duration)
	
	for feature in get_children():
		if not feature is TerrainFeature:
			continue
		
		feature.feature_seed = terrain_seed
		feature.area = area
		start = Time.get_ticks_usec()
		feature._generate_features(centers, voronator)
		end = Time.get_ticks_usec()
		duration = (end - start) / 1000000.0
		accumulative_time += duration
		emit_signal("finished_stage", feature._get_finished_message(), duration)
	
	state = State.FINISHED
	emit_signal("finished_generation", accumulative_time)


func get_features() -> Array[TerrainFeature]:
	var array = []
	
	for child in get_children():
		if not child is TerrainFeature:
			continue
		array.append(child)
	
	return array
