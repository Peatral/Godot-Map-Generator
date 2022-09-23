class_name IslandGenerator
extends Node

var gnerator_task_id: int = -1

var highlighted_cell = -1

@export_node_path(Node) var poly_gen_path
@onready var poly_gen = get_node(poly_gen_path)
@onready var ui: Control = $UILayer/IslandGeneratorUI
@onready var terrainator: Terrainator = $Terrainator

func _ready():
	terrainator.area = get_viewport().get_visible_rect()
	terrainator.connect("finished_generation", gen_finished)
	terrainator.connect("applied_basic_types", func(): ui.print_text(tr("UI_INFO_APPLIED_BASIC_TYPES"), true))
	terrainator.connect("applied_elevation", func(): ui.print_text(tr("UI_INFO_APPLIED_ELEVATION"), true))
	terrainator.connect("generated_rivers", func(): ui.print_text(tr("UI_INFO_GENERATED_RIVERS"), true))
	terrainator.connect("generated_moisture", func(): ui.print_text(tr("UI_INFO_GENERATED_MOISTURE"), true))
	terrainator.connect("generated_biomes", func(): ui.print_text(tr("UI_INFO_GENERATED_BIOMES"), true))
	terrainator.connect("started_generation", func(): ui.print_text(tr("UI_INFO_STARTED_GENERATION"), true))
	terrainator.connect("generation_error", func(): ui.print_text(tr("UI_INFO_GENERATION_ERROR"), true))
	
	get_tree().paused = true

func generate():
	if (gnerator_task_id != -1 && !WorkerThreadPool.is_task_completed(gnerator_task_id)) || terrainator.state != Terrainator.State.IDLE:
		printerr("Tried to start generation process while it was running or finished...")
		return
	ui.print_text(tr("UI_INFO_USING_SEED") % terrainator.terrain_seed)
	gnerator_task_id = WorkerThreadPool.add_task(terrainator.generate, true, "Generate Terrain")

func gen_finished():
	ui.print_text(tr("UI_INFO_GENERATION_FINISHED"), true)
	ui.animation_player.play("ui_black_fade")
	get_tree().paused = false
	poly_gen.call_deferred("generate")
	

func _on_generate(seed_text: String, min_distance: int, max_tries: int):
	ui.generator_input_holder.visible = false
	if seed_text.length() > 0:
		if seed_text.is_valid_int():
			terrainator.terrain_seed = seed_text.to_int()
		else:
			terrainator.terrain_seed = seed_text.to_lower().hash()
	else:
		terrainator.terrain_seed = int(Time.get_unix_time_from_system())
	terrainator.poisson_min_distance = min_distance
	terrainator.poisson_max_tries = max_tries
	ui.seed_label.terrain_seed = terrainator.terrain_seed
	generate()
