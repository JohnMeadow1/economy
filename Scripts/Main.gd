extends Node2D


onready var gameAge = $HUD/Margin/HBoxContainer/Container/GameAge


const CYCLE_DURATION = 1.0


var age = 0
var timer = 0
var velocity = Vector2()


func _ready():
	globals.debug = $HUD/TextureRect/Label
	gameAge.text = "Game Age: " + str(age)


func _process(_delta):
	globals.debug.text = "Debug\n"
	timer += _delta
	if timer > CYCLE_DURATION:
		timer -= CYCLE_DURATION
		update_main()


#func _on_Timer_timeout():
#	update_main()
#	update_villages()
#	update_resources()


func update_main():
	age += 1
	gameAge.text = "Game Age: " + str(age)


#func update_villages():
#	for village in get_tree().get_nodes_in_group("villages"):
#		village.update_village()
#
#
#func update_resources():
#	for resource in get_tree().get_nodes_in_group("resources"):
#		resource.update_resource()