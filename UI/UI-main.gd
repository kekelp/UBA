extends Control

onready var nav_history = [$root_vbox]



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func nav_to_child_subm(new_subm):
	nav_history[-1].visible = false
	nav_history.push_back(new_subm)
	nav_history[-1].visible = true

func nav_to_parent_subm():
	nav_history[-1].visible = false
	nav_history.pop_back()
	nav_history[-1].visible = true


func _on_back_button_pressed():
	nav_to_parent_subm()


func _on_ColorPicker_color_changed(color):
	Global.character_color = color

func _on_Name_text_changed(new_text):
	if new_text == "":
		Global.set_random_name()
	else:
		Global.character_name = new_text

func _on_room_code_text_changed(new_text):
	Global.room_code = new_text

func _on_create_button_pressed():
	Global.create_game()

func _on_join_button_pressed():
	Global.join_game()


func _on_max_players_spinbox_value_changed(value):
	Global.max_players = value
