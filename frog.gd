extends CharacterBody2D

@export var jump_force = -200.0
@export var horizontal_speed = 200.0
@export var damage = 150
@export var jump_damage = 250

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var player = null
var is_jumping = false

func _ready():
	player = Globals.player

func _physics_process(delta):
	# 1. Apply Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
		is_jumping = true
	else:
		# Stop horizontal movement when landing
		if velocity.y >= 0: 
			velocity.x = 0
		is_jumping = false

	move_and_slide()

func _on_jump_timer_timeout():
	if is_on_floor() and player:
		hop_toward_player()

func hop_toward_player():
	
	# Calculate direction (Left or Right)
	var direction = sign(player.global_position.x - global_position.x)
	
	# Flip the sprite to face the player
	$AnimatedSprite2D.flip_h = direction < 0
	
	# Apply the launch forces
	velocity.y = jump_force
	velocity.x = direction * horizontal_speed

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
	if body == player:
		player.update_active_force(calculate_knockback_vector(player.global_position))
