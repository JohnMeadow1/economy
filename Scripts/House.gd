extends "res://Scripts/base_classes/Dwelling.gd"
class_name House

onready var sprite = $Sprite

const CYCLE_DURATION = 1.0

var RAD_SQ = pow(radius, 2)
var neighbours = []
var cycle: float = 0.0

func _ready():
	randomize()
	generate()
	$name.text = SettlementNames[settlement_size]
	population_idle = population
	detect_neighbours()
	sort_neighbours()
	create_cost_labels()
	update_display()
	sprite.material = sprite.material.duplicate() #NOTE ?


func _process(delta):
	#HACK output docelowo w kamerze dla podświetlanego domku
	if Input.is_action_pressed("print_resources"):
		globals.debug.text += "\n" + str(self) + " RESOURCES\n" + neighbours_to_str() + "\n"
	
	cycle += delta
	if cycle > CYCLE_DURATION:
		cycle -= CYCLE_DURATION
		update_village()


func update_village():
	collect_resources()
	consider_starving()
	consumption_food = ceil(population/5)
	consider_birth()
	consumption_food = ceil(population/5)
	update_display()
	pass


func collect_resources():
	var index = 0
	population_idle += population_transporting
	population_transporting = 0
	while(population_idle > 0 and index < neighbours.size()):
#		print("Starting ", index+1, " harvest of ", get_parent().age, " year.")
		delegate_workers(get_cheapest_resource(index))
		transport_resources(get_cheapest_resource(index))
#		start_harvest(get_cheapest_resource(index))
		index += 1


func delegate_workers(location: ResourceLocation):
	if location.availible > 1:
		if location.workers < location.worker_capacity:
			var worker_allocation = location.worker_capacity - location.workers
			worker_allocation = min(worker_allocation, population_idle)
			population_idle  -= worker_allocation
			location.workers += worker_allocation
	else:
		population_idle  += location.workers
		location.workers = 0
		
func transport_resources(location: ResourceLocation):
	if location.stockpile > 0:
		#FIXME  Transport is not happening if all workers harvest
		var transport_cost = (position.distance_to(location.position) * 0.01)
		var worker_needed_for_max_transport = floor(location.stockpile * transport_cost )
		population_transporting = min(worker_needed_for_max_transport, population_idle)
		population_idle -= population_transporting
		stockpile_food += population_transporting/transport_cost
		location.stockpile -= population_transporting/transport_cost


func generate():
	population = randi() % 100 + 1 # randi between 1 and 100
	stockpile_food = randi() % 150 + 251


func consider_starving():
	if stockpile_food >= consumption_food: # dość jedzenia - ginie 2-3% pop
		stockpile_food -= consumption_food
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
	if stockpile_food >= consumption_food: # dość jedzenia - rodzi się 10-15% pop
		stockpile_food -= consumption_food
		if randf() < 0.5:
			population += max(1, floor(0.1*population))
		else:
			population += max(1, floor(0.15*population))
	else: # mało jedzenia - rodzi się 0-2% pop
		if randf() < 0.5:
			population += round(0.02*population)


func detect_neighbours(): # array of pairs (Reosurce Node, distance + gather cost)
	neighbours.clear()
	for resource in get_tree().get_nodes_in_group("resource"):
		var distance = (resource.position - position).length_squared()
		if distance < RAD_SQ:
			var pair = [resource, floor(0.01*distance) + resource.harvest_cost]
			neighbours.append(pair)


func create_cost_labels():
	var node = Node2D.new()
	node.name = "CostLabels"
#	get_tree().get_root().call_deferred("add_child", node)
	add_child(node)
	for resource in get_tree().get_nodes_in_group("resource"):
		var label = Label.new()
		label.name = resource.name
		label.text = str((resource.position - position).length())
		label.rect_position = 0.5*(resource.position - position)
		node.add_child(label)


func update_cost_labels(node):
	for resource in get_tree().get_nodes_in_group("resource"):
		var tmp = get_node(node).find_node(resource.name)
		# dlaczego null
		print(tmp)
#		tmp.text = str((resource.position - position).length())
#		tmp.rect_position = 0.5*(resource.position - position)


func neighbours_to_str():
	var temp: String = ""
	for neighbour in neighbours:
		temp += str(neighbour) + "\n"
	return temp


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
	$values.text += str(floor(stockpile_food))+"\n"
	$values.text += str(consumption_food)+"/s\n"
	update_cost_labels("CostLabels")
