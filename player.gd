extends CharacterBody2D

@export var movespeed = 150
@export var jumpspeed = -400
@export var attack_queued = false
# @export var acceleration = 15
# @export var deceleration = 150
# @export var air_deceleration = 50

@onready var player_animation_tree = $AnimationTree
@onready var sword_animation_tree = $Sword/AnimationTree
@onready var sword_original_position_x = $Sword/CollisionShape2D.position.x

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

enum State { NORMAL, PHYSICS_SIM }
var current_state = State.NORMAL
var active_force: Vector2 = Vector2.ZERO
var spin_velocity: float = 0.0

func _ready() -> void:
	Globals.player = self


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("Debug"):
		if current_state == State.NORMAL:
			current_state = State.PHYSICS_SIM
			active_force = Vector2(600, 600)
		else:
			current_state = State.NORMAL
	match current_state:
		State.NORMAL:
			handle_player_input(delta)
		State.PHYSICS_SIM:
			apply_simulated_physics(delta, active_force)
			update_animation_parameters()
	move_and_slide()

func handle_player_input(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = jumpspeed
	
	var direction = Input.get_axis("Left", "Right")
	if direction:
		velocity.x = direction * movespeed
	else:
		velocity.x = move_toward(velocity.x, 0, movespeed)
	
	if Input.is_action_just_pressed("Attack"):
		attack_queued = true
		handle_attack_logic()
	
	update_animation_parameters(direction)

func update_active_force(force: Vector2):
	active_force += force
	current_state = State.PHYSICS_SIM
	# Calculate spin direction (Right push = clockwise, Left push = counter-clockwise)
	var spin_dir = sign(force.x)
	if spin_dir == 0: 
		spin_dir = 1 # Fallback if perfectly vertical
	
	# Set the initial spin speed based on how strong the hit was
	# The 0.03 multiplier scales the raw force down to a reasonable rotation speed
	spin_velocity = force.length() * 0.03 * spin_dir

## This function now applies a continuous force vector over time
func apply_simulated_physics(delta: float, applied_force: Vector2):
	# 1. Apply the Force (Acceleration)
	# We multiply by delta so the speed increase is consistent regardless of framerate
	velocity += applied_force
	
	# 2. Apply Natural Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# 3. Apply Friction/Damping
	# This prevents the force from accelerating the player to infinite speeds
	var friction = 150.0
	var ground_friction = 300
	if not is_on_floor():
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, ground_friction * delta)
	
	# 4. Spin
	$AnimatedSprite2D.rotation += spin_velocity * delta
	
	# Gradually slow down the spinning in the air, and stop it quickly on the ground
	var spin_damping = 5.0 if not is_on_floor() else 20.0
	spin_velocity = move_toward(spin_velocity, 0, spin_damping * delta)

	
	# 6. State Exit Condition
	# If the external force is gone and we've settled on the floor
	active_force = Vector2.ZERO
	if is_on_floor() and applied_force == Vector2.ZERO and velocity.length() < 10 and $LandingTimer.is_stopped():
		$LandingTimer.start()

func handle_attack_logic():
	var playback = sword_animation_tree.get("parameters/playback")
	var current_node = playback.get_current_node()
	
	if current_node == "Idle":
		playback.travel("Swing1")
		attack_queued = false # Reset after consuming
	elif (current_node == "Swing1") and attack_queued:
		# We don't travel immediately; we let the AnimationTree 
		# check the condition at the end of the animation
		sword_animation_tree.set("parameters/conditions/attacking", true)

func reset_combo_flag():
	attack_queued = false
	sword_animation_tree.set("parameters/conditions/attacking", false)

func update_animation_parameters(direction = 0):
	var player = $CollisionShape2D
	var player_sprite = $AnimatedSprite2D
	var sword = $Sword/CollisionShape2D
	var sword_sprite = $Sword/AnimatedSprite2D
	
	if Input.is_action_pressed("Up"):
		sword.position.x = 0
		sword.position.y = -sword_original_position_x
		sword.rotation_degrees = -90
		
		sword_sprite.position.x = 0
		sword_sprite.position.y = -sword_original_position_x
		sword_sprite.rotation_degrees = -90
	elif Input.is_action_pressed("Down"):
		sword.position.x = 0
		sword.position.y = sword_original_position_x
		sword.rotation_degrees = 90
		
		sword_sprite.position.x = 0
		sword_sprite.position.y = sword_original_position_x
		sword_sprite.rotation_degrees = 90
	else:
		if direction > 0:
			player_sprite.flip_h = false
			# Move it back to the right side
			sword.position.x = sword_original_position_x
			sword.position.y = 0
			sword.rotation_degrees = 0
			
			sword_sprite.position.x = sword_original_position_x
			sword_sprite.position.y = 0
			sword_sprite.rotation_degrees = 0
			sword_sprite.flip_v = false
			
			player.position.x = abs(player.position.x)
			player.rotation_degrees = 0
		if direction < 0:
			player_sprite.flip_h = true
			# Move it to the left side and rotate it
			sword.position.x = -sword_original_position_x
			sword.position.y = 0
			sword.rotation_degrees = 180
			
			sword_sprite.position.x = -sword_original_position_x
			sword_sprite.position.y = 0
			sword_sprite.rotation_degrees = 180
			sword_sprite.flip_v = true
			
			player.position.x = -abs(player.position.x)
			player.rotation_degrees = 180
		
	if current_state == State.PHYSICS_SIM:
		player_animation_tree["parameters/conditions/is_idle"] = false
		player_animation_tree["parameters/conditions/is_falling"] = true
		player_animation_tree["parameters/conditions/is_jumping"] = false
		player_animation_tree["parameters/conditions/is_walking"] = false
	elif (velocity == Vector2.ZERO):
		# Idle
		player_animation_tree["parameters/conditions/is_idle"] = true
		player_animation_tree["parameters/conditions/is_falling"] = false
		player_animation_tree["parameters/conditions/is_jumping"] = false
		player_animation_tree["parameters/conditions/is_walking"] = false
	elif (is_on_floor()):
		# Walking
		player_animation_tree["parameters/conditions/is_idle"] = false
		player_animation_tree["parameters/conditions/is_falling"] = false
		player_animation_tree["parameters/conditions/is_jumping"] = false
		player_animation_tree["parameters/conditions/is_walking"] = true
	else:
		# Jumping
		player_animation_tree["parameters/conditions/is_idle"] = false
		player_animation_tree["parameters/conditions/is_falling"] = false
		player_animation_tree["parameters/conditions/is_jumping"] = true
		player_animation_tree["parameters/conditions/is_walking"] = false
	


func _on_landing_timer_timeout() -> void:
	current_state = State.NORMAL
	$AnimatedSprite2D.rotation = 0
