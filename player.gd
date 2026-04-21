extends CharacterBody2D

@export var movespeed = 150
@export var jumpspeed = -400
@export var attack_queued = false
# @export var acceleration = 15
# @export var deceleration = 150
# @export var air_deceleration = 50

@onready var player_animation_tree = $AnimationTree
@onready var sword_animation_tree = $Sword/AnimationTree

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Attack"):
		attack_queued = true
		handle_attack_logic()
	update_animation_parameters()

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
	
	move_and_slide()


func handle_attack_logic():
	var playback = sword_animation_tree.get("parameters/playback")
	var current_node = playback.get_current_node()
	
	if current_node == "Idle":
		playback.travel("Swing1")
		attack_queued = false # Reset after consuming
	elif (current_node == "Swing1" or current_node == "Swing2") and attack_queued:
		# We don't travel immediately; we let the AnimationTree 
		# check the condition at the end of the animation
		sword_animation_tree.set("parameters/conditions/combo", true)
		sword_animation_tree.set("parameters/conditions/not_combo", false)

func reset_combo_flag():
	attack_queued = false
	sword_animation_tree.set("parameters/conditions/combo", false)
	sword_animation_tree.set("parameters/conditions/not_combo", true)

func update_animation_parameters():
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
