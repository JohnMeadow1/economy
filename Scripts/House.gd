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
var starving_factor: float = 0.5


func _ready():
	if !Engine.is_editor_hint():
		CYCLE_DURATION = get_node("/root/Main").CYCLE_DURATION
	randomize()
	RAD_SQ = pow(radius, 2)
	prepare_population_arrays()
#	woip population_birth_multiplier = clamp(FOOD/FOOD_REQ, 0.5, 0.15) + clamp(HOUSING - HOUSING_REQ, 0, 1)
	fill_POPULATION_by_age(population_total)
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


"""Calculate wf & fr, then collect. After that starving, accidents, aging birth. wf and fr updated (recalculated)
only at the beginning, population_total updated when changed. Population fluctuations recalcualted only at the beginning."""
func update_village():
	clear_harvesting_workforce()
	calculate_workforce()
	calculate_foodreq()
	collect_resources()
	consider_starving()#
	consider_accidents()#
	consider_aging()#
	consider_birth()#
	calculate_fluctuations()
	update_display()
	pass


func calculate_workforce():
	workforce = 0
	for i in range(100):
		workforce += POPULATION_by_age[i] * POPULATION_work_eff[i]
	calculated_workforce = workforce


func calculate_fluctuations():
	calculated_workforce_fluctuations = previous_calculated_workforce - calculated_workforce
	previous_calculated_workforce = calculated_workforce
	
	population_total_fluctuations = previous_population_total - population_total
	previous_population_total = population_total


func calculate_foodreq():
	foodreq = 0
	for i in range(100):
		foodreq += POPULATION_by_age[i] * POPULATION_food_req[i]
	consumption_food = max (1, foodreq) # umarłe osady nie odżywają


"""Harvest food, then harvest remaining res."""
func collect_resources():
	total_workforce_transporting_this_cycle = 0
	for neighbour in neighbours:
		if neighbour[0].resource_name == "Food":
			try_harvest(neighbour[0])
	for neighbour in neighbours:
		if neighbour[0].resource_name != "Food":
			try_harvest(neighbour[0])


#NOTE transport = move resource from one village to another
"""Need rework for village to village mode."""
#func try_transport(location: ResourceLocation):
#	pass
#	if workforce > 0 and location.stockpile > 0:
#		var transport_cost: float = (position.distance_to(location.position) * 0.002)
#		var workforce_needed_for_max_transport: float = location.stockpile * transport_cost
#		var workforce_transporting: float = min(workforce_needed_for_max_transport, workforce)
#
#		total_workforce_transporting_this_cycle += workforce_transporting#@
#		send_peasants(location.position, workforce_transporting)
#		workforce -= workforce_transporting
###		workforce_reserved_for_transport = max(0, workforce_reserved_for_transport - workforce_transporting)
#		stockpile_food += workforce_transporting/transport_cost
#		location.stockpile -= workforce_transporting/transport_cost
#
###		workforce_needed_for_transport_next_cycle += workforce_needed_for_max_transport
###		workforce_needed_for_transport_next_cycle -= workforce_transporting


#NOTE still nedd rework, changes in base classes (harvest+transport, still capacity)
"""Take resource from the given location and transport it to the village. Transport cost is affected by distance
and resource type (something like 'gathering cost')."""
func try_harvest(location: ResourceLocation):
	if workforce > 0 and location.available > 1:
		if location.workforce_total < location.workforce_capacity:
				
				var harvest_cost: float = (position.distance_to(location.position) * 0.002) * location._resource_excav_cost
				var max_workforce_allocation = location.workforce_capacity - location.workforce_total
				var workforce_needed_for_max_harvest: float = location.available * harvest_cost
				
				var workforce_allocation: float = min(workforce, workforce_needed_for_max_harvest)
				workforce_allocation = min(max_workforce_allocation, workforce_allocation)
				workforce -= workforce_allocation
				location.workforce_total += workforce_allocation #NOTE Zerowane co update wszystkim wioskom
				neighbours[find_neighbour_idx(location)][2] += workforce_allocation #NOTE Do poprawy ten 3 el tablicy
				workforce_collecting += workforce_allocation#@ juz nie collectiing
				
				send_peasants(location.position, workforce_allocation)
				stockpile_food += workforce_allocation/harvest_cost
				location.available -= workforce_allocation/harvest_cost


func clear_harvesting_workforce():
	for neighbour in neighbours:
		neighbour[2] = 0


func find_neighbour_idx(location: ResourceLocation) -> int:
	for idx in range(neighbours.size()):
		if (neighbours[idx][0] as ResourceLocation) == location:
			return idx
	return -1


func generate():
	population_total = randi() % 100 + 1 # randi between 1 and 100
	stockpile_food = randi() % 150 + 251


func consider_starving():
	if stockpile_food >= consumption_food: # dość jedzenia, nie rób nic
		stockpile_food -= consumption_food
	elif population_total > 0: # za mało jedzenia, zjadają co jest i umierają proporcjonalnie do brakującej żywności
		var food_missing = consumption_food - stockpile_food
		var consumption_food_missing_percentage = food_missing / consumption_food # need 100, got 70 so missing 30%
		stockpile_food = 0
		
		# brakuje 30%, więc umiera 30% * starvFactor POPULACJI a nie FOODREQ więc czasem więcej a czasem mniej
		
		var amount = max(1, floor(consumption_food_missing_percentage * starving_factor * population_total))
		for i in range(amount):
			kill_random_citizen() # do not decrease workforce and foodreq -> no need
		


func consider_birth(): #NOTE w/o birthrate for now, TODO
# how birthrate should work? pairs, age difference, or ignore
	var amount
	if stockpile_food >= consumption_food: # dość jedzenia - rodzi się 10 v 15% pop
		stockpile_food -= consumption_food
		if randf() < 0.5:
			amount = max(1, floor(0.1 * population_total))
			population_total += amount
			for i in range(amount):
				POPULATION_by_age[0] += 1
		else:
			amount = max(1, floor(0.15 * population_total))
			population_total += amount
			for i in range(amount):
				POPULATION_by_age[0] += 1
			
	else: # mało jedzenia - rodzi się 0 v 2% pop
		if randf() < 0.5:
			amount = round(0.02 * population_total)
			population_total += amount
			for i in range(amount):
				POPULATION_by_age[0] += 1


func consider_accidents(): 
# death should decrease workforce, but if we do not transprot or harvest
# later in this cycle, we can ignore it bec we recalculate at the beginning anyway
	for i in range(100):
		if POPULATION_by_age[i] > 0:
			var number_of_possible_accidents = POPULATION_by_age[i]
			for j in range(number_of_possible_accidents):
				if randf() < POPULATION_death_rate[i]:
					POPULATION_by_age[i] -= 1
					####### every death/birth should actualize workforce and food req? NOPE
					# workforce -= POPULATION_work_eff[i]
#					neighbour[0].workers_total -= 1 # czasami, ale to trzeba zerować co cykl i tak i nie trackujemy juz
					#######
					population_total -= 1


"""If sb somehow reacheas age of 100 years - sb need to die. Every person ages."""
func consider_aging(): # Assumption: aging after starving
	population_total -= POPULATION_by_age[99]
	for i in range (99, 0, -1): # i = 99; i > 0; i--
		POPULATION_by_age[i] = POPULATION_by_age[i-1]
	POPULATION_by_age[0] = 0
	update()


"""Decrement random cell in POPULATION_by_age by one, besides that affect population_total counter only.
The idea is to call this function in proper context, alongside with decreasement 
of corresponding variabiles."""
func kill_random_citizen():
	if population_total > 0:
		for i in range(10):
			var temp = randi() % 100
			if POPULATION_by_age[temp] > 0:
				POPULATION_by_age[temp] -= 1
				population_total -= 1
				return
		var a = 0
		var b = 99
		while(true): # if cannot find random age citizen in 10 attempts, kill youngest/oldest citizen
			if POPULATION_by_age[a] > 0:
				POPULATION_by_age[a] -= 1
				population_total -= 1
				return
			if POPULATION_by_age[b] > 0:
				POPULATION_by_age[b] -= 1
				population_total -= 1
				return
			a += 1
			b -= 1


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
	
#	POPULATION_food_req   = [0.0, 0.0, 0.0, 0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6,
#	                         0.7, 0.7, 0.7, 0.7, 0.7, 0.8, 0.8, 0.9, 0.9, 0.9, 
#	                         1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 
#	                         1.0, 1.0, 1.0, 1.0, 1.0, 0.9, 0.9, 0.9, 0.9, 0.9, 
#	                         0.8, 0.8, 0.8, 0.8, 0.8, 0.7, 0.7, 0.7, 0.7, 0.7,
#	                         0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6,
#	                         0.6, 0.6, 0.6, 0.6, 0.6, 0.5, 0.5, 0.5, 0.5, 0.5,
#	                         0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4,
#	                         0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 
#	                         0.3, 0.3, 0.3, 0.3, 0.3, 0.2, 0.2, 0.2, 0.2, 0.2]
	POPULATION_food_req   = [0.0, 0.0, 0.0, 0.0, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3,
	                         0.35, 0.35, 0.35, 0.35, 0.35, 0.4, 0.4, 0.45, 0.45, 0.45, 
	                         0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 
	                         0.5, 0.5, 0.5, 0.5, 0.5, 0.45, 0.45, 0.45, 0.45, 0.45, 
	                         0.4, 0.4, 0.4, 0.4, 0.4, 0.35, 0.35, 0.35, 0.35, 0.35,
	                         0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3,
	                         0.3, 0.3, 0.3, 0.3, 0.3, 0.25, 0.25, 0.25, 0.25, 0.25,
	                         0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2,
	                         0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 
	                         0.15, 0.15, 0.15, 0.15, 0.15, 0.1, 0.1, 0.1, 0.1, 0.1]
	
	POPULATION_work_eff   = [0.0, 0.0, 0.0, 0.0, 0.1, 0.2, 0.3, 0.4, 0.4, 0.4,
	                         0.5, 0.5, 0.6, 0.6, 0.7, 0.7, 0.8, 0.8, 0.9, 0.9,
	                         1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 
	                         1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 
	                         0.9, 0.9, 0.9, 0.9, 0.9, 0.8, 0.8, 0.8, 0.8, 0.8,
	                         0.7, 0.7, 0.7, 0.7, 0.7, 0.6, 0.6, 0.6, 0.6, 0.6,
	                         0.5, 0.5, 0.5, 0.5, 0.5, 0.4, 0.4, 0.4, 0.4, 0.4,
	                         0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3,
	                         0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3,  
	                         0.2, 0.2, 0.2, 0.2, 0.2, 0.1, 0.1, 0.1, 0.1, 0.1]
	
	POPULATION_death_rate = [0.25, 0.1, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 
	                         0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01,
	                         0.02, 0.02, 0.02, 0.02, 0.02, 0.02, 0.02, 0.02, 0.02, 0.02, 
	                         0.02, 0.02, 0.02, 0.02, 0.02, 0.02, 0.02, 0.02, 0.02, 0.02, 
	                         0.03, 0.03, 0.03, 0.03, 0.03, 0.03, 0.03, 0.03, 0.03, 0.03, 
	                         0.04, 0.04, 0.04, 0.04, 0.04, 0.04, 0.04, 0.04, 0.04, 0.04, 
	                         0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 
	                         0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 
	                         0.09, 0.09, 0.09, 0.09, 0.09, 0.09, 0.09, 0.09, 0.09, 0.09, 
	                         0.11, 0.13, 0.15, 0.17, 0.19, 0.21, 0.23, 0.25, 0.27, 0.30]
	
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


func detect_neighbours(): # array of triples (Reosurce Node, distance, amount of this settlement workforce)
#	neighbours.clear()
	for resource in get_tree().get_nodes_in_group("resource"):
		var resource_idx = find_neighbour_idx(resource)
		if position.distance_squared_to(resource.position) < RAD_SQ:
			if resource_idx == -1: # jest a zasięgu, nie ma w tablicy -> dodaj
				var triple = [resource, position.distance_to(resource.position), 0]
				neighbours.append(triple)
		else:
			if resource_idx != -1: # jest w tablicy, nie ma w zasięgu -> usuń i wyzeruj workforce? tylko po co w sumie
				resource.workforce_total -= neighbours[resource_idx][2]###
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
		temp += "Occupying " + str(neighbour[2]) + " out of " + str(neighbour[0].workforce_capacity) + " workforce space.\n"
		temp += "Our workforce share = " + calculate_workers_share(neighbour[2], neighbour[0].workforce_total) + "\n"
	return temp


"""Sort (2+)-dimensional array by 2nd value"""
class MyCustomSorter:
	static func sort(a, b):
		if a[1] < b[1]:
			return true
		return false


""" mean = mean human age, deviation in years too"""
func fill_POPULATION_by_age(pop, mean: float = 30.0, deviation: float = 5.0): # 68% [25, 35] 95% [20, 40], 99.7% [15, 45]
	var temp
	for i in range(pop):
		temp = gaussian(mean, deviation)
		POPULATION_by_age[int(clamp(temp, 0, 100))] += 1


func gaussian(mean, deviation) -> float:
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
	$InfoTable/values.text = str(population_total)
	if population_total_fluctuations < 0: $InfoTable/values.text += " (+" + str(-population_total_fluctuations)+")\n"
	else: $InfoTable/values.text += " (" + str(-population_total_fluctuations)+")\n"
	$InfoTable/values.text += str(stepify(calculated_workforce, 0.1))
	if calculated_workforce_fluctuations < 0: $InfoTable/values.text += " (+" +\
	                                                        str(-stepify(calculated_workforce_fluctuations, 0.1))+")\n"
	else: $InfoTable/values.text += " (" + str(-stepify(calculated_workforce_fluctuations, 0.1))+")\n"
#	$InfoTable/values.text += str(stepify(calculated_workforce - workforce, 0.1))+"\n"
	if calculated_workforce != 0:
		$InfoTable/values.text += str(stepify(100*((calculated_workforce - workforce)/calculated_workforce), 0.1))+"%\n"
	else:
		$InfoTable/values.text += "ALL DEAD\n"
	$InfoTable/values.text += str(stepify(stockpile_food, 0.1))+"\n"
	$InfoTable/values.text += str(stepify(consumption_food, 0.1))+"/s\n"
	update_cost_labels("CostLabels")
	_set_settlement_type(clamp(population_total/50, 0, 3)) # population_total/50 to dzielenie intów, więc powinno obciąć:
	# 0-49 to 0, 50-99 to 1, 100-149 to 2 i 150+ to 3




func on_hover_info():
	globals.debug.text += "\n*** " + $name.text + " ***\n"
	globals.debug.text += "population_total: " + str(population_total) + "\n"
	globals.debug.text += "Food: " + str(stockpile_food) + "\n"
	globals.debug.text += "Wood: " + str(stockpile_wood) + "\n"
	globals.debug.text += "Stone: " + str(stockpile_stone) + "\n"
	globals.debug.text += "\nNEARBY RESOURCES\n" + neighbours_info() + "\n"
#	                  + " = " + str(workforce_collecting + total_workforce_transporting_this_cycle) + "\n"