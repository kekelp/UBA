extends Node2D

# game mode parameters

export var free_movement = true
export var free_swing = true

var elim_lives = 5
 

var char_id

var waiting_for_next_game = false setget set_waiting_for_next_game
var spectator_mode = false setget change_spectator_mode

enum NET_MODE {own_on_host, other_on_host, own_on_client, other_on_client}
export (NET_MODE) var net_mode setget change_net_mode


enum CONTROL_MODE {kbm, gamepad, kbm_or_gamepad, bot, none}
export(CONTROL_MODE) var control_mode:int = CONTROL_MODE.kbm_or_gamepad
# state

#enum STANCE {punching, grabbing, rasengan}
enum STANCE {punching, grabbing}
enum STATE {swinging, throwing1, throwing2}
enum MOUSE_INPUT {attack, block, withdraw}
var mouse_input: int = MOUSE_INPUT.withdraw

var outwards: bool = false
var towards_enemy: bool = false

var n_stances = 2

export var stance: int = STANCE.punching

var state = STATE.swinging
var being_grabbed: bool = false
var falling_from_throw: bool = false

var moving_right: bool = false
var moving_left: bool = false
var moving_up: bool = false
var moving_down: bool = false

var enemy_grabbing_hand = null

var body_getting_grabbed_by_self = null

var airborne = false

export var base_color: Color = Color(0.8, 0.7, 3.0)

export var base_name = "defaultfrog #12"
var dead = false
var respawning = false
# parameters

# punch swing
var oscillator_force = 85.0
#var oscillator_force = 45.0
var drag_amount = 4.85
#var drag_amount = 3.5
var bpf = 750 *1000
var punch_force = bpf
#var punch_force = 500 *1000



var respawn_wait_time = 1.0
var respawn_wait_time_lobby = 0.2

var global_throw_nerf = 0.9

var release1_wait = 0.2
var release2_wait = 0.4

var falling_from_throw_wait = 0.3

var p_to_damage_coeff_FALL = 0.75

var p_to_damage_coeff = 0.35
var maxopacitydamage = 500

#var extra_kick_coeff = 0.35
var extra_kick_coeff = 0.75
var extra_grabkick_coeff = 0.95


var x_dirmod = 0.0
var x_max_speed = 800
#var x_max_walk_force = 3000000
var x_max_walk_force = 6000000
var x_damp = 950

var y_dirmod = 0.0
var y_max_speed = 800
var y_min_speed = 500
var y_max_speed_damp = 950


# punching damage
#var hand_base_mass = 2.0
var hand_base_mass = 2.5
var hand_off_arc_mass_boost = 4.0
#var hand_off_arc_mass_boost = 5.0
var real_punch_min_speed = 500


# holding 
var body_force: Vector2

var csp_velocity: Vector2
var csp_last_position: Vector2
var csp_2nd_last_position: Vector2
var csp_hand_last_position: Vector2
var csp_hand_2nd_last_position: Vector2

var attack_disabled = false

const YELLOW_BANG = preload("res://vfx/yellow-bang.tscn")

var spectator_place = 1000000

onready var base_gravity = $body.gravity_scale

var overheat = 0

func random_npc_color():
	var hue = rand_range(0.0, 1.0)
	return Color.from_hsv(hue, 0.58, 0.7)

func random_good_color():
	var hue = rand_range(0.0, 1.0)
	return Color.from_hsv(hue, 0.8, 0.85)
# Called when the node enters the scene tree for the first time.
func _ready():
#	switch_to_stance()
	$hand.add_collision_exception_with($body)

	
func change_net_mode(newval):
	net_mode = newval
	if newval == NET_MODE.own_on_client or newval == NET_MODE.other_on_client:
		$body.mode = RigidBody2D.MODE_KINEMATIC
		$hand.mode = RigidBody2D.MODE_KINEMATIC
	else:
		$body.mode = RigidBody2D.MODE_RIGID
		$hand.mode = RigidBody2D.MODE_RIGID

# vars
var fall_timer = 0

var almost_zero = 0.00001
var damage_taken: float = almost_zero
#
#var target: Node2D
var target_b_pos: Vector2

var direction: float = 0

var release_timer = 0

var second_last_height = 0
var last_height = 0
var height = 0
var highest_height = 0
var current_jump_height = 0
var current_ground_level = 0

onready var arena = get_tree().get_nodes_in_group("arena")[0]

var attack_timer = 0
var attack_timer_max = 1.25

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
#	if not self.is_in_group("owned"):
#		print($hand.global_position)
	if free_swing == false:
		mouse_input = MOUSE_INPUT.withdraw


	# HAND
	# overheat BS
	# mongrel
#	if self.is_in_group("owned"):
#		Global.online.dbset("amongrel "+ str(MOUSE_INPUT.attack))
#		Global.online.dbline("mode " +str(NET_MODE.keys()[net_mode]))
	if (net_mode == NET_MODE.own_on_host or net_mode == NET_MODE.other_on_host or self.is_in_group("owned")):
		if mouse_input == MOUSE_INPUT.attack && attack_timer < attack_timer_max+0.10:
			attack_timer +=delta
		elif attack_timer > 0:
			attack_timer -= delta*2
		else:
			attack_timer = 0
		overheat = clamp(attack_timer/attack_timer_max, 0, 1.0)
		if overheat > 0.7:
			self.attack_disabled = true
		else:
			self.attack_disabled = false
		self.punch_force = lerp(0.35*bpf, bpf, 1.3-overheat)
		
		
		
	if (net_mode == NET_MODE.own_on_host or net_mode == NET_MODE.other_on_host):

		# hand physics
		# punch state analysis 
		var return_vec: Vector2 = $body.global_position - $hand.global_position
		var target_vec = Vector2(0,0)
		target_vec =  target_b_pos -$hand.global_position
		outwards = false
		if $hand.linear_velocity.dot(return_vec) < 0: outwards = true
		towards_enemy = false
		if $hand.linear_velocity.dot(target_vec) > 0: towards_enemy = true	
	
		# mass boost
		$hand.offensive_arc = towards_enemy && outwards
		if $hand.offensive_arc == true && attack_disabled == false:
			$hand.mass = hand_base_mass * hand_off_arc_mass_boost
	#		$hand.get_node("g/Sprite").modulate = Color("#ff0000")
		else:
			$hand.mass = hand_base_mass
	#		$hand.get_node("g/Sprite").modulate = Color("#0000ff")
		
		########################## new
	
		$hand.punch_force = Vector2(0,0)
		var oscill_xn: float = 200*pow((return_vec.length()/200),1.5)
	
	
		var new_vec: Vector2 = target_b_pos - $body.global_position 
		# attack
		if mouse_input == MOUSE_INPUT.attack:
			# position drag
			### poggers	
			$hand.should_drag = true
			$hand.drag_return_vec = return_vec
			$hand.drag_amount = drag_amount
			$hand.delta = delta		
#			$hand.global_position += return_vec*drag_amount*delta
		
			var att_str = punch_force
			$hand.punch_force += new_vec.normalized()*att_str* delta
			
			$hand.punch_force += oscill_xn* return_vec.normalized() *oscillator_force
		
		# block
#		elif mouse_input == MOUSE_INPUT.block:
#			# block position
#			var block_pos = $body.global_position + (target_b_pos - $body.global_position).normalized()*100
#			$test.global_position = block_pos
#			var block_ret_vec = block_pos - $hand.global_position
#			# position drag
#			$hand.global_position += block_ret_vec*drag_amount*2.0*delta
#			var att_str = punch_force
#			$hand.punch_force += new_vec.normalized()*att_str*0.5* delta
#
#			$hand.punch_force += oscill_xn* return_vec.normalized() *oscillator_force
#			$hand.mass = hand_base_mass*10.0
#			self.attack_disabled = true
#			self.attack_disabled = true
		
		elif mouse_input == MOUSE_INPUT.withdraw:
			# position drag
			### poggers
			$hand.should_drag = true
			$hand.drag_return_vec = return_vec
			$hand.drag_amount = drag_amount
			$hand.delta = delta
#			$hand.global_position += return_vec*drag_amount*delta
			# base oscillator force for returning home
			$hand.punch_force += oscill_xn* return_vec.normalized() *oscillator_force
	

			#remember gravity scale 16
#
#		if state == STATE.throwing1:
#			release_timer += delta
#			if release_timer >= release1_wait:
#				release1(body_getting_grabbed_by_self)
#		if state == STATE.throwing2:
#			release_timer += delta
#			if release_timer >= release2_wait:
#				release2(body_getting_grabbed_by_self)
#
#		if self.falling_from_throw == true:
#			fall_timer += delta
#			if fall_timer >= falling_from_throw_wait:
#				self.falling_from_throw = false
#				fall_timer = 0
		
		#body physics
				
		# jump adjustment
		# remember that y axis is inverted
		if free_movement == true:
			second_last_height = last_height
			last_height = height
			height = $body.global_position.y
			
			body_force = Vector2(0,0)
	#
	#		if (self.being_grabbed == true):
	#			# dragged by enemy grabbing hand
	#			var grab_return_vec = enemy_grabbing_hand.global_position - $body.global_position
	#			if enemy_grabbing_hand.owner.airborne == true:
	#				body_force += (grab_return_vec*750 - $body.linear_velocity.normalized() * 5)*global_throw_nerf * 0.05
	#				print("denied! ")
	#			else:
	#				body_force += (grab_return_vec*750 - $body.linear_velocity.normalized() * 5) *global_throw_nerf
	#
	#			# self pull
	#			var holding_on_return_vec = enemy_grabbing_hand.global_position - enemy_grabbing_hand.owner.get_node("body").global_position
	#			if enemy_grabbing_hand.owner.airborne == true:
	#				enemy_grabbing_hand.owner.body_force += (holding_on_return_vec*750 - $body.linear_velocity.normalized() * 10) *0.3
	#			else:
	#				enemy_grabbing_hand.owner.body_force += (holding_on_return_vec*750 - $body.linear_velocity.normalized() * 10) *0.05
		#	print("holding on... force ", -grab_return_vec*750 )
		#			print(enemy_grabbing_hand.owner, enemy_grabbing_hand.owner.airborne == true)
					
	#		else:
				# walking
				# x
		
			var x_force = 0
			var y_force = 0
			if moving_left:
				x_dirmod = -1
			elif moving_right:
				x_dirmod = 1
			else:
				x_dirmod = 0
				
			var x_braking = sign($body.linear_velocity.x * x_dirmod)
			var x_brake_mod = 1
			if x_braking == -1: x_brake_mod = 2.2
			
			if abs($body.linear_velocity.x) < x_max_speed:
				x_force += (x_max_speed - abs($body.linear_velocity.x))/x_max_speed * x_max_walk_force * delta * x_dirmod * x_brake_mod
			if abs($body.linear_velocity.x) > x_max_speed:
				x_force -= ($body.linear_velocity.x - x_max_speed)* delta * x_damp  
			
			if abs($body.linear_velocity.y) > y_max_speed:
				y_force -= ($body.linear_velocity.y - y_max_speed)* delta * y_max_speed_damp  

				
			body_force += Vector2(x_force, y_force)
	#		print($body.linear_velocity.y)
			$body.applied_force = body_force
	
	

#
#	if stance == STANCE.grabbing:
#		$hand.collision_mask = 2 # remove collisions with bodies (finger does it)
#	else:
#		$hand.collision_mask = 3
#	if stance == STANCE.grabbing && state == STATE.swinging:
#		$hand/fingers.collision_mask = 11 # enable fingers
#	else:
#		$hand/fingers.collision_mask = 0 # disable fingers



func _process(delta):
	# mongrel
#	if self.is_in_group("owned"):
#		var progressbar = get_tree().get_nodes_in_group("progressbar")[0]
#		progressbar.value = overheat*100.0
	# fix body rotation
	$body/g.rotation = -$body.rotation
	
	if spectator_mode == false:
		if $body.global_position.x < spectator_place - 500:
			if $body.global_position.y < arena.get_node("die_top").global_position.y:
				die()
			elif $body.global_position.y > arena.get_node("die_bottom").global_position.y:
				die()
			elif $body.global_position.x < arena.get_node("die_left").global_position.x:
				die()
			elif $body.global_position.x > arena.get_node("die_right").global_position.x:
				die()
			elif self.dead == true:
				self.dead = false

#
	# client side prediction
	if net_mode == NET_MODE.own_on_client or net_mode == NET_MODE.other_on_client:
		if csp_last_position == $body.global_position:
			var vel = csp_last_position - csp_2nd_last_position
			$body.global_position += vel
			var hand_vel = csp_hand_last_position - csp_hand_2nd_last_position
			$hand.global_position += hand_vel

		csp_2nd_last_position = csp_last_position
		csp_last_position = $body.global_position

		csp_hand_2nd_last_position = csp_hand_last_position
		csp_hand_last_position = $hand.global_position


func die():
	if (dead == false):
		print("dying")
		print("   ", $body.global_position)
		dead = true
		if Global.game_mode == Global.GAME_MODE.lobby:
			$RespawnTimer.start(respawn_wait_time_lobby)
		elif Global.game_mode == Global.GAME_MODE.elimination:
			elim_lives -= 1
			if elim_lives >= 1:
				$RespawnTimer.start(respawn_wait_time)
				if self.is_in_group("owned"):
					Global.spect_label.text = "RESPAWNING..."
					Global.spect_label.get_parent().visible = true
			else:
				change_spectator_mode(true)
				Global.online.check_winner()





# get punched. collider is the incoming hand 
# the first block assumes that the body's and collider's velocity already
# got adjusted as a result of the collision when this block is executed. 
# If this is not true, then I have no idea why it works
# or hit the ground
func _on_body_body_entered(collider):
	if net_mode == NET_MODE.own_on_host or net_mode == NET_MODE.other_on_host:
		if collider.is_in_group("hand"):
			var incoming_p = collider.mass * collider.linear_velocity
			self.damage_taken += sqrt(incoming_p.length())* p_to_damage_coeff * 0.2
			# extra kick
			var coll_atk_disabled = collider.get_parent().attack_disabled
			if coll_atk_disabled == false && collider.offensive_arc && collider.linear_velocity.length() > real_punch_min_speed:
				self.damage_taken += sqrt(incoming_p.length())* p_to_damage_coeff * 0.8
				$body.apply_central_impulse($body.linear_velocity *0.1*extra_kick_coeff*damage_taken)
			
				var yellow1 = YELLOW_BANG.instance()
				self.add_child(yellow1)
				yellow1.global_position = collider.global_position
				
			update_damage_debuff()
#			var diff_speed = (collider.linear_velocity)
#			var diff_power = diff_speed.dot( $body.linear_velocity.normalized())
#	#		var diff_momentum = collider.mass * diff_power
#			var incoming_p = collider.mass * diff_speed
#			self.damage_taken += sqrt(incoming_p.length())* p_to_damage_coeff * 0.2
#			# extra kick
#			var suff_speed = diff_speed.length() > real_punch_min_speed
#			var coll_atk_disabled = collider.get_parent().attack_disabled
#			if collider.offensive_arc && suff_speed && coll_atk_disabled == false:
#				self.damage_taken += sqrt(incoming_p.length())* p_to_damage_coeff * 0.8
#				$body.apply_central_impulse($body.linear_velocity.normalized() *diff_power *0.1*extra_kick_coeff*damage_taken)
#				var yellow1 = YELLOW_BANG.instance()
#				self.add_child(yellow1)
#				yellow1.global_position = collider.global_position
#			update_damage_debuff()
		elif collider.is_in_group("arena"):
			# bounce adjust
			var too_slow = max(y_min_speed - abs($body.linear_velocity.y), 0)/y_max_speed
			if free_movement == true:
				if moving_up:
					$body.apply_central_impulse(Vector2(0,-7500))
				elif moving_down:
					$body.apply_central_impulse(Vector2(0,900))
	elif net_mode == NET_MODE.own_on_client or net_mode == NET_MODE.other_on_client:
		if collider.is_in_group("hand"):
			var diff_speed = ($body.linear_velocity - collider.linear_velocity)
			# extra kick, but just the yellow stuff (on client)
			var suff_speed = diff_speed.length() > real_punch_min_speed
			var coll_atk_disabled = collider.get_parent().attack_disabled
			if collider.offensive_arc && suff_speed && coll_atk_disabled == false:
				var yellow1 = YELLOW_BANG.instance()
				self.add_child(yellow1)
				yellow1.global_position = collider.global_position

#			# get hurt if being thrown
#			if self.falling_from_throw == true:
#				var impact_p = $body.mass * $body.linear_velocity
#				self.damage_taken += sqrt(impact_p.length())* p_to_damage_coeff_FALL
#	#			print("fall damage ",sqrt(impact_p.length())* p_to_damage_coeff_FALL)
#				if ($body.linear_velocity.length() > real_punch_min_speed*2):
#					pass
	#				var yellow1 = YELLOW_BANG.instance()
	#				print(self)
	#				print(self.owner)
	#				self.add_child(yellow1)
	#				yellow1.global_position = $body.global_position
#				update_damage_debuff()
			

func big_booma(pos: Position2D):
	var yellow1 = YELLOW_BANG.instance()
	self.owner.add_child(yellow1)
	yellow1.global_position = pos


func update_damage_debuff():
	var _inverse_damage = 1.0/(damage_taken)
#	var alpha = 0.6 * min((damage_taken/maxopacitydamage),1 )
#	$body.get_node("RedSprite").modulate = Color(0.7, 0.0, 0.0, alpha)
	var white =  Color( 1, 1, 1, 1 )
	var namealpha = 0.9 * min((damage_taken/maxopacitydamage),1 )
	var newred_alpha = Color( 0.86, 0.08, 0.24, namealpha )
	$body/g/UI/name.modulate = white.blend(newred_alpha)



# for when the fingers hit something. collider is the guy getting grabbed
#func _on_fingers_body_entered(collider):
#	if collider.get_name() == "body":
#		if $body != collider:
#			grab(collider)
##			print("i grabbed the streamer lol", collider, collider.get_name())
#	if collider.get_name() == "hand":
#		if $hand != collider:
#			# judo move
#			pass

#
#func grab(body_getting_grabbed: RigidBody2D):
#	body_getting_grabbed.owner.being_grabbed = true
#	body_getting_grabbed.owner.enemy_grabbing_hand = $hand
#	body_getting_grabbed.add_collision_exception_with($body)
#	body_getting_grabbed.owner.get_node("hand").add_collision_exception_with($body)
#	self.body_getting_grabbed_by_self = body_getting_grabbed
#	$hand/g/Sprite.play("grab_grip")
#	self.release_timer = 0
#	self.state = STATE.throwing1
#
#func release1(body_getting_released: RigidBody2D):
#	body_getting_released.owner.being_grabbed = false
#	body_getting_released.owner.enemy_grabbing_hand = null
#	# throw extra kick
#	if self.airborne == false:
#		pass
#		body_getting_released.apply_central_impulse($body.linear_velocity.normalized()*1000.0 *body_getting_released.owner.extra_grabkick_coeff *body_getting_released.owner.damage_taken* 0.004*global_throw_nerf)
#	body_getting_released.owner.falling_from_throw = true
#	self.release_timer = 0
#	self.state = STATE.throwing2

#
#func release2(body_getting_released: RigidBody2D):
#	body_getting_released.remove_collision_exception_with($body)
#	body_getting_released.owner.get_node("hand").remove_collision_exception_with($body)
#	self.body_getting_grabbed_by_self = null
#	self.state = STATE.swinging
#	$hand/g/Sprite.play("grab")
#
#func switch_to_stance_punching():
#	self.stance = STANCE.punching
#	$hand/g/Sprite.play("punch")
#
#func switch_to_stance_grabbing():
#	self.stance = STANCE.grabbing
#	$hand/g/Sprite.play("grab")
#
#func switch_to_stance_rasengan():
#	self.stance = STANCE.rasengan
#	$hand/g/Sprite.play("rasengan")
#
#func switch_to_stance():
#	if self.stance == STANCE.punching:
#		self.switch_to_stance_punching()
#	if self.stance == STANCE.grabbing:
#		self.switch_to_stance_grabbing()
##	if self.stance == STANCE.rasengan:
##		self.switch_to_stance_rasengan()


func set_color(color: Color):
	self.base_color = color
	$body/Sprite.modulate = color
	$hand/g/Sprite.modulate = color.lightened(0.5)
	
func set_name(name):
	self.base_name = name
	$body/g/UI/name.text = name


func respawn():
	if self.is_in_group("owned"):
		Global.spect_label.text = ""
		Global.spect_label.get_parent().visible = false
#	if self.is_in_group("owned"):
	print("CALLING a respawn. ", self, " ", self.base_name)
	
	$body/g/UI/Label.text = str(elim_lives)
	
	# position is reset only on host. client characters will get 
	# their position puppeted around by the host anyway
	# BUT note that spectator mode has to be set to false at the end of 
	# teleport (in should_reset in body.gd)
	# so the ones that don't teleport do it in their own branch
	if (net_mode == NET_MODE.own_on_host or net_mode == NET_MODE.other_on_host):
		var left_x = arena.get_node("spawn-left").global_position.x
		var right_x = arena.get_node("spawn-right").global_position.x
		var spw_y = arena.get_node("spawn-left").global_position.y
		randomize()
		teleport( Vector2( rand_range(left_x, right_x)  , spw_y))
		$body.linear_velocity = Vector2(0,0)
		$hand.linear_velocity = Vector2(0,0)
	else:
		change_spectator_mode(false)
		respawning = false
		waiting_for_next_game = false
	
	self.damage_taken = almost_zero
	self.update_damage_debuff()



func teleport(new_pos):
	$body.should_reset = true
	$body.reset_pos = new_pos
	$hand.should_reset = true
	$hand.reset_pos = new_pos + $hand.rest_pos

func _on_RespawnTimer_timeout():
	respawn() # Replace with function body.

func get_character_data():
	var c_data = {}
	c_data.name = ($body/g/UI/name.text)
	c_data.color = Color($body/Sprite.modulate).to_html()
	c_data.spect_mode = spectator_mode
	c_data.waiting_for_next_game = waiting_for_next_game
	return c_data.duplicate()


func set_character_data(c_data):
	set_name(c_data.name)
	set_color(c_data.color)
	change_spectator_mode(c_data.spect_mode)
	waiting_for_next_game = c_data.waiting_for_next_game


### new and good
func get_character_position():
	var c_pos = []
	c_pos.push_back($hand.global_position.x)
	c_pos.push_back($hand.global_position.y)
	c_pos.push_back($body.global_position.x)
	c_pos.push_back($body.global_position.y)
	c_pos.push_back(target_b_pos.x)
	c_pos.push_back(target_b_pos.y)
	# velocity for client side prediction
#	c_pos.push_back($body.linear_velocity.x)
#	c_pos.push_back($body.linear_velocity.y)
	return c_pos


func sync_position(c_pos):
		$hand.global_position.x = c_pos[0]
		$hand.global_position.y = c_pos[1]
		$body.global_position.x = c_pos[2]
		$body.global_position.y = c_pos[3]
		target_b_pos.x = c_pos[4]
		target_b_pos.y = c_pos[5]
#	# velocity for client side prediction
#		csp_velocity.x = c_pos[6]
#		csp_velocity.y = c_pos[7]

func change_spectator_mode(newval):
	spectator_mode = newval
	if newval == true:
		$body.gravity_scale = 0
		self.visible = false
	
		self.global_position.x = spectator_place
		self.global_position.y = spectator_place
	
	elif newval == false:
		$body.gravity_scale = base_gravity
		self.visible = true
	
	if self.is_in_group("owned"):
		if newval == true && Global.spect_label.text != "WAITING FOR NEXT GAME...":
			Global.spect_label.text = "SPECTATING"
			Global.spect_label.get_parent().visible = true


func set_waiting_for_next_game(newval):
	waiting_for_next_game = newval
	if waiting_for_next_game == true:
		Global.spect_label.text = "WAITING FOR NEXT GAME..."
		Global.spect_label.get_parent().visible = true


func hide_lives():
	$body/g/UI/Label.visible = false

func show_lives():
	$body/g/UI/Label.visible = true
