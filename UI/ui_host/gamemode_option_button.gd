extends OptionButton

var selected_game_mode = Global.GAME_MODE.elimination

func _ready():
	# the first one has to be Global.default_game_mode 
	add_item("elimination", Global.GAME_MODE.elimination)
#	add_item("pogeer", Global.GAME_MODE.elimination)

#	if Global.matchmatking_server_url == "ws://localhost:9080":
#		select(1)
#	elif Global.matchmatking_server_url == "ws://still-basin-28484.herokuapp.com:80":
#		select(0)


func _on_gamemode_option_button_item_selected(index):
	Global.online.dbline("poggers"+str(index))
	Global.selected_game_mode = self.selected_game_mode

