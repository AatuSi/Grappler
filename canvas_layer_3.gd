extends CanvasLayer

func _ready():
	if Globals.first_time:
		$AnimationPlayer.play("controls")
