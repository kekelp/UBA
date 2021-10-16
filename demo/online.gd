extends Control

var host: bool = false
var connected:bool = false

signal created_game
signal joined_game
signal left_game

onready var own_char = get_tree().get_nodes_in_group("owned")[0]
onready var connect_info_panel = get_tree().get_nodes_in_group("connect_info_panel")[0]


# THIS HAS TO BE IDENTICAL TO THE ONE IN CHAR (or TODO copy this into global)
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
#
#func _process(delta):
#	dbclear()
#	dbline(str(Engine.get_frames_per_second()))

func _process(delta):
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
				# client is joining, check if there's room for him
				if is_lobby_full() == false:
					#spawn his character
					var char_data = JSON.parse(message).result
					# correct char_data.active_mode coming from client, based on current gamemode:
					if Global.is_game_mode_open():
						char_data["active_mode"] = Global.ACTIVE_MODE.playing
						connect_info_panel.appear("player "+char_data.name+" joined" )
					else:
						char_data["active_mode"] = Global.ACTIVE_MODE.waiting_next_game
						connect_info_panel.appear("player "+char_data.name+" joined as spectator (game already in progress)" )
					# TODO also change name and color if someone has the same 
					
					spawn_char(char_data, sender_id, NET_MODE.other_on_host)
					
					# reply with a nice and exhaustive "H" message
					client.rtc_mp.set_target_peer(sender_id)
					# game info
					var game_info = Global.get_game_info()
					# info about all characters including the client's newly spawned one
					#     (since it got corrected)
					var keys = chars_by_id.keys()
					var chars_data = {}
					for k in keys:
						chars_data[k] = chars_by_id[k].get_character_data()
					# combine dicts and send
					var all_info = {}
					all_info["g"] = game_info
					all_info["c"] = chars_data
					var jstr = JSON.print(all_info)
					client.rtc_mp.put_packet(("H"+jstr).to_utf8())
					
					# also send out "A" messages to notify all other clients about the new one
					# (negative sender_id sends to everyone except sender_id)
					client.rtc_mp.set_target_peer(-sender_id)
					var sender_data = chars_by_id[str(sender_id)].get_character_data()
					# also pack in the sender id as a key
					var sender_data_with_id = {}
					sender_data_with_id[str(sender_id)] = sender_data
					var jstr2 = JSON.print(sender_data_with_id)
					client.rtc_mp.put_packet(("A"+jstr2).to_utf8())
				else:
					client.rtc_mp.put_packet(("N").to_utf8())
				
			elif code == "I":
				# client is sending his input
				var remote_input = JSON.parse(message).result
				var sender_char = chars_by_id[str(sender_id)]
				sender_char.get_node("Controller").handle_input(remote_input)
		elif host == false:
			if code == "H":
				# connection is accepted
				own_char.net_mode = NET_MODE.own_on_client
				connected = true
				emit_signal("joined_game")
				# unpack the message
				var all_info = JSON.parse(message).result
				var game_info = all_info["g"]
				var chars_data_by_id = all_info["c"]
				# update game mode
				Global.update_game_info(game_info)
				# go through all characters
				# spawn the images for all of the chars on host
				for id in chars_data_by_id:
					if chars_by_id.has(id):
						# own char. do not spawn a duplicate, but update the data 
						#    for corrections and spect mode
						chars_by_id[id].set_character_data(chars_data_by_id[id])
					else:
						spawn_char(chars_data_by_id[id], id, NET_MODE.other_on_client)
				# show nice alert (game mode should be synced by now)
				if not Global.is_game_mode_open():
					connect_info_panel.appear("joined as spectator (game already in progress)" )
				else:
					connect_info_panel.appear("joined lobby" )
			elif code == "N":
				connect_info_panel.appear("room is full!")
				client.stop()
			elif code == "P":
				# host is sending the positions of all characters
				var chars_pos_by_id = JSON.parse(message).result
#				dbclear()
				for id in chars_pos_by_id:
#					dbline("id: "+ str(id) )
					if chars_by_id.has(str(id)):
						chars_by_id[str(id)].sync_position(chars_pos_by_id[str(id)])
			elif code == "A":
				# host is sending the data for another client who joined, spawn his character
				var new_data_with_id = JSON.parse(message).result
				var idstring = new_data_with_id.keys()[0]
				var new_char_data = new_data_with_id[idstring]
				print(idstring)
				print(new_char_data)
				if new_char_data["active_mode"] == Global.ACTIVE_MODE.waiting_next_game:
					connect_info_panel.appear("player "+new_char_data.name+" joined as spectator (game already in progress)" )
				else:
					connect_info_panel.appear("player "+new_char_data.name+" joined" )
				spawn_char(new_char_data, idstring, NET_MODE.other_on_client)
				
			elif code == "G":
				# host is starting a new game and sending game mode info
				var new_game_info = JSON.parse(message).result
				Global.update_game_info(new_game_info)
				setup_chars_for_new_gamemode()
				
				
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

func _disconnected():
	_log("Signaling server disconnected")
	dbline("Signaling server disconnected")
	


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
	
	# send own character data to HOST
	client.rtc_mp.set_target_peer(1)
	var own_data = own_char.get_character_data()
	var jstr = JSON.print(own_data)
	client.rtc_mp.put_packet(("J"+jstr).to_utf8())
	
	# everything else will wait until the request to join is accepted/denied
	# (when receiving "H")
	


func _mp_server_disconnect():
	dbline("_mp_server_disconnect")
	if host == false:
		leave_game()


func leave_game():
	own_char.net_mode = NET_MODE.own_on_host
	Global.game_mode = Global.GAME_MODE.lobby

	setup_chars_for_new_gamemode()
	
	connected = false
	# remove all remote chars
	for k in chars_by_id.keys():
			if chars_by_id.has(k) == true:
				if chars_by_id[k] != own_char:
					chars_by_id[k].queue_free()
					chars_by_id.erase(k)
				else:
					chars_by_id.erase(k)
	# ^ also remove self from the char list (since the id/key won't be 
	# the same next time)
	if host == true:
		host = false
	

	# (setting up for lobby should include respawning if out of play and everything)
	# also, it's kinda dumb to setup everyone just to remove them right after
	# but whatever
	emit_signal("left_game")


func _mp_peer_connected(id: int):
	# actually do nothing. wait for the client to send info about his character,
	# then reply to that.
	pass

func is_lobby_full():
	return (chars_by_id.size() >= Global.max_players)

func _mp_peer_disconnected(id: int):
	if chars_by_id.has(str(id)) == true:
		chars_by_id[str(id)].queue_free()
		chars_by_id.erase(str(id))
	if id == 1:
		dbline("_mp_peer_disconnected, id == 1")
		leave_game()


func host_start_game():
	# when starting match. send the info to everyone
	client.rtc_mp.set_target_peer(client.rtc_mp.TARGET_PEER_BROADCAST)
	var game_info = Global.get_game_info()
	var jstr = JSON.print(game_info)
	client.rtc_mp.put_packet(("G"+jstr).to_utf8())
	setup_chars_for_new_gamemode()

func setup_chars_for_new_gamemode():
	if Global.game_mode == Global.GAME_MODE.lobby:
		for k in chars_by_id.keys():
			# respawn the ones that were waiting
			dbline("respawning? "+str(Global.ACTIVE_MODE.keys()[chars_by_id[k].active_mode] ))
			if not chars_by_id[k].active_mode == Global.ACTIVE_MODE.playing:
				chars_by_id[k].respawn()
			# remove all gamemode-specific ui and shit
			chars_by_id[k].hide_lives()
				
	elif Global.game_mode == Global.GAME_MODE.elimination:
		for k in chars_by_id.keys():
			chars_by_id[k].elim_lives = Global.elimination_max_lives
			chars_by_id[k].respawn()
			chars_by_id[k].show_lives()




func _log(msg):
	print(msg)
#	$VBoxContainer/TextEdit.text += str(msg) + "\n"


func ping():
	_log(client.rtc_mp.put_packet("ping".to_utf8()))
	_log(client.rtc_mp.get_unique_id())



func create_game():
	client.start(Global.matchmatking_server_url, "")

func join_game():
	client.start(Global.matchmatking_server_url, Global.room_code)


func stop():
	client.stop()
	leave_game()

func spawn_char(char_data, owner_id, net_mode):

	if chars_by_id.has(str(owner_id)) == false:
		var character = CHARACTER.instance()
		self.add_child(character)
		character.set_character_data(char_data)
#		print(char_data)
		character.net_mode = net_mode
		character.control_mode = character.CONTROL_MODE.kbm_or_gamepad
		chars_by_id[str(owner_id)] = character



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
#			Global.game_mode = Global.GAME_MODE.lobby
#			host_start_game()
		
		elif n_surv == 0:
			declare_no_winners()

func declare_winner(winner):
	dbclear()
	announce(winner.base_name + " WINS THE GAME!")

func declare_no_winners():
	dbclear()
	announce(" NO SURVIVORS!")


####### debug

onready var label = get_tree().get_nodes_in_group("debug")[0]
func dbline(message):
	if OS.is_debug_build():
		label.text += (str(message)+"\n")

func dbset(message):
	if OS.is_debug_build():
		label.text = (str(message)+"\n")

func dbclear():
	if OS.is_debug_build():
		label.text = " "


func _input(event):
	if event.is_action_pressed("ui_debug"):
		if OS.is_debug_build():
			dbline("game mode: "+str( Global.GAME_MODE.keys()[Global.game_mode] )+"\n")
			for k in chars_by_id.keys():
				dbline("   ID "+ str(k)+" NAME "+chars_by_id[k].base_name)
				dbline("   pos: "+str( chars_by_id[k].get_node("body").global_position ))




