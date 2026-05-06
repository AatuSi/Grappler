extends Control


var is_paused: bool = false:
	set = set_paused

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Pause"):
		is_paused = !is_paused
	
func set_paused(value: bool) -> void:
	is_paused = value
	get_tree().paused = is_paused
	visible = is_paused


func _on_resume_pressed() -> void:
	is_paused = false


func _on_save_pressed() -> void:
	$"../..".trigger_save()


func _on_quit_pressed() -> void:
	get_tree().quit()
