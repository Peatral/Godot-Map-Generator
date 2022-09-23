extends Control

signal generate(seed: String, min_distance: int, max_tries: int)

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var info_text: RichTextLabel = $InfoText

@onready var generator_input_holder: CenterContainer = $GeneratorInputHolder
@onready var seed_label: Label = $SeedLabel

func print_text(text, append=false, newline=true):
	if !append:
		info_text.text = text
	else:
		info_text.text += ("\n" if newline else "") + text

func _on_seed_copied():
	animation_player.play("ui_seed_copy")

func _on_generate(seed: String, min_distance: int, max_tries: int):
	emit_signal("generate", seed, min_distance, max_tries)
