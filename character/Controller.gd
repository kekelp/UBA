extends Node

enum INPUT_TYPE {stance, attack, target_x, target_y, move_x, move_y}
#enum INPUT_TYPE {stance, attack, target, move_x, move_y}

var attack_timer = 0

# Declare member variables here. Examples:
# var a = 2
onready var pawn = self.get_parent()
var net_client
var input = [ 0, 0, 1, 0, 0.000, 0.000 ]
# [ move_x(-1,0,1), move_y(-1,0,1), attack(0,1), stance(INT), target_x(FLOAT), target_y(FLOAT) ]  
# this is still converted to variables with the same meaning in character.gd. 
# this is out of laziness, but will probably be good if bots are added.
const MOVE_X = 0
const MOVE_Y = 1
const ATTACK = 2
const STANCE = 3
const TARGET_X = 4
const TARGET_Y = 5




func _input(event):
	if pawn.spectator_mode == false:
		if pawn.net_mode == pawn.NET_MODE.own_on_host:
				convert_event(event)
				handle_input(input)
		elif pawn.net_mode == pawn.NET_MODE.own_on_client:
			# convert_event will store the input in "input" and do nothing.
			# the network client class will have to fetch the input from here 
			# and send it over to the host.
			# EXCEPT some minor things like updating the progressbar need
			# to be done on the client side as well. handle_input_client is 
			# a shorter version of handle_input that skips most things
#			handle_input_own_on_client(input)
			convert_event(event)

#func handle_input_own_on_client(input):
#	pawn.mouse_input = input[ATTACK]

func handle_input(input):
	### new
	if input[MOVE_X] == -1:
		pawn.moving_left = true
	elif input[MOVE_X] == 0:
		pawn.moving_left = false
		pawn.moving_right = false
	elif input[MOVE_X] == 1:
		pawn.moving_right = true

	if input[MOVE_Y] == -1:
		pawn.moving_up = true
	elif input[MOVE_Y] == 0:
		pawn.moving_up = false
		pawn.moving_down = false
	elif input[MOVE_Y] == 1:
		pawn.moving_down = true


	pawn.mouse_input = input[ATTACK]

	pawn.stance = input[STANCE]

	pawn.target_b_pos.x = input[TARGET_X]

	pawn.target_b_pos.y = input[TARGET_Y]
	
#
### new version
func convert_event(event):
	if pawn.control_mode == pawn.CONTROL_MODE.kbm \
	  or pawn.control_mode == pawn.CONTROL_MODE.kbm_or_gamepad:
		########### new
		### stances = later
#		if event is InputEventMouseButton and event.pressed:
#			if event.button_index == BUTTON_WHEEL_UP :
#				var input_type = INPUT_TYPE.stance
#				var input_value = 1
#				input_arr.append( [input_type, input_value] )
#			elif event.button_index == BUTTON_WHEEL_DOWN:
#				var input_type = INPUT_TYPE.stance
#				var input_value = -1
#				input_arr.append( [input_type, input_value] )
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT:
				if event.is_pressed():  # Mouse button down.
					input[ATTACK] = pawn.MOUSE_INPUT.attack
				if not event.is_pressed():  # Mouse button released.
					input[ATTACK] = pawn.MOUSE_INPUT.withdraw


		
		input[MOVE_X] = 0
		if Input.is_action_pressed("move_left"):
			input[MOVE_X] = -1
		if Input.is_action_pressed("move_right"):
			input[MOVE_X] = 1
		
		input[MOVE_Y] = 0
		if Input.is_action_pressed("move_up"):
			input[MOVE_Y] = -1
		if Input.is_action_pressed("move_down"):
			input[MOVE_Y] = 1
			

		var tvec = get_viewport().get_mouse_position() - get_viewport().get_canvas_transform().get_origin()
		var input_value = tvec
		input[TARGET_X] = tvec.x
		input[TARGET_Y] = tvec.y
	
#	### gamepad = later
#	elif pawn.control_mode == pawn.CONTROL_MODE.gamepad \
#		  or pawn.control_mode == pawn.CONTROL_MODE.kbm_or_gamepad:
#
#		if event is InputEventJoypadButton and event.pressed:
#			if event.button_index == JOY_R :
#				var input_type = INPUT_TYPE.stance
#				var input_value = 1
#				input_arr.append( [input_type, input_value] )
#			elif event.button_index == JOY_L:
#				var input_type = INPUT_TYPE.stance
#				var input_value = -1
#				input_arr.append( [input_type, input_value] )
#		if event is InputEventJoypadButton && event.button_index == JOY_R2:
#				if event.is_pressed():  # Mouse button down.
#					var input_type = INPUT_TYPE.attack
#					var input_value = 1
#					input_arr.append( [input_type, input_value] )
#				elif not event.is_pressed():  # Mouse button released.
#					var input_type = INPUT_TYPE.attack
#					var input_value = 0
#					input_arr.append( [input_type, input_value] )

	
	
#		if Input.is_action_just_pressed("move_left_joypad"):
#			var input_type = INPUT_TYPE.move_x
#			var input_value = -1
#			input_arr.append( [input_type, input_value] )
#		elif Input.is_action_just_released("move_left_joypad"):
#			var input_type = INPUT_TYPE.move_x
#			var input_value = 0
#			input_arr.append( [input_type, input_value] )
#		if Input.is_action_just_pressed("move_right_joypad"):
#			var input_type = INPUT_TYPE.move_x
#			var input_value = 1
#			input_arr.append( [input_type, input_value] )
#		elif Input.is_action_just_released("move_right_joypad"):
#			var input_type = INPUT_TYPE.move_x
#			var input_value = 0
#			input_arr.append( [input_type, input_value] )
#		if Input.is_action_just_pressed("move_up_joypad"):
#			var input_type = INPUT_TYPE.move_7
#			var input_value = -1
#			input_arr.append( [input_type, input_value] )
#		elif Input.is_action_just_released("move_up_joypad"):
#			var input_type = INPUT_TYPE.move_y
#			var input_value = 0
#			input_arr.append( [input_type, input_value] )
#		if Input.is_action_just_pressed("move_down_joypad"):
#			var input_type = INPUT_TYPE.move_y
#			var input_value = 1
#			input_arr.append( [input_type, input_value] )
#		elif Input.is_action_just_released("move_down_joypad"):
#			var input_type = INPUT_TYPE.move_y
#			var input_value = 0
#			input_arr.append( [input_type, input_value] )
#
#		var a = Input.get_action_strength("aim_right_joypad") - Input.get_action_strength("aim_left_joypad")
#		var b = Input.get_action_strength("aim_down_joypad") - Input.get_action_strength("aim_up_joypad")
#		var velocity = Vector2(a,b).clamped(1)
#		var input_type = INPUT_TYPE.target
#		var input_value = velocity.normalized()*100000
#		input_arr.append( [input_type, input_value] )
	

#	pawn.target_b_pos = pawn.get_node("body").global_position + velocity.normalized()*100000
#		pawn.get_node("test").global_position = pawn.get_node("body").global_position + velocity.normalized()*100000

