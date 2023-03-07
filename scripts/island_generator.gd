class_name IslandGenerator
extends Node


var gnerator_task_id: int = -1

var highlighted_cell = -1


@export var poly_gen: Node
@onready var ui: Control = $UILayer/IslandGeneratorUI
@onready var terrainator: Terrainator = $Terrainator


func _ready():
	terrainator.area = get_viewport().get_visible_rect()
	terrainator.started_generation.connect(func(): ui.print_text(tr("UI_INFO_STARTED_GENERATION"), true))
	terrainator.finished_stage.connect(func(message, duration): ui.print_text(tr(message) + " (" + str(duration) + "s)", true))
	terrainator.finished_generation.connect(gen_finished)
	terrainator.generation_error.connect(func(): ui.print_text(tr("UI_INFO_GENERATION_ERROR"), true))
	
	get_tree().paused = true


func generate():
	if (gnerator_task_id != -1 && !WorkerThreadPool.is_task_completed(gnerator_task_id)) || terrainator.state != Terrainator.State.IDLE:
		printerr("Tried to start generation process while it was running or finished...")
		return
	ui.print_text(tr("UI_INFO_USING_SEED") % terrainator.terrain_seed)
	gnerator_task_id = WorkerThreadPool.add_task(terrainator.generate, true, "Generate Terrain")


func gen_finished(accumulative_time: float):
	ui.print_text(tr("UI_INFO_GENERATION_FINISHED") + " (" + str(accumulative_time) + "s)", true)
	ui.animation_player.play("ui_black_fade")
	get_tree().paused = false
	poly_gen.call_deferred("generate")


func _on_generate(seed_text: String, hex: bool, min_distance: int, max_tries: int, centroid_lerp: float):
	ui.generator_input_holder.visible = false
	if seed_text.length() > 0:
		if seed_text.is_valid_int():
			terrainator.terrain_seed = seed_text.to_int()
		else:
			terrainator.terrain_seed = seed_text.to_lower().hash()
	else:
		terrainator.terrain_seed = int(Time.get_unix_time_from_system())
	terrainator.sampling_mode = Terrainator.SamplingMode.HEX if hex else Terrainator.SamplingMode.POISSON_DISC
	terrainator.sampling_min_distance = min_distance
	terrainator.sampling_poisson_max_tries = max_tries
	terrainator.voronator_centroid_lerp = centroid_lerp
	ui.seed_label.terrain_seed = terrainator.terrain_seed
	generate()
