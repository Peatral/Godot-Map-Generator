extends Control

signal generate_pressed(seed_text: String)

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var info_text: RichTextLabel = $InfoText

@onready var seed_input_holder: CenterContainer = $SeedInputHolder
@onready var seed_input: LineEdit = $SeedInputHolder/SeedInputPanel/MarginContainer/VBoxContainer/SeedInput
@onready var generate_button: Button = $SeedInputHolder/SeedInputPanel/MarginContainer/VBoxContainer/GenerateButton
@onready var seed_label: Label = $SeedLabel

func _ready():
	seed_input.grab_focus()

func print_text(text, append=false, newline=true):
	if !append:
		info_text.text = text
	else:
		info_text.text += ("\n" if newline else "") + text

func _on_seed_copied():
	animation_player.play("ui_seed_copy")

func _on_generate_button_pressed():
	emit_signal("generate_pressed", seed_input.text)
