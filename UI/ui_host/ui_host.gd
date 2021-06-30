extends CanvasLayer


onready var gamemode_option_button = $MarginContainer/VBoxContainer/options_vbox/gamemode_panel_container/MarginContainer/VBoxContainer/gamemode_option_button

onready var room_code = $MarginContainer/VBoxContainer/options_vbox/room_code
onready var hide_button = $MarginContainer/VBoxContainer/hide_button
onready var options_vbox = $MarginContainer/VBoxContainer/options_vbox
onready var gamemode_panel = $MarginContainer/VBoxContainer/options_vbox/gamemode_panel_container
onready var abort_button = $MarginContainer/VBoxContainer/options_vbox/abort_button
onready var elimination_lives_spinbox = $MarginContainer/VBoxContainer/options_vbox/gamemode_panel_container/MarginContainer/VBoxContainer/elimination_hbox/elimination_lives_spinbox
onready var start_game_button = $MarginContainer/VBoxContainer/options_vbox/gamemode_panel_container/MarginContainer/VBoxContainer/start_game_button
onready var quit_button = $MarginContainer/VBoxContainer/options_vbox/quit_button
onready var confirm_quitting_button = $MarginContainer/VBoxContainer/options_vbox/confirm_quitting_button

var awaiting_quit_confirmation = false

func _ready():
	elimination_lives_spinbox.value = Global.elimination_max_lives

func set_room_code(value):
	room_code.set_code(value)

var shown = true

func _on_hide_button_pressed():
	shown = !shown
	if shown == false: hide_button.text = "MENU"
	else: hide_button.text = "HIDE"
	options_vbox.visible = shown


func _on_elimination_lives_spinbox_value_changed(value):
	Global.elimination_max_lives = value


func _on_start_game_button_pressed():
	Global.start_game()
	abort_button.visible = true
	gamemode_panel.visible = false


func _on_abort_button_pressed():
	Global.selected_game_mode = Global.GAME_MODE.lobby
	Global.start_game()
	abort_button.visible = false
	gamemode_panel.visible = true
	# when going back to lobby, elimination is selected by default 
	# for the next game
	Global.selected_game_mode = Global.default_game_mode

#func _process(delta):
#	confirm_quitting_button.visible = true
	
func _on_quit_button_pressed():
	print(awaiting_quit_confirmation)
	if awaiting_quit_confirmation == false:
		print(quit_button)
		quit_button.text = "CANCEL"
		confirm_quitting_button.visible = true
		awaiting_quit_confirmation = true
	elif awaiting_quit_confirmation == true:
		confirm_quitting_button.visible = false
		quit_button.text = "QUIT"
		awaiting_quit_confirmation = false


func _on_confirm_quitting_button_pressed():
	Global.quit_host_game()
