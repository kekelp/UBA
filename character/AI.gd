extends Node

onready var pawn = self.get_parent()
onready var enemy = get_tree().get_nodes_in_group("owned")[0]

var base_fight_distance = 450

func _process(delta):
	if pawn.net_mode == pawn.NET_MODE.other_on_host && \
	 pawn.control_mode == pawn.CONTROL_MODE.bot:
		var enemy_b_pos = enemy.get_node("body").global_position
		var own_b_pos = pawn.get_node("body").global_position
		var distance = enemy_b_pos.x - own_b_pos.x

		if abs(distance) > base_fight_distance:
			if distance > 0:
				pawn.moving_left = false
				pawn.moving_right = true
			else:
				pawn.moving_left = true
				pawn.moving_right = false
		else:
			pawn.moving_right = false
			pawn.moving_left = false
		
		pawn.target_b_pos = enemy_b_pos
		if pawn.outwards && pawn.towards_enemy:
			pawn.mouse_input = pawn.MOUSE_INPUT.attack
		else:
			pawn.mouse_input = pawn.MOUSE_INPUT.withdraw
			
