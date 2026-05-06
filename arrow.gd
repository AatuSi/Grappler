extends Area2D

var target : Vector2				## Nuolen kohde
var direction : Vector2			## Normalisoitu suuntavektori kohteeseen
var distance : float				## Alkuperäinen etäisyys kohteeseen
var player = null

@export var inaccuracy = 0.1 	## Epätarkkuus, kasvaa suhteessa matkaann. 0 = tarkkaa
@export var speed = 700		## Nuolen nopeus
@export var arrow_damage = 300

# Laksetaan nuolen suunta ja rotaatio
func _ready() -> void:
	# Määritellään kohde (pelaaja), lisätään epätarkkuutta
	player = Globals.player
	target = player.global_position
	target += Vector2(
		global_position.distance_to(target) * randf_range(-1.0, 3.0) * inaccuracy,
		global_position.distance_to(target) * randf_range(-1.0, 1.0) * inaccuracy
	)
	
	# Normalisoitu suuntavektori kohteeseen
	direction = (target - global_position).normalized()
	
	# Alkuperäinen etäisyys kohteeseen
	distance = global_position.distance_to(target)
	
	# Käännetään nuoli osoittamaan kohteeseen
	rotation = global_position.angle_to_point(target)
	
# Inside the Frog script or a shared Hitbox script
func calculate_knockback_vector(player_pos: Vector2, damage):
	# 1. Get the raw direction (Player - Frog)
	var raw_direction = player_pos - global_position
	
	# 2. Normalize it 
	# This turns the vector length to 1.0, so only the direction remains.
	var knockback_direction = raw_direction.normalized()
	
	# --- ADD THE LIFT HERE ---
	# Subtract from Y to force an upward trajectory (-0.5 is a good starting point)
	direction.y -= 1.25

	
	# Re-normalize so the added Y doesn't artificially increase the total knockback distance
	#direction = direction.normalized()
	# -------------------------
	
	# 3. Multiply by damage
	var knockback_force = knockback_direction * damage
	return knockback_force

# Nuolen liikutus
func _physics_process(delta: float) -> void:
	if speed > 0:
		global_position += direction * speed * delta
	

# Osuman käsittely
func _on_body_entered(body: Node2D) -> void:
	if body == player:
		player.update_active_force(calculate_knockback_vector(player.global_position, arrow_damage))
	queue_free.call_deferred()
		


func _on_miss_timer_timeout() -> void:
	queue_free.call_deferred()
