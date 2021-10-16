extends Control

onready var nav_history = [$root_vbox]

onready var texrect_color = $customize_vbox/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/PanelContainer/MarginContainer/HBoxContainer/TextureRectColor
onready var texrect_color2 = $customize_vbox/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/PanelContainer2/MarginContainer/HBoxContainer/TextureRectColor2




# Called when the node enters the scene tree for the first time.
func _ready():
	for vbox in get_children():
		vbox.visible = false
	$root_vbox.visible = true
	
	texrect_color.modulate = Color(Global.own_char_data.color)
	texrect_color2.modulate = Color(Global.own_char_data.color2)

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
	Global.change_char_color(color)

func _on_Name_text_changed(new_text):
	if new_text == "":
		Global.set_random_name()
	else:
		Global.change_char_name(new_text)

func _on_room_code_text_changed(new_text):
	Global.room_code = new_text

func _on_create_button_pressed():
	Global.create_game()

func _on_join_button_pressed():
	Global.join_game()


func _on_max_players_spinbox_value_changed(value):
	Global.max_players = value


func _on_quit_button_pressed():
	get_tree().notification(MainLoop.NOTIFICATION_WM_QUIT_REQUEST)
