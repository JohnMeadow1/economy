extends Node2D

var age
onready var camera = $Camera2D

func _ready():
	age = 0
	$GameAge.text = "Game Age: " + str(age)

func _process(delta):
	pass

func _on_Timer_timeout():
	update_main()
	update_villages()
	update_resources()


func update_main():
	age = age +1
	$GameAge.text = "Game Age: " + str(age)

func update_villages():
	for village in get_tree().get_nodes_in_group("villages"):
		village.update_village()

func update_resources():
	for resource in get_tree().get_nodes_in_group("resources"):
		resource.update_resource()