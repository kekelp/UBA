extends CanvasLayer

func set_room_code(value):
	$MarginContainer/VBoxContainer/room_code_lineedit.text = value

var shown = true

func _on_hide_button_pressed():
	shown = !shown
	if shown == false: $MarginContainer/VBoxContainer/hide_button.text = "MENU"
	else: $MarginContainer/VBoxContainer/hide_button.text = "HIDE"
	$MarginContainer/VBoxContainer/room_code_label.visible = shown
	$MarginContainer/VBoxContainer/room_code_lineedit.visible = shown
	$MarginContainer/VBoxContainer/quit_button.visible = shown


func _on_quit_button_pressed():
	Global.quit_host_game()

