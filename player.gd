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

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Attack"):
		attack_queued = true
		handle_attack_logic()
		
func _ready() -> void:
	Globals.player = self


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = jumpspeed
	
	var direction = Input.get_axis("Left", "Right")
	if direction:
		velocity.x = direction * movespeed
	else:
		velocity.x = move_toward(velocity.x, 0, movespeed)
		
	update_animation_parameters(direction)
	move_and_slide()


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

func update_animation_parameters(direction):
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
		
	if (velocity == Vector2.ZERO):
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
