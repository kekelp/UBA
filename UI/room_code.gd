extends PanelContainer

const COPIED = preload("res://UI/copied.tscn")

func set_code(newstring):
	$MarginContainer/VBoxContainer/room_code_lineedit.text = newstring
	say_copied()

func say_copied():
	var copied = COPIED.instance()
	self.add_child(copied)


func _on_room_code_lineedit_focus_entered():
	OS.set_clipboard($MarginContainer/VBoxContainer/room_code_lineedit.text) 
	say_copied()
