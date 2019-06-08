extends Camera2D

onready var previous_mouse_possition = get_global_mouse_position()
onready var previous_camera_position = position

func _process(_delta):
	globals.debug.text += "MOUSE POSITION\nGlobal:" + str(get_global_mouse_position().floor())
	globals.debug.text += "\nLocal:" + str(get_local_mouse_position().floor())
	globals.debug.text += "\nViewport:" + str(get_viewport().get_mouse_position().floor()) + "\n"
#	globals.debug.text += "Prev:" + str(previous_camera_position.floor()) + "\n"
#	globals.debug.text += "Prev:" + str(previous_mouse_possition.floor()) + "\n"
#	globals.debug.text += "Prev:" + str(previous_camera_position + previous_mouse_possition - get_local_mouse_position().floor()) + "\n"

func _input(event):
	""" Mouse picking """

	if event is InputEventMouseMotion:
		handle_mouse_motion_event(event)

	if event is InputEventMouseButton:
		handle_mouse_button_event(event)

func handle_mouse_motion_event(event):
	if globals.mouse_button_pressed:
		if globals.selected_node: #something is selected
			globals.selected_node.position = get_global_mouse_position().floor()
			pass
		else: #nothing selected -> drag camera
			position = lerp(position,previous_camera_position + previous_mouse_possition - get_local_mouse_position(), 0.5)
	else: #camera hoverig
#		globals.selected_node = null
		get_object_near_mouse()

func handle_mouse_button_event(event):
	if event.pressed: 
		if event.button_index == BUTTON_WHEEL_UP:
			zoom -= globals.ZOOM_SPEED
			position += get_local_mouse_position() * 0.1
		elif event.button_index == BUTTON_WHEEL_DOWN:
			zoom += globals.ZOOM_SPEED
			position += get_local_mouse_position() * 0.1
		else: #button pressed -> check if got something selected
			globals.mouse_button_pressed = true
			previous_mouse_possition = get_local_mouse_position()
			previous_camera_position = position
#			get_object_near_mouse()
	else: # button released
		globals.mouse_button_pressed = false
		globals.selected_node = null

func get_object_near_mouse():
	var is_hoover = false
	for node in get_tree().get_nodes_in_group("selectable"):
		if get_global_mouse_position().distance_to(node.position) < globals.SELECTION_RANGE:
			is_hoover = true
			globals.selected_node = node
			node.sprite.material.set("shader_param/width", 1.0)
	if !is_hoover and globals.selected_node :
		globals.selected_node.sprite.material.set("shader_param/width", 0.0)
		globals.selected_node.update()
		globals.selected_node = null
