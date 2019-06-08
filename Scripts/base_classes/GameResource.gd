extends Node2D
class_name GameResource, "res://Sprites/Rocks/Gray_Rock_Mini.png"

enum ResourceType{ NO_RESOURCE = -1, GRAIN, WOOD, STONE }
var ResourceName = ["Food", "Wood", "Stone"]
var ResourceSprites = ["res://Sprites/Plants/Wheat.png",
                       "res://Sprites/Farm/Tree_2_Side.png",
                       "res://Sprites/Rocks/Gray_Rock.png"]

export(float) var availible: float             = 10.0
export(float) var harvestable_per_cycle: float = 1.0
export(float) var harvest_cost: float          = 1.0
export(float) var harvest_cost_max: float      = 10.0
export(float) var auto_harvest: float          = 0.0
export(float) var regenerates_per_cycle: float = 0.0
export(float) var cycle_length: float          = 1.0
export(float) var stockpile_max: float         = 10.0
export(float) var stockpile: float             = 1.0

export(int) var worker_capacity: int           = 1

var cycle: float     = 0.0 
var workers: int     = 0
var availible_fluctuations: float = 0.0
var stockpile_fluctuations: float = 0.0
var previosu_stockpile: float = 0.0
