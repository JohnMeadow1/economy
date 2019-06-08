tool
#extends GameResource
extends "res://Scripts/base_classes/GameResource.gd"
class_name ResourceLocation

onready var name_label:Label = $name
onready var resource_name:String = name_label.text setget _set_resource_name, _get_resource_name
onready var sprite = $Sprite

export(ResourceType) var _resource_type:int = 0 setget _set_resource_type

func _ready():
	randomize()
#	generate()
	update_display()
	harvest_cost = max(1,harvest_cost)
	cycle = rand_range(0,cycle_length)
	sprite.material = sprite.material.duplicate()
	
func _set_resource_name(value):
	resource_name = value
	if has_node("name"):
		$name.text = value

func _get_resource_name():
	return resource_name

func _set_resource_type(value):
	_resource_type = value
	if value>=0:
		self.resource_name = ResourceName[value]
		if has_node("Sprite"):
			$Sprite.texture = load(ResourceSprites[value])
	else:
		self.resource_name = "null resource"
		if has_node("Sprite"):
			$Sprite.texture = load("res://Sprites/No_Resource.png")


func _physics_process(delta):
	if !Engine.is_editor_hint(): # do not calculate in editor
		cycle += delta
		if cycle > cycle_length:
			cycle -= cycle_length
			harvest()
			update_display()
			
func harvest():
	availible_fluctuations = availible
	stockpile_fluctuations = previosu_stockpile-stockpile
	previosu_stockpile = stockpile
	availible += regenerates_per_cycle
	var hervested = workers / harvest_cost + auto_harvest
	hervested = min( hervested, harvestable_per_cycle)   #limit by max harvestable
	hervested = min( hervested, availible)               #limit by max availible
	hervested = min( hervested, stockpile_max-stockpile) #limit by max storage
	stockpile += hervested
	availible -= hervested
	availible_fluctuations -= availible
	
	update_depletion(hervested)

func update_depletion(hervested):
	harvest_cost += availible_fluctuations * 0.1
	harvest_cost = clamp(harvest_cost, 1, harvest_cost_max)
	
func update_display():
	$values.text = str(round(availible))
	if availible_fluctuations <0: $values.text += " (+"+str(-round(availible_fluctuations*10)/10)+"/s)\n"
	else: $values.text += " ("+str(-round(availible_fluctuations*10)/10)+"/s)\n"
	$values.text += str(round(harvest_cost*100)/100)+"\n"
	$values.text += str(regenerates_per_cycle)+"\n"
	$values.text += str(workers)+"/"+str(worker_capacity)+"\n"
	$values.text += str(round(stockpile))+"/"+str(stockpile_max)
	if stockpile_fluctuations <0: $values.text += " (+"+str(-round(stockpile_fluctuations*10)/10)+"/s)\n"
	else: $values.text += " ("+str(-round(stockpile_fluctuations*10)/10)+"/s)\n"

func generate():
	availible = 50 * (randi() % 7 + 1)              # randi between 50 and 350 with 50 step
	regenerates_per_cycle = ceil(4 * randf()) + 1   # randf [1,5]
	worker_capacity = randi() % 10 + 11             # randi [11,20]
