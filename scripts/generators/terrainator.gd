# Generates a terrain
class_name Terrainator
extends Node

signal started_generation()
signal applied_basic_types()
signal applied_elevation()
signal generated_rivers()
signal generated_moisture()
signal generated_biomes()
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

@onready var feature_basic_types: TerrainFeatureBasicTypes = $BasicTypes
@onready var feature_elevation: TerrainFeatureElevation = $Elevation
@onready var feature_rivers: TerrainFeatureRivers = $Rivers
@onready var feature_moisture: TerrainFeatureMoisture = $Moisture
@onready var feature_biomes: TerrainFeatureBiomes = $Biomes

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
	centers = PoissonDiscSampling.calculate(area.size, 10, 10, true, terrain_seed)
	voronator = Voronator.new(centers)
	
	for feature in get_children():
		if feature is TerrainFeature:
			feature.feature_seed = terrain_seed
	
	feature_basic_types.area = area
	feature_basic_types._generate_features(centers, voronator)
	emit_signal("applied_basic_types")
	feature_elevation._generate_features(centers, voronator)
	emit_signal("applied_elevation")
	feature_rivers._generate_features(centers, voronator)
	emit_signal("generated_rivers")
	feature_moisture._generate_features(centers, voronator)
	emit_signal("generated_moisture")
	feature_biomes._generate_features(centers, voronator)
	emit_signal("generated_biomes")
	
	state = State.FINISHED
	emit_signal("finished_generation")
