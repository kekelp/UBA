extends ParallaxBackground


func _ready():
	reset_y_offset()
	get_tree().get_root().connect("size_changed", self, "myfunc")

func reset_y_offset():
	var window_ywid = OS.window_size.y
	self.scroll_offset.y = - (872 - window_ywid)
	
	
func myfunc():
	reset_y_offset()


func _process(_delta):
	self.scroll_offset.x = self.get_viewport().get_canvas_transform().get_origin().x

