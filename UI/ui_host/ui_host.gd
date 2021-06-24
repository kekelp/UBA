extends CanvasLayer

onready var room_code_lineedit = $MarginContainer/VBoxContainer/options_vbox/PanelContainer/MarginContainer/VBoxContainer/room_code_lineedit
onready var hide_button = $MarginContainer/VBoxContainer/hide_button
onready var options_vbox = $MarginContainer/VBoxContainer/options_vbox
onready var gamemode_panel = $MarginContainer/VBoxContainer/options_vbox/gamemode_panel_container
onready var elimination_lives_spinbox = $MarginContainer/VBoxContainer/options_vbox/gamemode_panel_container/MarginContainer/VBoxContainer/elimination_hbox/elimination_lives_spinbox
onready var start_game_button = $MarginContainer/VBoxContainer/options_vbox/gamemode_panel_container/MarginContainer/VBoxContainer/start_game_button

func _ready():
	elimination_lives_spinbox.value = Global.elimination_max_lives

func set_room_code(value):
	room_code_lineedit.text = value

var shown = true

func _on_hide_button_pressed():
	shown = !shown
	if shown == false: hide_button.text = "MENU"
	else: hide_button.text = "HIDE"
	options_vbox.visible = shown


func _on_quit_button_pressed():
	Global.quit_host_game()



func _on_elimination_lives_spinbox_value_changed(value):
	Global.elimination_max_lives = value


func _on_start_game_button_pressed():
	Global.start_game()
