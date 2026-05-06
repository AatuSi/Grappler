extends CharacterBody2D

@export var jump_force = -200.0
@export var horizontal_speed = 200.0
@export var damage = 150
@export var jump_damage = 250
@export var jump_range = 300
@export var fatal_fall_speed = 600.0
@export var respawn_range_y = 300
@export var requires_LOS = true
@export var is_alive = true

@onready var jump_timer = $JumpTimer

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var player = null
var sword = null
var is_jumping = false
var respawn_pos
var last_frame_velocity_y = 0.0

func _ready():
	player = Globals.player
	sword = Globals.sword
	if not is_alive:
		death()
	else:
		$AnimationTree["parameters/conditions/is_dead"] = false
	respawn_pos = global_position

func _process(delta: float) -> void:
	if player.global_position.y - global_position.y >= respawn_range_y:
		respawn()

func _physics_process(delta):
	if is_alive:
		# 1. Apply Gravity
		if not is_on_floor():
			velocity.y += gravity * delta
			$AnimationTree["parameters/conditions/is_jumping"] = true
			$AnimationTree["parameters/conditions/is_idle"] = false
			is_jumping = true
			last_frame_velocity_y = velocity.y
		elif last_frame_velocity_y >= fatal_fall_speed:
			last_frame_velocity_y = 0
			death()
		else:
			# Stop horizontal movement when landing
			if velocity.y >= 0: 
				velocity.x = 0
			$AnimationTree["parameters/conditions/is_jumping"] = false
			$AnimationTree["parameters/conditions/is_idle"] = true
			is_jumping = false
		move_and_slide()

func _on_jump_timer_timeout():
	var distance = global_position.distance_to(player.global_position)
	if is_on_floor() and player and is_alive and distance <= jump_range and has_line_of_sight():
		hop_toward_player()

func hop_toward_player():
	$AudioStreamPlayer2D.play()
	# Calculate direction (Left or Right)
	var direction = sign(player.global_position.x - global_position.x)
	
	# Flip the sprite to face the player
	$AnimatedSprite2D.flip_h = direction > 0
	
	# Apply the launch forces
	velocity.y = jump_force
	velocity.x = direction * horizontal_speed
	
	# --- ADD VARIANCE HERE ---
	# Pick a random wait time between 1.0 and 3.5 seconds
	jump_timer.wait_time = randf_range(1.0, 3.5)
	
	# Restart the timer with the new wait time
	jump_timer.start()

func has_line_of_sight() -> bool:
	if player == null:
		return false
	
	if not requires_LOS:
		return true
	
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

# Inside the Frog script or a shared Hitbox script
func calculate_knockback_vector(player_pos: Vector2):
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
	
	# 3. Multiply by the innate force of the frog
	var knockback_force
	if is_jumping:
		knockback_force = direction * jump_damage
	else:
		knockback_force = direction * damage
	return knockback_force


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body == player and is_alive:
		player.update_active_force(calculate_knockback_vector(player.global_position))


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area == sword and is_alive:
		death()
	
func respawn():
	$AnimationTree["parameters/conditions/is_dead"] = false
	$AnimationTree["parameters/conditions/is_idle"] = true
	is_alive = true
	move_to_respawn_pos()
	velocity.y = 0
	velocity.x = 0

func move_to_respawn_pos():
	global_position = respawn_pos

func death(play_sound = true):
	if play_sound:
		$AudioStreamPlayer2D2.play()
	$AnimationTree["parameters/conditions/is_jumping"] = false
	$AnimationTree["parameters/conditions/is_idle"] = false
	$AnimationTree["parameters/conditions/is_dead"] = true
	is_alive = false
