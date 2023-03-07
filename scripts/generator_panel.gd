extends PanelContainer


signal generate(seed: String, hex: bool, min_distance: int, max_tries: int)


var seed := ""
var min_distance := 10
var max_tries := 10
var centroid_lerp := 0.1
var hex := false


func _on_seed_changed(new_text):
	seed = new_text


func _on_hex_toggled(value):
	hex = value
	
	$MarginContainer/VBoxContainer/PointDistributionInputHolder/HexInputHolder/HexInput.text = "UI_ON" if value else "UI_OFF"


func _on_min_distance_changed(value):
	min_distance = value


func _on_max_tries_changed(value):
	max_tries = value


func _on_centroid_lerp_changed(value):
	centroid_lerp = value


func _on_generate_button_pressed():
	emit_signal("generate", seed, hex, min_distance, max_tries, centroid_lerp)
