extends Node

const SAVE_PATH = "user://save_data.json"

# This holds EVERYTHING in your game. We will add a "world_state" key to it.
var game_data = {} 

func _ready():
	load_game() # Automatically read the file from disk when the game boots

func save_game():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	var json_string = JSON.stringify(game_data)
	file.store_string(json_string)
	file.close()
	print("Game Saved to disk!")

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		Globals.first_time = true
		return # No save file yet, start fresh

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(content) == OK:
		game_data = json.get_data()
