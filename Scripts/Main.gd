extends Node2D

var age

func _ready():
	age = 0
	$GameAge.text = "Game Age: " + str(age) # project settings > debug > Force FPS: 3

func _process(delta):
	age = age +1
	$GameAge.text = "Game Age: " + str(age)