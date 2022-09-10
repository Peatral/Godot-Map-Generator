extends Label

signal seed_copied()

var terrain_seed: int = 0 :
	set(value):
		terrain_seed = value
		text = tr("UI_INFO_SEED") % value

func _gui_input(event: InputEvent):
	if event.is_action_released("ui_click") && text.length() > 0:
		DisplayServer.clipboard_set(str(terrain_seed))
		emit_signal("seed_copied")
