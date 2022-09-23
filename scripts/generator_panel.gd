extends PanelContainer

signal generate(seed: String, min_distance: int, max_tries: int)

var seed := ""
var min_distance := 10
var max_tries := 10

func _on_seed_changed(new_text):
	seed = new_text

func _on_min_distance_changed(value):
	min_distance = value

func _on_max_tries_changed(value):
	max_tries = value

func _on_generate_button_pressed():
	emit_signal("generate", seed, min_distance, max_tries)
