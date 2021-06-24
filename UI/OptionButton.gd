extends OptionButton

var values = {1: "ws://localhost:9080", 0: "ws://still-basin-28484.herokuapp.com:80"}

func _ready():
	add_item("default", 0)
	add_item("localhost", 1)
	if Global.matchmatking_server_url == "ws://localhost:9080":
		select(1)
	elif Global.matchmatking_server_url == "ws://still-basin-28484.herokuapp.com:80":
		select(0)


func _on_OptionButton_item_selected(index):
	Global.matchmatking_server_url = values[index]
	print(Global.matchmatking_server_url)
