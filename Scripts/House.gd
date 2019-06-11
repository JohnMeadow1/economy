tool
extends "res://Scripts/base_classes/Dwelling.gd"
class_name House


onready var name_label:Label = $name
onready var house_name:String = name_label.text setget _set_house_name, _get_house_name
onready var sprite = $Sprite


export(SettlementType) var _settlement_type:int = 0 setget _set_settlement_type


const CYCLE_DURATION = 1.0


var RAD_SQ = pow(radius, 2)
var neighbours = []
var cycle: float = 0.0


func _ready():
	randomize()
	generate()
	$name.text = SettlementName[settlement_size] + "_" + str(get_index())
	population_idle = population
	detect_neighbours()
	sort_neighbours()
	create_cost_labels()
	update_display()
	sprite.material = sprite.material.duplicate()


func _set_house_name(value):
	house_name = value
	if has_node("name"):
		$name.text = value


func _get_house_name():
	return house_name


func _set_settlement_type(value):
	_settlement_type = value
	if value >= 0:
		self.house_name = SettlementName[value]
		if has_node("Sprite"):
			$Sprite.texture = load(SettlementSprites[value])
	else:
		self.house_name = "null settlement"
		if has_node("Sprite"):
			$Sprite.texture = load("res://Sprites/No_Resource.png")


func _process(delta):
	
	cycle += delta
	if cycle > CYCLE_DURATION:
		cycle -= CYCLE_DURATION
		update_village()


func update_village():
	collect_resources()
	consider_starving()
	consider_birth()
	consumption_food = ceil(population/5)
	update_display()
	pass


func collect_resources():
	var index = 0
	population_idle += total_population_transporting_this_cycle #here this cycle refers to previous cycle
	
	total_population_transporting_this_cycle = 0
	population_needed_for_transport_this_cycle = population_needed_for_transport_next_cycle
	population_needed_for_transport_next_cycle = 0
	while(population_idle > 0 and index < neighbours.size()):
#		print("Starting ", index+1, " harvest of ", get_parent().age, " year.")
		delegate_workers(get_cheapest_resource(index))
		transport_resources(get_cheapest_resource(index))
		index += 1
	population_reserved_for_transport = 0 # rezerwowanie jest podczas delegate na potrzeby transport tego cyklu


func convert_harvesters_to_transporters(location: ResourceLocation):
	if population_needed_for_transport_this_cycle > 0:
		if location.workers > 0:
			if location.workers >= population_needed_for_transport_this_cycle:
				location.workers -= population_needed_for_transport_this_cycle
				population_collecting -= population_needed_for_transport_this_cycle
				# wliczam needed do idle, ale zapamiętuje jako reserved
				population_idle += population_needed_for_transport_this_cycle
				population_reserved_for_transport += population_needed_for_transport_this_cycle
				population_needed_for_transport_this_cycle = 0
			else:
				population_needed_for_transport_this_cycle -= location.workers
				population_collecting -= location.workers
				population_idle += location.workers
				population_reserved_for_transport += location.workers
				location.workers = 0


func delegate_workers(location: ResourceLocation):
	convert_harvesters_to_transporters(location)
	
	if population_needed_for_transport_this_cycle == 0:
		if location.available > 1:
			if location.workers < location.worker_capacity:
				var worker_allocation = location.worker_capacity - location.workers
				#zarezerwowanych nie wysylam do pracy
				worker_allocation = min(worker_allocation, population_idle - population_reserved_for_transport)
				population_idle  -= worker_allocation
				location.workers += worker_allocation
				population_collecting += worker_allocation
				#TODO Send animated workers from house to location with distance/cycle_dur speed
		elif location.workers != 0:
			population_collecting -= location.workers
			population_idle  += location.workers
			location.workers = 0

func transport_resources(location: ResourceLocation):
	if location.stockpile > 0:
		var transport_cost = (position.distance_to(location.position) * 0.01)
		var workers_needed_for_max_transport = floor(location.stockpile * transport_cost)
		
		population_transporting = min(workers_needed_for_max_transport, population_idle)
		total_population_transporting_this_cycle += population_transporting
		population_idle -= population_transporting #niepewne okolice
		population_reserved_for_transport = max(0, population_reserved_for_transport - population_transporting)
		stockpile_food += population_transporting/transport_cost
		location.stockpile -= population_transporting/transport_cost
		
		population_needed_for_transport_next_cycle += workers_needed_for_max_transport
		population_needed_for_transport_next_cycle -= population_transporting


func generate():
	population = randi() % 100 + 1 # randi between 1 and 100
	stockpile_food = randi() % 150 + 251

#HACK ludzie pracy nie umierają
func consider_starving():
	if stockpile_food >= consumption_food: # dość jedzenia
		stockpile_food -= consumption_food
		if randf() < 0.5:
			population -= round(0.15*population_idle)
			population_idle -= round(0.15*population_idle)
		else:
			population -= round(0.1*population_idle)
			population_idle -= round(0.1*population_idle)
	else: # za mało jedzenia, ale nic nie zjadają
		if randf() < 0.5:
			population -= floor(0.7*population_idle)
			population_idle -=  floor(0.7*population_idle)
#			population = max(0, population)
		else:
			population -= floor(0.4*population_idle)
			population_idle -= floor(0.4*population_idle)
#			population = max(0, population)


func consider_birth():
	if stockpile_food >= consumption_food: # dość jedzenia - rodzi się 10-15% pop
		stockpile_food -= consumption_food
		if randf() < 0.5:
			population_idle += max(1, floor(0.1*population))
			population += max(1, floor(0.1*population))
		else:
			population_idle += max(1, floor(0.15*population))
			population += max(1, floor(0.15*population))
	else: # mało jedzenia - rodzi się 0-2% pop
		if randf() < 0.5:
			population_idle += round(0.02*population)
			population += round(0.02*population)


func detect_neighbours(): # array of pairs (Reosurce Node, distance + harvest cost)
	neighbours.clear()
	for resource in get_tree().get_nodes_in_group("resource"):
#		var distance = (resource.position - position).length_squared()
#		var distance = position.distance_squared_to(resource.position)
		if position.distance_squared_to(resource.position) < RAD_SQ:
			var pair = [resource, floor(position.distance_to(resource.position)) + resource.harvest_cost]
			neighbours.append(pair)


func create_cost_labels():
	var node = Node2D.new()
	node.name = "CostLabels"
#	get_tree().get_root().call_deferred("add_child", node)
	add_child(node)
	for resource in get_tree().get_nodes_in_group("resource"):
		var label = Label.new()
		label.name = resource.name
		label.text = str(stepify((resource.position - position).length(), 0.01))
		label.rect_position = 0.5*(resource.position - position)
		label.add_font_override("font",load("res://Fonts/Jamma_13.tres"))
		node.add_child(label)


func update_cost_labels(node):
	for resource in get_tree().get_nodes_in_group("resource"):
		var label_node = get_node(node+"/"+resource.name) as Label
		label_node.text = str(stepify((resource.position - position).length(), 0.01))
		label_node.rect_position = 0.5*(resource.position - position)


func neighbours_info():
	var temp: String = ""
	for neighbour in neighbours:
		temp += str(neighbour) + "\n"
	return temp


"""Sort 2-dimensional array by 2nd value"""
class MyCustomSorter:
	static func sort(a, b):
		if a[1] < b[1]:
			return true
		return false


func sort_neighbours():
	neighbours.sort_custom(MyCustomSorter, "sort")


func get_cheapest_resource(start = 0):
#	print (start+1, " cheapest resource is ", neighbours[start][0], " (", neighbours[start][0].resName, ") with total price = floor(0.01*distanceSQ) + gatherCost = ", neighbours[start][1])
	return neighbours[start][0]


func _draw():
	draw_circle(Vector2(0,0), radius, Color(0.55, 0, 0, 0.3))
	for resource in get_tree().get_nodes_in_group("resource"):
		var isNeighbour = false
		for i in range(neighbours.size()):
			if resource == neighbours[i][0]:
				isNeighbour = true
		if isNeighbour:
			draw_line(Vector2(0,0), resource.position - position, Color(0, 1, 0, 1), 3.0)
		else:
			draw_line(Vector2(0,0), resource.position - position, Color(1, 0, 0, 1), 3.0)


func update_display():
	$values.text = str(population_idle) +"/"+ str(population) +"\n"
	$values.text += str(population_collecting) +"/"+ str(total_population_transporting_this_cycle)+"\n"
	$values.text += str(floor(stockpile_food))+"\n"
	$values.text += str(consumption_food)+"/s\n"
	update_cost_labels("CostLabels")


func on_hoover_info():
	globals.debug.text += "\n" + $name.text + " RESOURCES\n" + neighbours_info() + "\n"
	globals.debug.text += "\nGolden law: " + str(population - population_idle) + " = " + str(population_collecting + total_population_transporting_this_cycle) + "\n"
	globals.debug.text += "\nPop needed this cycle: " + str(population_needed_for_transport_this_cycle) + "\n"
	globals.debug.text += "\nPop Needed next cycle: " + str(population_needed_for_transport_next_cycle) + "\n"