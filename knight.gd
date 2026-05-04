extends CharacterBody2D


@export var horizontal_speed = 200.0
@export var contact_damage = 400
@export var sword_damage = 600
@export var respawn_range_y = 300
@export var walk_speed = 75
@export var attacking: bool = false
@export var health_points = 3


var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var player = null
var sword = null
var is_alive = true
var respawn_pos
var last_frame_velocity_y = 0.0
var direction = -1 # 1 represents moving right, -1 represents moving left


func _ready():
	player = Globals.player
	sword = Globals.sword
	$AnimationTree["parameters/conditions/is_dead"] = false
	$AnimationTree["parameters/conditions/is_walking"] = false
	$AnimationTree["parameters/conditions/is_idle"] = true
	$AnimationTree["parameters/conditions/is_attacking"] = false
	respawn_pos = global_position

func _process(delta: float) -> void:
	if player.global_position.y - global_position.y >= respawn_range_y:
		respawn()

func _physics_process(delta):
	
	if is_alive:
		# 1. Apply Gravity
		if not is_on_floor():
			velocity.y += gravity * delta
			$AnimationTree["parameters/conditions/is_walking"] = false
			$AnimationTree["parameters/conditions/is_idle"] = true
			
		elif global_position.distance_to(player.global_position) < 140 and sign(player.global_position.x - global_position.x) == direction:
			velocity.x = 0
			if not attacking:
				# 1. The animation isn't playing yet. Trigger it!
				$AnimationTree["parameters/conditions/is_walking"] = false
				$AnimationTree["parameters/conditions/is_idle"] = false
				$AnimationTree["parameters/conditions/is_attacking"] = true
			else:
				# 2. The animation IS playing. 
				# Turn the attack condition off and queue up the idle state.
				# (Because your transition is set to 'AtEnd', the engine will politely 
				# finish the sword swing before actually going back to idle).
				$AnimationTree["parameters/conditions/is_attacking"] = false
				$AnimationTree["parameters/conditions/is_idle"] = true
				
		elif not attacking:
			# Walk
			# If the enemy hits a wall OR if the RayCast stops detecting the floor
			if is_on_wall() or (is_on_floor() and not $EdgeDetector.is_colliding()):
				flip_direction()
	
			# 3. Apply horizontal movement
			velocity.x = direction * walk_speed
			
			$AnimationTree["parameters/conditions/is_attacking"] = false
			$AnimationTree["parameters/conditions/is_walking"] = true
			$AnimationTree["parameters/conditions/is_idle"] = false
		move_and_slide()

func flip_direction():
	# Reverse the movement direction
	direction *= -1
	
	# Flip the visual sprite (assumes default facing is right)
	#$AnimatedSprite2D.flip_h = direction > 0
	$SpritePivot.scale.x = -direction
	$SwordHitbox.scale.x = -direction
	
	# Move the RayCast to the other side of the enemy so it detects the new "front" edge
	$EdgeDetector.target_position.x *= -1


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



func _on_hitbox_body_entered(body: Node2D) -> void:
	if body == player and is_alive:
		player.update_active_force(calculate_knockback_vector(player.global_position, contact_damage))

func _on_sword_hitbox_body_entered(body: Node2D) -> void:
	if body == player and is_alive:
		player.update_active_force(calculate_knockback_vector(player.global_position, sword_damage))

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area == sword and is_alive:
		if health_points > 0:
			if $DamageTimer.is_stopped():
				health_points -= 1
				$SpritePivot/AnimatedSprite2D.modulate = Color.RED 
				$DamageTimer.start()
		else:
			death()

func _on_damage_timer_timeout() -> void:
	$SpritePivot/AnimatedSprite2D.modulate = Color.WHITE

func respawn():
	health_points = 3
	$AnimationTree["parameters/conditions/is_dead"] = false
	$AnimationTree["parameters/conditions/is_idle"] = true
	$AnimationTree["parameters/conditions/is_walking"] = false
	$AnimationTree["parameters/conditions/is_attacking"] = false
	is_alive = true
	move_to_respawn_pos()
	velocity.y = 0
	velocity.x = 0

func move_to_respawn_pos():
	global_position = respawn_pos

func death():
	$AnimationTree["parameters/conditions/is_walking"] = false
	$AnimationTree["parameters/conditions/is_idle"] = false
	$AnimationTree["parameters/conditions/is_dead"] = true
	$AnimationTree["parameters/conditions/is_attacking"] = false
	is_alive = false
