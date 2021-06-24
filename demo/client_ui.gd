extends Control

var host: bool = false
var connected:bool = false

onready var own_char = get_tree().get_nodes_in_group("owned")[0]

enum NET_MODE {own_on_host, other_on_host, own_on_client, other_on_client}
var chars_by_id = {}

onready var client = $Client
var CHARACTER = preload("res://character/character.tscn")

func _ready():
	client.connect("lobby_joined", self, "_lobby_joined")
	client.connect("lobby_sealed", self, "_lobby_sealed")
	client.connect("connected", self, "_connected")
	client.connect("disconnected", self, "_disconnected")
	client.rtc_mp.connect("peer_connected", self, "_mp_peer_connected")
	client.rtc_mp.connect("peer_disconnected", self, "_mp_peer_disconnected")
	client.rtc_mp.connect("server_disconnected", self, "_mp_server_disconnect")
	client.rtc_mp.connect("connection_succeeded", self, "_mp_connected")


func _process(delta):
	# receive packets
	client.rtc_mp.poll()
	while client.rtc_mp.get_available_packet_count() > 0:
		var sender_id = client.rtc_mp.get_packet_peer()
		var packet = client.rtc_mp.get_packet().get_string_from_utf8()
#		_log(packet)
		var code = packet.left(1)
		var message = packet.right(1)
		if host == true:
			if code == "J":
				# client is joining, spawn his character
				var char_data = JSON.parse(message).result
				spawn_char(char_data, sender_id, NET_MODE.other_on_host)
			elif code == "I":
				# client is sending his input
				var remote_input = JSON.parse(message).result
				var sender_char = chars_by_id[str(sender_id)]
				sender_char.get_node("Controller").handle_input(remote_input)
		elif host == false:
			if code == "H":
				# spawn the images for all of the chars on host
				var chars_data_by_id = JSON.parse(message).result
				for id in chars_data_by_id:
					spawn_char(chars_data_by_id[id], id, NET_MODE.other_on_client)
			elif code == "P":
				var chars_pos_by_id = JSON.parse(message).result
				for id in chars_pos_by_id:
					if chars_by_id.has(str(id)):
						chars_by_id[str(id)].sync_position(chars_pos_by_id[str(id)])
			if code == "J":
				# another client is joining, spawn his character
				var char_data = JSON.parse(message).result
				spawn_char(char_data, sender_id, NET_MODE.other_on_client)

	# send packets
	if host == true && connected == true:
		# send positions to all peers
		client.rtc_mp.set_target_peer(client.rtc_mp.TARGET_PEER_BROADCAST)
		var keys = chars_by_id.keys()
		var chars_pos = {}
		for k in keys:
			chars_pos[k] = chars_by_id[k].get_character_position()
		var jstr = JSON.print(chars_pos)
		client.rtc_mp.put_packet(("P"+jstr).to_utf8())
	elif host == false && connected == true:
		# send input to host
		client.rtc_mp.set_target_peer(1)
		var input = own_char.get_node("Controller").input
		var jstr = JSON.print(input)
		client.rtc_mp.put_packet(("I"+jstr).to_utf8())



func _connected(id):
	_log("Signaling server connected with ID: %d" % id)


func _disconnected():
	connected = false
	# remove all remote chars
	for k in chars_by_id.keys():
		if k != str(client.rtc_mp.get_unique_id()):
			if chars_by_id.has(k) == true:
				chars_by_id[k].queue_free()
				chars_by_id.erase(k)
	_log("Signaling server disconnected: %d - %s" % [client.code, client.reason])


func _lobby_joined(lobby):
	# register own character in chars_by_id
	chars_by_id[str(client.rtc_mp.get_unique_id())] = own_char
	# decide if host or not
	var n_peers = client.rtc_mp.get_peers().size()
	if n_peers == 0:
		host = true
		connected = true
		_log("Created lobby %s" % lobby)
	else:
		_log("Joined lobby %s" % lobby)


func _lobby_sealed():
	_log("Lobby has been sealed")


func _mp_connected():
	### on client side, function will run when joining the host's game. 
	# set own character to own_on_client
	own_char.net_mode = NET_MODE.own_on_client
	# send own character data to everyone
	client.rtc_mp.set_target_peer(client.rtc_mp.TARGET_PEER_BROADCAST)
	var own_data = own_char.get_character_data()
	var jstr = JSON.print(own_data)
	client.rtc_mp.put_packet(("J"+jstr).to_utf8())
	# will receive data about characters on host (in _process)
	connected = true
	_log("Multiplayer is connected (I am %d)" % client.rtc_mp.get_unique_id())



func _mp_server_disconnect():
	if host == false:
		# remove all remote chars
		for k in chars_by_id.keys():
			if k != str(client.rtc_mp.get_unique_id()):
				if chars_by_id.has(k) == true:
					chars_by_id[k].queue_free()
					chars_by_id.erase(k)
		# stop being a client char 
		own_char.net_mode = NET_MODE.own_on_host
		print("own net mode ",own_char.net_mode)
#		connected = false
	_log("Multiplayer is disconnected (I am %d)" % client.rtc_mp.get_unique_id())

func _mp_peer_connected(id: int):
	### will run on host side whenever a client connects. 
	# send data about characters on host to the newly connected player
	client.rtc_mp.set_target_peer(id)
	var keys = chars_by_id.keys()
	var chars_data = {}
	for k in keys:
		if k != str(id):
			chars_data[k] = chars_by_id[k].get_character_data()
	var jstr = JSON.print(chars_data)
	client.rtc_mp.put_packet(("H"+jstr).to_utf8())
	# in _process, receive data about the connected client's char
	_log("Multiplayer peer %d connected" % id)


func _mp_peer_disconnected(id: int):
	if chars_by_id.has(str(id)) == true:
		chars_by_id[str(id)].queue_free()
		chars_by_id.erase(str(id))
	_log("Multiplayer peer %d disconnected" % id)


func _log(msg):
	print(msg)
	$VBoxContainer/TextEdit.text += str(msg) + "\n"


func ping():
	_log(client.rtc_mp.put_packet("ping".to_utf8()))
	_log(client.rtc_mp.get_unique_id())


func _on_Peers_pressed():
	var d = client.rtc_mp.get_peers()
	_log(d.keys())
	_log("chars by id: ")
	_log(chars_by_id)
#	for k in d:
#		_log(client.rtc_mp.get_peer(k).get("id"))

func start():
	client.start($VBoxContainer/Connect/Host.text, $VBoxContainer/Connect/RoomSecret.text)


func _on_Seal_pressed():
	client.seal_lobby()


func stop():
	client.stop()

func spawn_char(char_data, owner_id, net_mode):
	if chars_by_id.has(str(owner_id)) == false:
		var character = CHARACTER.instance()
		self.add_child(character)
		character.set_character_data(char_data)
		character.net_mode = net_mode
		character.control_mode = character.CONTROL_MODE.kbm_or_gamepad
		chars_by_id[str(owner_id)] = character



func _on_ColorPicker_color_changed(color):
	var own_char = get_tree().get_nodes_in_group("owned")[0]
	own_char.set_color(color)


func _on_TextEdit_text_changed():
	var own_char = get_tree().get_nodes_in_group("owned")[0]
	own_char.set_name($TextEdit.text)
