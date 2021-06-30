extends Node

var character_color: Color setget color_change
var character_name = "anonymous" setget name_change
var room_code
var max_players = 99
var matchmatking_server_url = "ws://localhost:9080"
#var matchmatking_server_url = "ws://still-basin-28484.herokuapp.com:80"

enum GAME_MODE {lobby, elimination}
# default mode (the one that you play if you click "start game"
# from lobby without selecting anything)
var default_game_mode = GAME_MODE.elimination
var game_mode = GAME_MODE.lobby setget game_mode_changed
var selected_game_mode = GAME_MODE.elimination
var elimination_max_lives = 5

const MAIN_UI = preload("res://UI/UI-main.tscn")
const HOST_UI = preload("res://UI/ui_host/ui_host.tscn")
const CLIENT_UI = preload("res://UI/ui_client/ui_client.tscn")

onready var main_ui = get_node("/root/main/UI_main")
var host_ui = null
var client_ui = null

onready var current_ui_ref = main_ui

enum CURRENT_UI {MAIN, HOST, CLIENT}
var current_ui = CURRENT_UI.MAIN

onready var own_char = get_tree().get_nodes_in_group("owned")[0]
onready var online = get_tree().get_nodes_in_group("online")[0]


func color_change(newcol):
	own_char.set_color(newcol)

func name_change(newname):
	own_char.set_name(newname)

func set_random_name():
	randomize()
	var rand_name = "anonymous"+str(int(rand_range(0,9)))+str(int(rand_range(0,9)))+str(int(rand_range(0,9)))
	own_char.set_name(rand_name)

func set_random_color():
	own_char.set_color(random_good_color())

func random_npc_color():
	var hue = rand_range(0.0, 1.0)
	return Color.from_hsv(hue, 0.58, 0.7)

func random_good_color():
	var hue = rand_range(0.0, 1.0)
	return Color.from_hsv(hue, 0.8, 0.85)

func _ready():
	set_random_name()
	set_random_color()

func create_game():
	online.create_game()


func join_game():
	online.join_game()


func quit_host_game():
	self.game_mode = GAME_MODE.lobby
	online.stop()


func switch_to_host_ui():
	if current_ui != CURRENT_UI.HOST:
		current_ui_ref.queue_free()
		var l_host_ui = HOST_UI.instance()
		self.add_child(l_host_ui)
		current_ui_ref = l_host_ui
		current_ui_ref.set_room_code(room_code)
		current_ui = CURRENT_UI.HOST

func switch_to_client_ui():
	if current_ui != CURRENT_UI.CLIENT:
		current_ui_ref.queue_free()
		var l_client_ui = CLIENT_UI.instance()
		self.add_child(l_client_ui)
		current_ui_ref = l_client_ui
		current_ui_ref.set_room_code(room_code)
		current_ui = CURRENT_UI.CLIENT

func switch_to_main_ui():
	if current_ui != CURRENT_UI.MAIN:
		current_ui_ref.queue_free()
		var l_main_ui = MAIN_UI.instance()
		self.add_child(l_main_ui)
		current_ui_ref = l_main_ui
		current_ui = CURRENT_UI.MAIN


func _on_online_created_game():
	switch_to_host_ui()


func _on_online_joined_game():
	switch_to_client_ui()


func _on_online_left_game():
	switch_to_main_ui()

func start_game():
	self.game_mode = selected_game_mode
	online.host_start_game()

# this sounds stupid but it has to be serialized
func get_game_info():
	var game_info = {}
	if game_mode == Global.GAME_MODE.elimination:
		game_info["mode"] = Global.GAME_MODE.elimination
		game_info["lives"] = elimination_max_lives
	elif game_mode == Global.GAME_MODE.lobby:
		game_info["mode"] = Global.GAME_MODE.lobby
	return game_info

func update_game_info(new_game_info):
	var new_game_mode = new_game_info["mode"]
	self.game_mode = new_game_mode
	if new_game_mode == Global.GAME_MODE.lobby:
		pass
	elif new_game_mode == Global.GAME_MODE.elimination:
		elimination_max_lives = new_game_info["lives"]


onready var spect_label = get_tree().get_nodes_in_group("UI_spectating")[0]




### NOTE: only purely stateless modes like lobby should be open for now
### a mode that keeps stats for each character (like score in tf2-style 
### endless games) needs to send the stats to everyone who joins after
### (for now, elimination only sends the max lives at the beginning, 
### and then evolution is auto-synced
func is_game_mode_open():
	if game_mode == Global.GAME_MODE.lobby:
		return true
	elif game_mode == Global.GAME_MODE.elimination:
		return false
	else:
		return true


func game_mode_changed(new_mode):
	game_mode = new_mode
#	online.setup_chars_for_new_gamemode()
	if new_mode == GAME_MODE.lobby:
		get_tree().get_nodes_in_group("UI_gamemode")[0].text = "LOBBY"
	if new_mode == GAME_MODE.elimination:
		get_tree().get_nodes_in_group("UI_gamemode")[0].text = "ELIMINATION"

