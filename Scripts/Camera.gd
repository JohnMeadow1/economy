extends Camera2D

var previous_mause_possition =  get_global_mouse_position()
var previous_camera_position = position

#func _process(delta):
#	globals.debug.text += "MOUSE:\n" + str(get_local_mouse_position()) + "\n"

func _input(event):
	""" Mouse picking """

	if event is InputEventMouseMotion:
		handle_mouse_motion_event(event)

	if event is InputEventMouseButton:
		handle_mouse_button_event(event)

func handle_mouse_motion_event(event):
	if globals.mouse_button_pressed:
		if globals.selected_node:
			pass
		else:
			position = previous_camera_position + previous_mause_possition - get_local_mouse_position() 
#			previous_mause_possition = get_viewport().get_mouse_position()
	else:
#		previous_mause_possition = get_viewport().get_mouse_position()
#		globals.selected_node = null
#		get_object_near_mouse()
		pass

func handle_mouse_button_event(event):
	if event.pressed:
		if event.button_index == BUTTON_WHEEL_UP:
			zoom -= globals.ZOOM_SPEED
			position += get_local_mouse_position() * 0.1
		elif event.button_index == BUTTON_WHEEL_DOWN:
			zoom += globals.ZOOM_SPEED
			position += get_local_mouse_position() * 0.1
		else:
			globals.mouse_button_pressed = true
			previous_mause_possition = get_local_mouse_position()
			previous_camera_position = position
			globals.selected_node = null
			get_object_near_mouse()

	else:
		globals.mouse_button_pressed = false
		globals.selected_node = null

func get_object_near_mouse():
	for node in get_tree().get_nodes_in_group("selectable"):
		if get_global_mouse_position().distance_to(node.position) < globals.SELECTION_RANGE:
			globals.selected_node = node

