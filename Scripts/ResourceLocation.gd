tool
extends "res://Scripts/base_classes/GameResource.gd"
class_name ResourceLocation


onready var name_label: Label = $name
onready var resource_name: String = name_label.text setget _set_resource_name, _get_resource_name
onready var sprite = $Sprite


export(ResourceType) var _resource_type:int = 0 setget _set_resource_type


var CYCLE_DURATION: float = -1.0


func _ready():
	if !Engine.is_editor_hint():
		CYCLE_DURATION = get_node("/root/Main").CYCLE_DURATION
	randomize()
#	generate()
	self.resource_name += "_" + str(get_index())
	update_display()
	harvest_cost = max(1, harvest_cost)
#	cycle = rand_range(0, cycle_length)
	sprite.material = sprite.material.duplicate()


func _set_resource_name(value):
	resource_name = value
	if has_node("name"):
		$name.text = value


func _get_resource_name():
	return resource_name


func _set_resource_type(value: int):
	_resource_type = value
	if value >= 0:
		self.resource_name = ResourceName[value]
		if has_node("Sprite"):
			$Sprite.texture = load(ResourceSprites[value])
	else:
		self.resource_name = "null resource"
		if has_node("Sprite"):
			$Sprite.texture = load("res://Sprites/No_Resource.png")


func set_resource_size(availabl: float):
	var sc = clamp(availabl/300, 1, 2.5) # 1 ~ 300-, 2 ~ 600, 2.5 ~ 750+
	$Sprite.scale = Vector2(sc, sc)


func _physics_process(delta):
	if !Engine.is_editor_hint(): # do not calculate in editor
		cycle += delta
		if cycle > CYCLE_DURATION:
			cycle -= CYCLE_DURATION
			harvest()
			update_display()


func harvest():
	available_fluctuations = available
	stockpile_fluctuations = previous_stockpile - stockpile
	previous_stockpile = stockpile
	available += regenerates_per_cycle
#	var hervested = workers_total / harvest_cost + auto_harvest
	var hervested = workforce_total / harvest_cost + auto_harvest
	hervested = min(hervested, harvestable_per_cycle)   #limit by max harvestable
	hervested = min(hervested, available)               #limit by max available
	hervested = min(hervested, stockpile_max-stockpile) #limit by max storage
	stockpile += hervested
	available -= hervested
	available_fluctuations -= available
	
	update_depletion(hervested)


func update_depletion(hervested):
	harvest_cost += available_fluctuations * 0.1
	harvest_cost = clamp(harvest_cost, 1, harvest_cost_max)


func update_display():
	$InfoTable/values.text = str(round(available))
	set_resource_size(available)
#	if available < 1: _set_resource_type(-1) # pomysl: opróżnione się zerują
	if available_fluctuations < 0: $InfoTable/values.text += " (+" + str(-round(available_fluctuations*10)/10) + "/s)\n"
	else: $InfoTable/values.text += " (" + str(-round(available_fluctuations*10)/10) + "/s)\n"
	$InfoTable/values.text += str(round(harvest_cost*100)/100) + "\n"
	$InfoTable/values.text += str(regenerates_per_cycle) + "\n"
#	$InfoTable/values.text += str(workers_total) + "/" + str(worker_capacity) + "\n"
	$InfoTable/values.text += str(workforce_total) + "/" + str(workforce_capacity) + "\n"
	$InfoTable/values.text += str(round(stockpile)) + "/" + str(stockpile_max)
	if stockpile_fluctuations <0: $InfoTable/values.text += " (+" + str(-round(stockpile_fluctuations*10)/10) + "/s)\n"
	else: $InfoTable/values.text += " (" + str(-round(stockpile_fluctuations*10)/10) + "/s)\n"

func generate():
	available = 50 * (randi() % 7 + 1)              # randi between 50 and 350 with 50 step
	regenerates_per_cycle = ceil(4 * randf()) + 1   # randf [1,5]
#	worker_capacity = randi() % 10 + 11             # randi [11,20]
