extends Node2D

var age

const WALK_SPEED = 400
const ZOOM_SPEED = Vector2(0.02, 0.02)
var velocity = Vector2()

onready var ghost = $Ghost
onready var camera = $Ghost/Camera2D
onready var gameAge = $HUD/MarginContainer/HBoxContainer/Container/GameAge

func _ready():
	age = 0
	gameAge.text = "Game Age: " + str(age)
	$Timer.wait_time = 0.5

func _physics_process(delta):
	
	velocity.x =  WALK_SPEED * (int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left")))
	velocity.y =  WALK_SPEED * (int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up")))
	camera.zoom += ZOOM_SPEED * (int(Input.is_action_pressed("zoom_out")) - int(Input.is_action_pressed("zoom_in")))
	ghost.move_and_slide(velocity)

func _on_Timer_timeout():
	update_main()
	update_villages()
	update_resources()

func update_main():
	age = age +1
	gameAge.text = "Game Age: " + str(age)

func update_villages():
	for village in get_tree().get_nodes_in_group("villages"):
		village.update_village()

func update_resources():
	for resource in get_tree().get_nodes_in_group("resources"):
		resource.update_resource()