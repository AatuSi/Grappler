extends CharacterBody2D

@export var jump_force = -400.0
@export var horizontal_speed = 200.0
@export var gravity = 980.0

var player = null
var is_jumping = false

func _ready():
	player = Globals.player

func _physics_process(delta):
	# 1. Apply Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		# Stop horizontal movement when landing
		velocity.x = move_toward(velocity.x, 0, horizontal_speed * delta)
		is_jumping = false

	move_and_slide()

func _on_jump_timer_timeout():
	if is_on_floor() and player:
		hop_toward_player()

func hop_toward_player():
	is_jumping = true
	
	# Calculate direction (Left or Right)
	var direction = sign(player.global_position.x - global_position.x)
	
	# Flip the sprite to face the player
	$Sprite2D.flip_h = direction < 0
	
	# Apply the launch forces
	velocity.y = jump_force
	velocity.x = direction * horizontal_speed
