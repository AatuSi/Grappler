extends CharacterBody2D

@export var respawn_range_y = 300
@export var detection_range = 400
@export var wait_time: float = 3
@export var is_alive = true

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var arrow_scene = load("res://arrow.tscn")

var player = null
var sword = null
var respawn_pos
var last_frame_velocity_y = 0.0
var player_is_in_range = false




func _ready():
	player = Globals.player
	sword = Globals.sword
	respawn_pos = global_position
	if not is_alive:
		death()
	else:
		$AnimationPlayer.play("Idle")
	$Timer.wait_time = wait_time
	$Timer.start()
	

func _process(delta: float) -> void:
	# Calculate direction (Left or Right)
	if is_alive and player.global_position.distance_to(global_position) < detection_range and has_line_of_sight():
		player_is_in_range = true
		$Bow.rotation = global_position.angle_to_point(player.global_position)
	else:
		player_is_in_range = false
	var direction = sign(player.global_position.x - global_position.x)
	
	# Flip the sprite to face the player
	$BodySprite.flip_h = direction < 0
	if player.global_position.y - global_position.y >= respawn_range_y:
		respawn()

func _physics_process(delta):
	if is_alive:
		# 1. Apply Gravity
		if not is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()


# Inside the Frog script or a shared Hitbox script
func calculate_knockback_vector(player_pos: Vector2, damage):
	# 1. Get the raw direction (Player - Frog)
	var raw_direction = player_pos - global_position
	
	# 2. Normalize it 
	# This turns the vector length to 1.0, so only the direction remains.
	var direction = raw_direction.normalized()
	
	# --- ADD THE LIFT HERE ---
	# Subtract from Y to force an upward trajectory (-0.5 is a good starting point)
	direction.y -= 1.25

	
	# Re-normalize so the added Y doesn't artificially increase the total knockback distance
	#direction = direction.normalized()
	# -------------------------
	
	# 3. Multiply by damage
	var knockback_force = direction * damage
	return knockback_force

func has_line_of_sight() -> bool:
	if player == null:
		return false
		
	# Get the physics state of the current 2D world
	var space_state = get_world_2d().direct_space_state
	
	# Create the raycast parameters from the archer to the player
	var query = PhysicsRayQueryParameters2D.create(global_position, player.global_position)
	
	# CRITICAL: Exclude the archer and the player from the raycast!
	# Otherwise, the ray will hit the player's own hitbox and think the path is blocked.
	query.exclude = [self, player] 
	
	# Optional: If your tiles are on a specific physics layer (e.g., Layer 1), 
	# you can uncomment the line below and set the mask to only look for walls.
	query.collision_mask = 1 
	
	# Cast the ray
	var result = space_state.intersect_ray(query)
	
	# If the dictionary is empty, the ray hit nothing, meaning the path is clear.
	return result.is_empty()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area == sword and is_alive:
		death()

func _on_timer_timeout() -> void:
	if is_alive and player_is_in_range and has_line_of_sight():
		var arrow = arrow_scene.instantiate()
		arrow.global_position = global_position
		get_tree().get_root().add_child(arrow)
		$AudioStreamPlayer2D.play()
	$Timer.start()


func respawn():
	$AnimationPlayer.play("Idle")
	$Bow/Sprite2D.visible = true
	is_alive = true
	move_to_respawn_pos()
	velocity.y = 0
	velocity.x = 0

func move_to_respawn_pos():
	global_position = respawn_pos

func death(play_sound = true):
	if play_sound:
		$AudioStreamPlayer2D2.play()
	$AnimationPlayer.play("Death")
	$Bow/Sprite2D.visible = false
	is_alive = false
