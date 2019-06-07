tool
#extends GameResource
extends "res://Scripts/base_classes/GameResource.gd"
onready var name_label:Label = $name
onready var resource_name:String = name_label.text setget _set_resource_name, _get_resource_name

export(ResourceType) var _resource_type:int = 0 setget _set_resource_type

func _ready():
	randomize()
	generate()
	update_display()

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
			$Sprite.texture = load("res://icon.png")
			
			

func _physics_process(delta):
	cycle += delta
	if cycle > regeneration_cycle:
		cycle -= regeneration_cycle
		resolve_cycle()

func resolve_cycle():
	availible += regenerates_per_cycle
	harvested += auto_harvest
	
func update_display():
	$values.text = str(floor(availible))+"\n"
	$values.text += str(harvest_cost)+"\n"
	$values.text += str(regenerates_per_cycle)+"\n"
	$values.text += str(worker_capacity)+"\n"
	
func generate():
	availible = 50 * (randi() % 7 + 1)              # randi between 50 and 350 with 50 step
	regenerates_per_cycle = ceil(4 * randf()) + 1   # randf [1,5]
	worker_capacity = randi() % 10 + 11             # randi [11,20]
	
func harvest():
	pass