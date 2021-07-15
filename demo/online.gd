extends Control

var host: bool = false
var connected:bool = false

signal created_game
signal joined_game
signal left_game

onready var own_char = get_tree().get_nodes_in_group("owned")[0]
onready var connect_info_panel = get_tree().get_nodes_in_group("connect_info_panel")[0]

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

	self.connect("created_game",Global,"_on_online_created_game")
	self.connect("joined_game",Global,"_on_online_joined_game")
	self.connect("left_game",Global,"_on_online_left_game")

func _physics_process(delta):
#	for k in chars_by_id.keys():
#		print(chars_by_id[k], " ", chars_by_id[k].elim_lives)
	
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
				var spect_mode = !Global.is_game_mode_open()
				spawn_char(char_data, sender_id, NET_MODE.other_on_host, spect_mode)
				if spect_mode == true:
					connect_info_panel.appear("player "+char_data.name+" joined as spectator (game already in progress)" )
				else:
					connect_info_panel.appear("player "+char_data.name+" joined" )
					
			elif code == "I":
				# client is sending his input
				var remote_input = JSON.parse(message).result
				var sender_char = chars_by_id[str(sender_id)]
				sender_char.get_node("Controller").handle_input(remote_input)
		elif host == false:
			if code == "H":
				# spawn the images for all of the chars on host
				var chars_data_by_id = JSON.parse(message).result
				dbclear()
				for id in chars_data_by_id:
					spawn_char(chars_data_by_id[id], id, NET_MODE.other_on_client, false)
				setup_chars_for_new_gamemode(own_char.waiting_for_next_game)
			elif code == "P":
				# host is sending the positions of all characters
				var chars_pos_by_id = JSON.parse(message).result
#				dbclear()
				for id in chars_pos_by_id:
#					dbline("id: "+ str(id) )
					if chars_by_id.has(str(id)):
						chars_by_id[str(id)].sync_position(chars_pos_by_id[str(id)])
			elif code == "J":
				# another client is joining, spawn his character
				var char_data = JSON.parse(message).result
				var spect_mode = not Global.is_game_mode_open()
				if spect_mode == true:
					connect_info_panel.appear("player "+char_data.name+" joined as spectator (game already in progress)" )
				else:
					connect_info_panel.appear("player "+char_data.name+" joined" )
					
				spawn_char(char_data, sender_id, NET_MODE.other_on_client, spect_mode)
			elif code == "G":
				# host is sending game mode info
				var new_game_info = JSON.parse(message).result
				Global.update_game_info(new_game_info)
				print("RECEIVING ", new_game_info["mode"])
				setup_chars_for_new_gamemode(false)
			elif code == "M":
				# we joined mid-game so host is sending game mode info
				var new_game_info = JSON.parse(message).result
				Global.update_game_info(new_game_info)
				own_char.spectator_mode = not Global.is_game_mode_open()
				own_char.waiting_for_next_game = not Global.is_game_mode_open()
				
				if not Global.is_game_mode_open():
					connect_info_panel.appear("joined as spectator (game already in progress)" )
				else:
					connect_info_panel.appear("joined lobby" )
					
				
	# send packets
	if host == true && connected == true:
		# send positions to all peers
		client.rtc_mp.set_target_peer(client.rtc_mp.TARGET_PEER_BROADCAST)
		var keys = chars_by_id.keys()
		var chars_pos = {}
#		dbclear()
		for k in keys:
#			dbline("k "+str(k))
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
	Global.room_code = lobby
	if host == true:
		OS.set_clipboard(lobby)
		emit_signal("created_game")

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
	emit_signal("joined_game")


func _mp_server_disconnect():
	if host == false:
		leave_game()


func leave_game():
	connected = false
	# remove all remote chars
	for k in chars_by_id.keys():
			if chars_by_id.has(k) == true:
				if chars_by_id[k] != own_char:
					chars_by_id[k].queue_free()
					chars_by_id.erase(k)
				else:
					chars_by_id.erase(k)
	if host == true:
		host = false
	# ^ also remove self from the char list (since the id/key won't be 
	# the same next time)
	
	own_char.net_mode = NET_MODE.own_on_host
	Global.game_mode = Global.GAME_MODE.lobby
	if own_char.spectator_mode == true:
		own_char.respawn()
	emit_signal("left_game")

### for when a client joins mid-game
func send_current_game_info():
	var game_info = Global.get_game_info()
	var jstr = JSON.print(game_info)
	client.rtc_mp.put_packet(("M"+jstr).to_utf8())


func _mp_peer_connected(id: int):
	### will run on host side whenever a client connects. 
	client.rtc_mp.set_target_peer(id)
	# send him info about the currently running game
	send_current_game_info()
	# it's important that game info is sent before character info,
	# so that the client can run setup_chars_for_new_gamemode() 
	# at the end of the "H" message
	# send data about characters on host to the newly connected player

	var keys = chars_by_id.keys()
	var chars_data = {}
	for k in keys:
		if k != str(id):
			chars_data[k] = chars_by_id[k].get_character_data()
	var jstr = JSON.print(chars_data)
	client.rtc_mp.put_packet(("H"+jstr).to_utf8())
	# then, in _process, the host will receive data about the connected client's char
	
	_log("Multiplayer peer %d connected" % id)

func check_for_full_lobby():
	# seal the lobby if it's full
	Global.online.dbline("global.max_players "+str(Global.max_players))
	Global.online.dbline("current players "+str(chars_by_id.size())+"\n" )
			
	if chars_by_id.size() >= Global.max_players:
		client.seal_lobby()

func _mp_peer_disconnected(id: int):
	if chars_by_id.has(str(id)) == true:
		chars_by_id[str(id)].queue_free()
		chars_by_id.erase(str(id))

# there's currently no way to unseal the lobby. KEK!
#	if chars_by_id.size() < Global.max_players:
#		client.unseal_lobby()
		
	_log("Multiplayer peer %d disconnected" % id)


func host_start_game():
	# when starting match. send the info to everyone
	client.rtc_mp.set_target_peer(client.rtc_mp.TARGET_PEER_BROADCAST)
	var game_info = Global.get_game_info()
	var jstr = JSON.print(game_info)
	client.rtc_mp.put_packet(("G"+jstr).to_utf8())
	setup_chars_for_new_gamemode()

func setup_chars_for_new_gamemode(joined_mid = false):
	if Global.game_mode == Global.GAME_MODE.lobby:
		for k in chars_by_id.keys():
			# respawn the ones that were waiting
#			if chars_by_id[k].spectator_mode == true:
				chars_by_id[k].respawn()
				# remove all gamemode-specific ui and shit
				chars_by_id[k].hide_lives()
				
	elif Global.game_mode == Global.GAME_MODE.elimination:
		var new_elim_lives = Global.elimination_max_lives
		for k in chars_by_id.keys():
			if chars_by_id[k].waiting_for_next_game == true:
				if joined_mid:
					continue
			chars_by_id[k].elim_lives = new_elim_lives
			chars_by_id[k].respawn()
			chars_by_id[k].show_lives()




func _log(msg):
	print(msg)
#	$VBoxContainer/TextEdit.text += str(msg) + "\n"


func ping():
	_log(client.rtc_mp.put_packet("ping".to_utf8()))
	_log(client.rtc_mp.get_unique_id())



func start():
	client.start($VBoxContainer/Connect/Host.text, $VBoxContainer/Connect/RoomSecret.text)

func create_game():
	client.start(Global.matchmatking_server_url, "")

func join_game():
	client.start(Global.matchmatking_server_url, Global.room_code)

func _on_Seal_pressed():
	client.seal_lobby()

func stop():
	client.stop()
	leave_game()

func spawn_char(char_data, owner_id, net_mode, spect_mode):

	if chars_by_id.has(str(owner_id)) == false:
		var character = CHARACTER.instance()
		self.add_child(character)
		character.set_character_data(char_data)
		character.net_mode = net_mode
		character.control_mode = character.CONTROL_MODE.kbm_or_gamepad
		chars_by_id[str(owner_id)] = character
		if host == true:
			check_for_full_lobby()

onready var label = get_tree().get_nodes_in_group("debug")[0]
func dbline(message):
	if OS.is_debug_build():
		label.text += (str(message)+"\n")

func dbset(message):
	if OS.is_debug_build():
		label.text = (str(message)+"\n")

func dbclear():
	if OS.is_debug_build():
		label.text += "\n"

const ANNOUNCE_BANNER = preload("res://UI/announce_banner.tscn")
func announce(message):
	var announce_banner = ANNOUNCE_BANNER.instance()
	self.add_child(announce_banner)
	announce_banner.get_node("MarginContainer/PanelContainer/Label").text = message

func check_winner():
	if Global.game_mode == Global.GAME_MODE.elimination:
		var survivor
		var n_surv = 0
		for k in chars_by_id.keys():
			if chars_by_id[k].elim_lives >= 1:
				survivor = chars_by_id[k]
				n_surv += 1
		if n_surv == 1 && chars_by_id.keys().size() > 1:
			declare_winner(survivor)
		elif n_surv == 0:
			declare_no_winners()

func declare_winner(winner):
	dbclear()
	announce(winner.base_name + " WINS THE GAME!")

func declare_no_winners():
	dbclear()
	announce(" NO SURVIVORS!")

func _input(event):
	
	if OS.is_debug_build():
		if event.is_action_pressed("ui_debug"):
			Global.online.dbline("vis "+str(Global.spect_label.get_parent().visible))

			
	#		var label = get_tree().get_nodes_in_group("debug")[0]
	#		label.text += "\n"
	#		label.text += "CHARS:\n"
	#		for k in chars_by_id.keys():
	#			label.text += ("   ID "+ str(k)+" NAME "+chars_by_id[k].base_name)
	#			label.text += (" visible: "+ str(chars_by_id[k].visible))
	#			label.text += "\n"

