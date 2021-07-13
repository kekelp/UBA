extends PanelContainer

func appear(text: String):
	set_text(text)
	$AnimationPlayer.play("fade2")


func set_text(text: String):
	$Label.text = text
