extends Node2D
class_name Peasant


var velocity = Vector2()
var speed = 200
var destination = Vector2()


func _ready():
	$Sprite/AnimationPlayer.play("run")

func _physics_process(delta):
	position += destination * delta #for "sening peasants" in one cycle they need to have velocity ~ distance_to_run
	if position.distance_to(destination) < 5:
		queue_free()

#func move_towards(pos: Vector2):
#	destination = pos
#	velocity = destination.normalized() * speed