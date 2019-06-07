extends Node2D
class_name GameResource#, "res://Sprites/Rocks/Gray_Rock.png"

const RESOURCE_GRAIN = preload("res://Sprites/Plants/wheet.png")
const RESOURCE_WOOD = preload("res://Sprites/Farm/Tree_2_Side.png")
const RESOURCE_STONE = preload("res://Sprites/Rocks/Gray_Rock.png")
enum ResourceType{ NO_RESOURCE = -1, RESOURCE_GRAIN, RESOURCE_WOOD, RESOURCE_STONE }
var ResourceName = ["Food", "Wood", "Stone"]
var ResourceSprites = ["res://Sprites/Plants/wheet.png",
                       "res://Sprites/Farm/Tree_2_Side.png",
                       "res://Sprites/Rocks/Gray_Rock.png"]

export(float) var availible:float             = 10.0
export(float) var harvestable_per_cycle:float = 1.0
export(float) var harvest_cost:float          = 1.0
export(float) var auto_harvest:float          = 0.0
export(float) var regenerates_per_cycle:float = 0.0
export(float) var regeneration_cycle:float    = 0.0
export(int) var worker_capacity:int           = 1.0

var cycle:float     = 0.0 
var harvested:float = 0.0

func get_harvested(location, collectors):
#	if !is_connected("harvested", location, "end_harvest"):
#		connect("harvested", location, "end_harvest")
#
#	var amount = min(collectors/gatherCost, currAmount)
#	emit_signal("harvested", amount) 
#	print(amount, " food collected.")
#	currAmount = max(0, currAmount - collectors/gatherCost)
#	update_display()
	pass