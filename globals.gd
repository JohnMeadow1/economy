extends Node
"""
Globally Visible Singleton
"""
# gandle to debug label on HUD
var debug

# mouse variables
var mouse_button_pressed:bool = false
var selected_node:Node        = null
const SELECTION_RANGE         = 20
const ZOOM_SPEED = Vector2(0.02, 0.02)