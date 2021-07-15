extends Node2D

# game mode parameters

var sync_drag = 0.9


export var free_movement = true
export var free_swing = true

var elim_lives = 5


var char_id

enum ACTIVE_MODE {playing, respawning, waiting_next_game}
var active_mode:int = ACTIVE_MODE.playing setget change_active_mode
var spectating = false setget change_spectating

enum NET_MODE {own_on_host, other_on_host, own_on_client, other_on_client}
export (NET_MODE) var net_mode setget change_net_mode


enum CONTROL_MODE {kbm, gamepad, kbm_or_gamepad, bot, none}
export(CONTROL_MODE) var control_mode:int = CONTROL_MODE.kbm_or_gamepad
########################## state

enum STANCE {punching, grabbing, rasengan}
enum MOUSE_INPUT {attack, withdraw}
var mouse_input: int = MOUSE_INPUT.withdraw

var outwards: bool = false
var towards_enemy: bool = false

export var stance: int = STANCE.punching

var being_grabbed: bool = false
var falling_from_throw: bool = false

var moving_right: bool = false
var moving_left: bool = false
var moving_up: bool = false
var moving_down: bool = false

export var base_color: Color = Color(0.8, 0.7, 3.0)

export var base_name = "defaultfrog #12"
var dead = false
var respawning = false


#################################### stats/parameters

var oscillator_force = 85.0

var drag_amount = 4.85

var bpf = 750 *1000
var punch_force = bpf

var respawn_wait_time = 1.0
var respawn_wait_time_lobby = 0.2


var p_to_damage_coeff = 0.35
var maxopacitydamage = 500

var extra_kick_coeff = 0.75

var x_max_speed = 800

var x_max_walk_force = 6000000
var x_damp = 950

var y_dirmod = 0.0
var y_max_speed = 800
var y_min_speed = 500
var y_max_speed_damp = 950


# punching damage
var hand_base_mass = 2.5
var hand_off_arc_mass_boost = 4.0
var real_punch_min_speed = 500

onready var base_gravity = $body.gravity_scale


############################à# holding / internal
var x_dirmod = 0.0

var body_force: Vector2

var csp_velocity: Vector2
var csp_last_position: Vector2
var csp_2nd_last_position: Vector2
var csp_hand_last_position: Vector2
var csp_hand_2nd_last_position: Vector2

var attack_disabled = false

const YELLOW_BANG = preload("res://vfx/yellow-bang.tscn")

var spectator_place = 1000000

var overheat = 0

var fall_timer = 0

var almost_zero = 0.00001
var damage_taken: float = almost_zero

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

var physics_proc_delta = 0



###################### functions

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
	change_net_mode(NET_MODE.own_on_host)


# now useless...
func change_net_mode(newval):
	net_mode = newval
	if newval == NET_MODE.own_on_client or newval == NET_MODE.other_on_client:
		$body.mode = RigidBody2D.MODE_RIGID
		$hand.mode = RigidBody2D.MODE_RIGID
	else:
		$body.mode = RigidBody2D.MODE_RIGID
		$hand.mode = RigidBody2D.MODE_RIGID


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	physics_proc_delta = delta
	if free_swing == false:
		mouse_input = MOUSE_INPUT.withdraw
	
	
	# HAND
	# overheat BS
#	if (net_mode == NET_MODE.own_on_host or net_mode == NET_MODE.other_on_host):
	if true:
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
		
		
		
#	if (net_mode == NET_MODE.own_on_host or net_mode == NET_MODE.other_on_host):
	if true:
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
	
			var att_str = punch_force
			$hand.punch_force += new_vec.normalized()*att_str* delta
			
			$hand.punch_force += oscill_xn* return_vec.normalized() *oscillator_force
		
		elif mouse_input == MOUSE_INPUT.withdraw:
			# base oscillator force for returning home
			$hand.punch_force += oscill_xn* return_vec.normalized() *oscillator_force
	
		#body physics
				
		# jump adjustment
		# remember that y axis is inverted
		if free_movement == true:
			second_last_height = last_height
			last_height = height
			height = $body.global_position.y
			
			body_force = Vector2(0,0)
		
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
			$body.applied_force = body_force
	



func _process(delta):

	# fix body rotation
	$body/g.rotation = -$body.rotation
	
	if spectating == false:
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
	
	
	# if client, smooth the apparent positions 
#	if self.net_mode == NET_MODE.own_on_client or self.net_mode == NET_MODE.other_on_client:
#
#		$body/g/Sprite.position = sync_drag * $body/g/Sprite.position
#
#		$hand/g/Sprite.position = sync_drag * $hand/g/Sprite.position





func die():
	if (dead == false):
		dead = true
		if Global.game_mode == Global.GAME_MODE.lobby:
			$RespawnTimer.start(respawn_wait_time_lobby)
		elif Global.game_mode == Global.GAME_MODE.elimination:
			elim_lives -= 1
			if elim_lives >= 1:
				$RespawnTimer.start(respawn_wait_time)
				change_active_mode(ACTIVE_MODE.respawning)
			else:
				change_active_mode(ACTIVE_MODE.waiting_next_game)
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




func set_color(color: Color):
	self.base_color = color
	$body/g/Sprite.modulate = color
	$hand/g/Sprite.modulate = color.lightened(0.5)
	
func set_name(name):
	self.base_name = name
	$body/g/UI/name.text = name


func respawn():
	if self.is_in_group("owned"):
		update_spect_label("", false)
	
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
		var reset_pos = ( Vector2( rand_range(left_x, right_x)  , spw_y))
		$body.teleport(reset_pos)
		$hand.teleport(reset_pos)

	else:
		change_active_mode(ACTIVE_MODE.playing)
		respawning = false
	
	self.damage_taken = almost_zero
	self.update_damage_debuff()





func _on_RespawnTimer_timeout():
	respawn() # Replace with function body.

func get_character_data():
	var c_data = {}
	c_data.name = ($body/g/UI/name.text)
	c_data.color = Color($body/g/Sprite.modulate).to_html()
	return c_data.duplicate()


func set_character_data(c_data):
	set_name(c_data.name)
	set_color(c_data.color)

func get_character_position():
	var c_pos = []
	c_pos.push_back($hand.global_position.x)
	c_pos.push_back($hand.global_position.y)
	c_pos.push_back($body.global_position.x)
	c_pos.push_back($body.global_position.y)
	c_pos.push_back(target_b_pos.x)
	c_pos.push_back(target_b_pos.y)
	# velocity for client side prediction
	c_pos.push_back($hand.linear_velocity.x)
	c_pos.push_back($hand.linear_velocity.y)
	c_pos.push_back($body.linear_velocity.x)
	c_pos.push_back($body.linear_velocity.y)
	return c_pos



func sync_position(c_pos):
# smooth
#
#	var bigstep = 50
#	var lesign = -1
#
#	var hand_step = Vector2( c_pos[0] - $hand.global_position.x, c_pos[1] - $hand.global_position.y ) 
#	if hand_step.length() > bigstep:
#		$hand/g/Sprite.position += lesign*hand_step *sync_drag
#
#	var body_step = Vector2( c_pos[2] - $body.global_position.x, c_pos[3] - $body.global_position.y ) 
#	if body_step.length() > bigstep:
#		$body/g/Sprite.position += lesign*body_step *sync_drag
#
	# sync
	$hand.global_position.x = c_pos[0]
	$hand.global_position.y = c_pos[1]
	$body.global_position.x = c_pos[2]
	$body.global_position.y = c_pos[3]
	target_b_pos.x = c_pos[4]
	target_b_pos.y = c_pos[5]
	$hand.linear_velocity.x = c_pos[6]
	$hand.linear_velocity.y = c_pos[7]
	$body.linear_velocity.x = c_pos[8]
	$body.linear_velocity.y = c_pos[9]
	

func change_active_mode(newval):
	active_mode = newval
	if newval == ACTIVE_MODE.respawning:
		if self.is_in_group("owned"):
			if Global.game_mode != Global.GAME_MODE.lobby:
				change_spectating(true)
				update_spect_label("RESPAWNING...", true)
	elif newval == ACTIVE_MODE.waiting_next_game:
		change_spectating(true)
		if self.is_in_group("owned"):
			update_spect_label("WAITING FOR NEXT GAME...", true)
	elif newval == ACTIVE_MODE.playing:
		change_spectating(false)
		if self.is_in_group("owned"):
			update_spect_label("", false)

func change_spectating(newval):
	spectating = newval
	if newval == true:
		$body.gravity_scale = 0
		self.visible = false
		
		self.global_position.x = spectator_place
		self.global_position.y = spectator_place
	
	elif newval == false:
		$body.gravity_scale = base_gravity
		self.visible = true
		
		self.global_position.x = 0
		self.global_position.y = 0

#func change_spectator_mode(newval):
#	spectator_mode = newval
#	if newval == true:
#		$body.gravity_scale = 0
#		self.visible = false
#
#		self.global_position.x = spectator_place
#		self.global_position.y = spectator_place
#
#	elif newval == false:
#		$body.gravity_scale = base_gravity
#		self.visible = true
#
#	if self.is_in_group("owned"):
#		if newval == true:
#			update_spect_label("SPECTATING", true)
#
#
#func set_waiting_for_next_game(newval):
#	waiting_for_next_game = newval
#	if waiting_for_next_game == true:
#		update_spect_label("WAITING FOR NEXT GAME", true)

func update_spect_label(text: String, visible: bool):
	Global.spect_label.text = text
	if visible == false:
		Global.spect_label.get_parent().modulate = Color("00ffffff")
	else:
		Global.spect_label.get_parent().modulate = Color("ffffffff")

func hide_lives():
	$body/g/UI/Label.visible = false

func show_lives():
	$body/g/UI/Label.visible = true


#func _input(event):
#	# Mouse in viewport coordinates.
#	if event is InputEventMouseButton:
#		if event.is_pressed():
#			var tvec = get_viewport().get_mouse_position() - get_viewport().get_canvas_transform().get_origin()
#			if self.is_in_group("owned"):
#				$hand.teleport(tvec)

