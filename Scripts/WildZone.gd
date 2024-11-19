extends Area2D

# Ensure this area detects the player
func _on_body_entered(body):
	if body.name == "Player":
		body._on_WildZone_body_entered(self)

func _on_body_exited(body):
	if body.name == "Player":
		body._on_WildZone_body_exited(self)
