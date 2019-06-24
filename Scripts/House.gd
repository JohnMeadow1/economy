tool
extends "res://Scripts/base_classes/Dwelling.gd"
class_name House


onready var peasant = load("res://Nodes/Peasant.tscn")
onready var name_label: Label = $name
onready var house_name: String = name_label.text setget _set_house_name, _get_house_name
onready var sprite = $Sprite


export(SettlementType) var _settlement_type:int = 0 setget _set_settlement_type


const SPAWN_DELAY: float = 0.035


var CYCLE_DURATION: float = -1.0
var RAD_SQ: int = -1
var neighbours: Array = []


func _ready():
	if !Engine.is_editor_hint():
		CYCLE_DURATION = get_node("/root/Main").CYCLE_DURATION
	randomize()
#	generate()
#	self.house_name += "_" + str(get_index())
	RAD_SQ = pow(radius, 2)
	prepare_population_arrays()
#	woip population_birth_multiplier = clamp(FOOD/FOOD_REQ, 0.5, 0.15) + clamp(HOUSING - HOUSING_REQ, 0, 1)
	#HACK nie wiem czy tak chcemy: fill start POPULATION_by_age based on total "population" 
	fill_POPULATION_by_age(population)
	population_idle = population
	detect_neighbours()
	sort_neighbours()
	create_cost_labels()
	update_display()
	sprite.material = sprite.material.duplicate()


func _set_house_name(value):
	house_name = value
	if has_node("name"):
		$name.text = value + "_" + str(get_index())


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
	if !Engine.is_editor_hint():
		cycle += delta
		if cycle > CYCLE_DURATION:
			cycle -= CYCLE_DURATION
			update_village()


func update_village():
	collect_resources()
	consider_aging()
	consider_starving()
#	consider_birth()
	consumption_food = max (1, ceil(population/5)) # umarłe osady nie odżywają
	consider_aging()
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


func delegate_workers(location: ResourceLocation):
	convert_harvesters_to_transporters(location)
	
	if population_needed_for_transport_this_cycle == 0:
		if location.available > 1:
			if location.workers_total < location.worker_capacity:
				var worker_allocation = location.worker_capacity - location.workers_total
				#zarezerwowanych nie wysylam do pracy
				worker_allocation = min(worker_allocation, population_idle - population_reserved_for_transport)
				population_idle  -= worker_allocation
				location.workers_total += worker_allocation
				neighbours[find_neighbour_idx(location)][2] += worker_allocation##
				population_collecting += worker_allocation
		elif neighbours[find_neighbour_idx(location)][2] != 0:##
			population_collecting -= neighbours[find_neighbour_idx(location)][2]##
			population_idle += neighbours[find_neighbour_idx(location)][2]##
			location.workers_total -= neighbours[find_neighbour_idx(location)][2]##
			neighbours[find_neighbour_idx(location)][2] = 0##


func convert_harvesters_to_transporters(location: ResourceLocation):
	if population_needed_for_transport_this_cycle > 0:
		var workers = neighbours[find_neighbour_idx(location)][2] # var workers dla przejrzystości
		#edycja: zastępuję location.workers_total przez workers
		if workers > 0:##
			if workers >= population_needed_for_transport_this_cycle:##
				workers -= population_needed_for_transport_this_cycle##
				neighbours[find_neighbour_idx(location)][2] -= population_needed_for_transport_this_cycle
				location.workers_total -= population_needed_for_transport_this_cycle
				population_collecting -= population_needed_for_transport_this_cycle
				# wliczam needed do idle, ale zapamiętuje jako reserved
				population_idle += population_needed_for_transport_this_cycle
				population_reserved_for_transport += population_needed_for_transport_this_cycle
				population_needed_for_transport_this_cycle = 0
			else:
				population_needed_for_transport_this_cycle -= workers##
				population_collecting -= workers##
				population_idle += workers##
				population_reserved_for_transport += workers##
				location.workers_total -= workers
#				workers = 0##
				neighbours[find_neighbour_idx(location)][2] = 0


func transport_resources(location: ResourceLocation):
	if location.stockpile > 0:
		var transport_cost: float = (position.distance_to(location.position) * 0.01)
		var workers_needed_for_max_transport: int = int(floor(location.stockpile * transport_cost)) # czemu nie ceil?
		var population_transporting: int = min(workers_needed_for_max_transport, population_idle)
		
		total_population_transporting_this_cycle += population_transporting
		send_peasants(location.position, population_transporting)
		population_idle -= population_transporting #niepewne okolice
		population_reserved_for_transport = max(0, population_reserved_for_transport - population_transporting)
		stockpile_food += population_transporting/transport_cost
		location.stockpile -= population_transporting/transport_cost
		
		population_needed_for_transport_next_cycle += workers_needed_for_max_transport
		population_needed_for_transport_next_cycle -= population_transporting


func find_neighbour_idx(location: ResourceLocation) -> int:
	for idx in range(neighbours.size()):
		if (neighbours[idx][0] as ResourceLocation) == location:
			return idx
	return -1


func generate():
	population = randi() % 100 + 1 # randi between 1 and 100
	stockpile_food = randi() % 150 + 251


#HACK ludzie pracy nie umierają
# gdyby mieli umierać to ~:
#dla wydobycia
#for neighbour in neighbours:
#	if neighbour[2] > 0:
#	neighbour[2] -= dead #tu i niżej max(0, value)
#	neighbour[0].workers -= dead
#	neighbour[0].workers_total -= dead
#	population -= dead
#	population_collecting -= dead #chyba

#dla zbieractwa

func consider_starving():
	if stockpile_food >= consumption_food: # dość jedzenia
		stockpile_food -= consumption_food
		if randf() < 0.5:
			population -= round(0.15 * population_idle)
			population_idle -= round(0.15 * population_idle)
		else:
			population -= round(0.1 * population_idle)
			population_idle -= round(0.1 * population_idle)
	else: # za mało jedzenia, ale nic nie zjadają
		if randf() < 0.5:
			population -= min(population_idle, max(1, floor(0.7 * population_idle)))
			population_idle -= min(population_idle, max(1, floor(0.7 * population_idle)))
#			population = max(0, population)
		else:
			population -= min(population_idle, max(1, floor(0.4 * population_idle)))
			population_idle -= min(population_idle, max(1, floor(0.4 * population_idle)))
#			population = max(0, population)


func consider_birth():
	if stockpile_food >= consumption_food: # dość jedzenia - rodzi się 10-15% pop
		stockpile_food -= consumption_food
		if randf() < 0.5:
			population_idle += max(1, floor(0.1 * population))
			population += max(1, floor(0.1*population))
		else:
			population_idle += max(1, floor(0.15 * population))
			population += max(1, floor(0.15 * population))
	else: # mało jedzenia - rodzi się 0-2% pop
		if randf() < 0.5:
			population_idle += round(0.02 * population)
			population += round(0.02 * population)


func consider_aging(): #NOTE kiedy powinni się starzeć? przed/po rodzeniu/umieraniu? Zakladam przed obydwoma
	var temp = 0
	population -= POPULATION_by_age[99]
	for i in range (99, 0, -1): # i = 99; i > 0; i--
		POPULATION_by_age[i] = POPULATION_by_age[i-1]
	POPULATION_by_age[0] = 0
	update()


func send_peasants(where: Vector2, how_much: int = 1):
	how_much = min(how_much, floor(0.5 * float(CYCLE_DURATION)/SPAWN_DELAY))
	for i in range(how_much):
		yield(get_tree().create_timer(SPAWN_DELAY), "timeout")
		var peasant_instance = peasant.instance()
		peasant_instance.position = Vector2.ZERO
		peasant_instance.destination = (where - position)
		var angle_rad = Vector2.RIGHT.angle_to(peasant_instance.destination)
		peasant_instance.rotation = angle_rad
		if angle_rad > 0.5 * PI and angle_rad < 1.5 * PI:
			peasant_instance.get_node("Sprite").set_flip_v(true)
		add_child(peasant_instance)


func prepare_population_arrays():
	prepare_array(POPULATION_by_age, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
#	prepare_array(POPULATION_food_req, 0.0, 0.7, 1.0, 1.0, 0.7, 0.5, 0.4, 0.3, 0.3, 0.3)
#	prepare_array(POPULATION_work_eff, 0.3, 0.6, 1.0, 1.0, 0.8, 0.5, 0.4, 0.3, 0.3, 0.3)
	prepare_array(POPULATION_death_rate, 0.3, 0.04, 0.03, 0.03, 0.05, 0.06, 0.07, 0.13, 0.14, 0.15) #NOTE Sumują się do 1, tak ma być? 
#	prepare_array(POPULATION_male_ratio, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5) # jak i kiedy modyfikowane
	
#	prepare_array(POPULATION_birth_rate, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
#	prepare_array(POPULATION_housing_req, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)


func prepare_array(array, v1_10, v11_20, v21_30, v31_40, v41_50, v51_60, v61_70, v71_80, v81_90, v91_100):
	array.resize(0)
	for i in range(0, 10): # od [0] = 1 do [9] = 10
		array.push_back(v1_10)
	for i in range(10, 20): # wiek 11 - 20
		array.push_back(v11_20)
	for i in range(20, 30): # wiek 21 - 30
		array.push_back(v21_30)
	for i in range(30, 40): # wiek 31 - 40
		array.push_back(v31_40)
	for i in range(40, 50): # etc
		array.push_back(v41_50)
	for i in range(50, 60):
		array.push_back(v51_60)
	for i in range(60, 70):
		array.push_back(v61_70)
	for i in range(70, 90):
		array.push_back(v71_80)
	for i in range(80, 90):
		array.push_back(v81_90)
	for i in range(90, 100):
		array.push_back(v91_100)


func detect_neighbours(): # array of triples (Reosurce Node, distance, amount of this settlement workers)
#	neighbours.clear()
	for resource in get_tree().get_nodes_in_group("resource"):
		var resource_idx = find_neighbour_idx(resource)
		if position.distance_squared_to(resource.position) < RAD_SQ:
			if resource_idx == -1: # jest a zasięgu, nie ma w tablicy -> dodaj
				#NOTE czym jest trzeci element tablicy ustawiony na 0 ?
				#NOTE jest napisane 6 linijek wyżej: ilość pracowników tej wioski wydobywających w danym sąsiedzie
				var triple = [resource, position.distance_to(resource.position), 0]
				neighbours.append(triple)
		else:
			if resource_idx != -1: # jest w tablicy, nie ma w zasięgu -> usuń i zabij pracowników, którym uciekł dom
				population_collecting -= neighbours[resource_idx][2]
#				population_idle += neighbours[resource_idx][2] # umieraja, wiec zamiast ich zwracac obnizam pop
				population -= neighbours[resource_idx][2]
				resource.workers_total -= neighbours[resource_idx][2]
#				neighbours[resource_idx][2] = 0 # niepotrzebne
				neighbours.remove(resource_idx)


func create_cost_labels():
	var node = Node2D.new()
	node.name = "CostLabels"
	node.z_index = 1
#	get_tree().get_root().call_deferred("add_child", node)
	add_child(node)
	for resource in get_tree().get_nodes_in_group("resource"):
		var label = Label.new()
		label.name = resource.name
		label.text = str(stepify(position.distance_to(resource.position), 0.1))
		label.rect_position = 0.5*(resource.position - position)
		label.add_font_override("font",load("res://Fonts/Jamma_13.tres"))
		node.add_child(label)


func update_cost_labels(node):
	for resource in get_tree().get_nodes_in_group("resource"):
		var label_node = get_node(node+"/"+resource.name) as Label
		label_node.text = str(stepify(position.distance_to(resource.position), 0.1))
		label_node.rect_position = 0.5*(resource.position - position)


func calculate_workers_share(our_workers: int, total_workers: int):
	if total_workers != 0:
		return str(stepify(100 * (float(our_workers)/total_workers), 0.01)) + "%"
	else:
		return "0%"


func neighbours_info():
	var temp: String = ""
	var index: int = 0
	for neighbour in neighbours:
		index += 1
		temp += str(index) + ". " + str(neighbour[0].resource_name) + "\n"
		temp += "Tansport cost = " + str(neighbour[1] * 0.01) + "\n"
		temp += "Occupying " + str(neighbour[2]) + " out of " + str(neighbour[0].worker_capacity) + " worker slots.\n"
		temp += "Our workers share = " + calculate_workers_share(neighbour[2], neighbour[0].workers_total) + "\n"
	return temp


"""Sort (2+)-dimensional array by 2nd value"""
class MyCustomSorter:
	static func sort(a, b):
		if a[1] < b[1]:
			return true
		return false


""" mean = mean human age, deviation in years too"""
func fill_POPULATION_by_age(pop, mean = 30, deviation = 5): # 68% [25, 35] 95% [20, 40], 99.7% [15, 45]
	var temp
	for i in range(pop):
		temp = gaussian(mean, deviation)
		POPULATION_by_age[int(clamp(temp, 0, 100))] += 1


func gaussian(mean, deviation):
	var x1 = null
	var x2 = null
	var w = null
	
	while true:
		x1 = rand_range(0, 2) - 1 # [-1, 1]
		x2 = rand_range(0, 2) - 1
		w = x1*x1 + x2*x2
		if 0 < w && w < 1:
			break
	w = sqrt(-2 * log(w)/w)
	return round(mean + deviation * x1 * w)


func sort_neighbours():
	neighbours.sort_custom(MyCustomSorter, "sort")


"""Return 'start'st/nd/rd/th cheapest resource, starting from 'start' index in sorted neighbours array"""
func get_cheapest_resource(start = 0) -> Node2D:
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
		# BUG OX and OY are rendered partially invisible after few update calls (best depicted with zoom > 2)
		draw_population_chart(2) # zoom parameter 


"""Called by _draw"""
func draw_population_chart(zoom: int = 1):
	var start_x  = 0
	var end_x    = 100
	var start_y  = 110
	var end_y    = 60
	draw_line(Vector2(start_x, start_y) , Vector2(end_x, start_y) , Color.white, 1.0) # OX
	draw_line(Vector2(start_x, start_y) , Vector2(start_x, end_y) , Color.white, 1.0) # OY
	for i in range(99):
		draw_line(Vector2(start_x + zoom*i, start_y - zoom*POPULATION_by_age[i]),\
		          Vector2(start_x + zoom*i + zoom*1, start_y - zoom*POPULATION_by_age[i+1]) , Color.white, 1)


"""Actualize settlement info displayed on scene; called by update_village"""
func update_display():
	$InfoTable/values.text = str(population_idle) +"/"+ str(population) +"\n"
	$InfoTable/values.text += str(population_collecting) +"/"+ str(total_population_transporting_this_cycle)+"\n"
	$InfoTable/values.text += str(floor(stockpile_food))+"\n"
	$InfoTable/values.text += str(consumption_food)+"/s\n"
	update_cost_labels("CostLabels")
	_set_settlement_type(clamp(population/50, 0, 3)) # population/50 to dzielenie intów, więc powinno obciąć: 0-49 to 0
	# 50-99 to 1, 100-149 to 2 i 150+ to 3


func on_hover_info():
	globals.debug.text += "\n" + $name.text + " RESOURCES\n" + neighbours_info() + "\n"
	globals.debug.text += "Golden law: " + str(population - population_idle) + " = "\
	                          + str(population_collecting + total_population_transporting_this_cycle) + "\n"
	globals.debug.text += "Pop needed this cycle: " + str(population_needed_for_transport_this_cycle) + "\n"
	globals.debug.text += "Pop Needed next cycle: " + str(population_needed_for_transport_next_cycle) + "\n"