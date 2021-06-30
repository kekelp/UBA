extends CanvasLayer

onready var room_code = $MarginContainer/VBoxContainer/options_vbox/room_code
onready var hide_button = $MarginContainer/VBoxContainer/hide_button
onready var options_vbox = $MarginContainer/VBoxContainer/options_vbox


func set_room_code(value):
	room_code.set_code(value)

var shown = true

func _on_hide_button_pressed():
	shown = !shown
	if shown == false: hide_button.text = "MENU"
	else: hide_button.text = "HIDE"
	options_vbox.visible = shown


func _on_quit_button_pressed():
	Global.quit_host_game()

