extends Node2D
class_name Peasant


var velocity = Vector2()
var destination = Vector2()

var returning = false

func _ready():
	$Sprite/AnimationPlayer.play("run")

func _physics_process(delta):
	position += destination * delta #for "sending peasants" in one cycle they need to have velocity ~ distance_to_run
	if !returning:
		if position.distance_to(destination) < 5:
			destination = -destination
			$Sprite.set_flip_h(true)
			returning = true
	else:
		if position.distance_to(Vector2.ZERO) < 5:
			queue_free()

#func move_towards(pos: Vector2):
#	destination = pos
#	velocity = destination.normalized() * speed