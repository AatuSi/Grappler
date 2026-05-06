extends Node2D 

func _ready():
	# 1. When the scene loads, check if the SaveManager has data for this world
	if SaveManager.game_data.has("world_state"):
		apply_scene_save_data(SaveManager.game_data["world_state"])

# Call this function whenever you want to save the game 
# (e.g., passing a checkpoint, pressing a save button, or quitting)
func trigger_save():
	# 1. Gather the current state of the enemies and spawn point
	var current_state = get_scene_save_data()
	
	# 2. Store it inside the global SaveManager dictionary
	SaveManager.game_data["world_state"] = current_state
	
	# 3. Tell the SaveManager to write the updated dictionary to the hard drive
	SaveManager.save_game()

# --- Functions from the previous step ---

func get_scene_save_data() -> Dictionary:
	var scene_data = {
		"spawn_x": $Player.position.x,
		"spawn_y": $Player.position.y,
		"enemies_state": {}
	}
	
	for child in get_children():
		if "is_alive" in child:
			scene_data["enemies_state"][child.name] = child.is_alive
			
	return scene_data

func apply_scene_save_data(loaded_data: Dictionary):
	if loaded_data.has("spawn_x") and loaded_data.has("spawn_y"):
		$Player.position = Vector2(loaded_data["spawn_x"], loaded_data["spawn_y"])
		
	if loaded_data.has("enemies_state"):
		var saved_enemies = loaded_data["enemies_state"]
		for child in get_children():
			if "is_alive" in child and saved_enemies.has(child.name):
				# Simply update the variable. Do NOT use queue_free().
				child.is_alive = saved_enemies[child.name]
				if not child.is_alive and child.has_method("death"):
					child.death(false)
