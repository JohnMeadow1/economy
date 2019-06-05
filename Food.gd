extends Node2D

var resName = "Food" #pozniej
var currAmount
var gatherCost = 4 #pozniej
var regenRate

signal harvested

func _ready():
	generate()
	$Name.text = resName
	update_display()
	

func _process(delta):
	currAmount += regenRate
	update_display()


func generate():
	randomize()
	currAmount = 50 * (randi() % 7 + 1) # randi between 50 and 350 with 50 step
	regenRate = ceil(4 * randf()) + 1 # randf [1,5]

func update_display():
	$CurrentAmount.text = "Available: " + str(floor(currAmount))
	$GatheringCost.text = "Cost: " + str(gatherCost)
	$RegenerationRate.text = "Replenishment: " + str(regenRate)

func get_harvested(location, collectors):
	if !is_connected("harvested", location, "end_harvest"):
		connect("harvested", location, "end_harvest")
	
	var amount = min(collectors/gatherCost, currAmount)
	emit_signal("harvested", amount) 
	print(amount, " food collected.")
	currAmount = max(0, currAmount - collectors/gatherCost)
	update_display()