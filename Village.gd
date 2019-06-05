extends Node2D

var vilName = "Settlement" #pozniej
var population
var neededFood
var gatheredFood
var radius = 5 #pozniej

onready var foodPlace = get_parent().get_node("Food")

signal harvesting

func _ready():
	generate()
	$Name.text = vilName
	update_display()

func _process(delta):
	start_harvest(foodPlace)
	consider_starving()
	neededFood = ceil(population/5)
	consider_birth()
	neededFood = ceil(population/5)
	update_display()


func start_harvest(location):
	if !is_connected("harvesting", location, "get_harvested"):
		connect("harvesting", location, "get_harvested")
	
	emit_signal("harvesting", self, population) 
	print(population, " people collecting food.\n")

func end_harvest(amount):
	gatheredFood += amount
	update_display()

func generate():
	randomize()
	population = randi() % 100 + 1 # randi between 1 and 100
	neededFood = ceil(population/5)
	gatheredFood = randi() % 150 + 251

func consider_starving():
	randomize()
	if gatheredFood >= neededFood: # dość jedzenia - ginie 2-3% pop
		gatheredFood -= neededFood
		if randf() < 0.5:
			population -= round(0.03*population)
		else:
			population -= round(0.02*population)
	else: # mało jedzenia - ginie 20-30% pop (ale nic nie zjadają, poki co)
		if randf() < 0.5:
			population -= max(5, floor(0.3*population))
			population = max(0, population)
		else:
			population -= max(5, floor(0.2*population))
			population = max(0, population)

func consider_birth():
	randomize()
	if gatheredFood >= neededFood: # dość jedzenia - rodzi się 10-15% pop
		gatheredFood -= neededFood
		if randf() < 0.5:
			population += max(1, floor(0.1*population))
		else:
			population += max(1, floor(0.15*population))
	else: # mało jedzenia - rodzi się 0-2% pop
		if randf() < 0.5:
			population += round(0.02*population)

func update_display():
	$Population.text = "Pop: " + str(population)
	$Radius.text = "Rad: " + str(radius)
	$NeededFood.text = "Eating: " + str(neededFood)
	$GatheredFood.text = "Possessing: " + str(gatheredFood)