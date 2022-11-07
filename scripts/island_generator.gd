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
	terrainator.finished_stage.connect(func(message): ui.print_text(tr(message), true))
	terrainator.finished_generation.connect(gen_finished)
	terrainator.generation_error.connect(func(): ui.print_text(tr("UI_INFO_GENERATION_ERROR"), true))
	
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
