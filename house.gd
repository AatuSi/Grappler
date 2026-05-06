extends Node2D

var player

func _ready():
	player = Globals.player
	$AnimationPlayer.play("Open")



func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == player:
		player.visible = false
		$AnimationPlayer.play("Closed")
		player.fade_to_black()
