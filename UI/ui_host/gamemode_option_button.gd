extends OptionButton

var selected_game_mode = Global.GAME_MODE.elimination

func _ready():
	add_item("elimination", Global.GAME_MODE.elimination)

#	if Global.matchmatking_server_url == "ws://localhost:9080":
#		select(1)
#	elif Global.matchmatking_server_url == "ws://still-basin-28484.herokuapp.com:80":
#		select(0)


func _on_OptionButton_item_selected(index):
	Global.selected_game_mode = self.selected_game_mode
