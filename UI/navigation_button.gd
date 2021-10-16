extends Button

export (NodePath) var child_menu
onready var UI_main = get_tree().get_nodes_in_group("UI_main")[0]


func _ready():
	connect("pressed",self,"on_nav_button_pressed")

func on_nav_button_pressed():
	var destination = get_node(child_menu)
	if destination != null:
		UI_main.nav_to_child_subm(destination)
	
