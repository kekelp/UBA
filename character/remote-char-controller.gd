extends Node

const CHAR_SCRIPT = preload("res://character/character.gd")

enum CONTROL_MODE {kbm, gamepad, kbm_or_gamepad}
export(CONTROL_MODE) var control_mode:int = CONTROL_MODE.kbm_or_gamepad

const STANCE = CHAR_SCRIPT.STANCE
export(STANCE) var stance
const MOUSE_INPUT = CHAR_SCRIPT.MOUSE_INPUT
export(MOUSE_INPUT) var mouse_input

var target: Vector2

func _input(event):
	if control_mode == CONTROL_MODE.kbm \
	  or control_mode == CONTROL_MODE.kbm_or_gamepad:
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == BUTTON_WHEEL_UP :
				stance = (stance + 1)%CHAR_SCRIPT.n_stances
				switch_to_stance()
			if event.button_index == BUTTON_WHEEL_DOWN:
				stance = (stance + 1)%n_stances
				switch_to_stance()
		if event is InputEventMouseButton && event.button_index == BUTTON_LEFT:
			if event.is_pressed():  # Mouse button down.
				mouse_input = MOUSE_INPUT.attack
			elif not event.is_pressed():  # Mouse button released.
				mouse_input = MOUSE_INPUT.withdraw
		
		
		if Input.is_action_just_pressed("move_left"):
			moving_left = true
		if Input.is_action_just_released("move_left"):
			moving_left = false
		if Input.is_action_just_pressed("move_right"):
			moving_right = true
		if Input.is_action_just_released("move_right"):
			moving_right = false
		if Input.is_action_just_pressed("move_up"):
			moving_up = true
		if Input.is_action_just_released("move_up"):
			moving_up = false
		if Input.is_action_just_released("move_down"):
			moving_down = false
		if Input.is_action_just_released("move_down"):
			moving_down = false
			
		if event is InputEventMouseMotion:
			target_b_pos = get_viewport().get_mouse_position()
			
	if control_mode == CONTROL_MODE.gamepad \
	  or control_mode == CONTROL_MODE.kbm_or_gamepad:
#		print(event)
		if event is InputEventJoypadButton and event.pressed:
			if event.button_index == JOY_R :
				stance = (stance + 1)%n_stances
				switch_to_stance()
			if event.button_index == JOY_L:
				stance = (stance + 1)%n_stances
				switch_to_stance()
		if event is InputEventJoypadButton && event.button_index == JOY_R2:
				if event.is_pressed():  # Mouse button down.
					mouse_input = MOUSE_INPUT.attack
				elif not event.is_pressed():  # Mouse button released.
					mouse_input = MOUSE_INPUT.withdraw
		if event is InputEventJoypadMotion && event.axis == JOY_AXIS_5:
			if event.axis_value > 0.05:  # Mouse button down.
				mouse_input = MOUSE_INPUT.attack
			else:  # Mouse button released.
				mouse_input = MOUSE_INPUT.withdraw
			print(event.axis_value)


			
		if Input.is_action_just_pressed("move_left_joypad"):
			moving_left = true
		if Input.is_action_just_released("move_left_joypad"):
			moving_left = false
		if Input.is_action_just_pressed("move_right_joypad"):
			moving_right = true
		if Input.is_action_just_released("move_right_joypad"):
			moving_right = false
		if Input.is_action_just_pressed("move_up_joypad"):
			moving_up = true
		if Input.is_action_just_released("move_up_joypad"):
			moving_up = false
		if Input.is_action_just_released("move_down_joypad"):
			moving_down = false
		if Input.is_action_just_released("move_down_joypad"):
			moving_down = false
			
		var a = Input.get_action_strength("aim_right_joypad") - Input.get_action_strength("aim_left_joypad")
		var b = Input.get_action_strength("aim_down_joypad") - Input.get_action_strength("aim_up_joypad")
		var velocity = Vector2(a,b).clamped(1)
		target_b_pos = get_node("body").global_position + velocity.normalized()*100000
#		get_node("test").global_position = get_node("body").global_position + velocity.normalized()*100000
	
	elif control_mode == CONTROL_MODE.network_synced:
		# do nothing and wait to be moved by rpc's
		pass
	elif control_mode == CONTROL_MODE.network_controlled:
		# same
		pass
