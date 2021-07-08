extends OptionButton

var crosshair_spr = load("res://sprites/cursor2.png")
var neon_crosshair_spr = load("res://sprites/cursor.png")

var cursors = [ crosshair_spr, neon_crosshair_spr, null ]

func _ready():
	add_item("    crosshair     ", 0)
	add_item("neon crosshair", 1)
	add_item("     system       ", 2)
	select(0)


func _on_OptionButton_item_selected(index):
	if index == 0:
		Input.set_custom_mouse_cursor(crosshair_spr, 0, Vector2(32,32))
	if index == 1:
		Input.set_custom_mouse_cursor(neon_crosshair_spr, 0, Vector2(32,32))
	if index == 2:
		Input.set_custom_mouse_cursor(null, 0, Vector2(0,0))
	else: pass
