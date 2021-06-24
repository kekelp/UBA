extends ParallaxBackground

func _process(_delta):
	self.scroll_offset.x = self.get_viewport().get_canvas_transform().get_origin().x
