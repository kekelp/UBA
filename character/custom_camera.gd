extends Node2D

var spectate_pan_speed = 2700

var fixed_x = 0

onready var Viewport = self.get_viewport();

onready var arena = get_tree().get_nodes_in_group("arena")[0]
var bound_down
var bound_top
var bound_left
var bound_right

var cam_margin = 50

var target_x 
var target_y

var startingy = 200
var deadzone_x = 20
var deadzone_y_down = 0
var deadzone_y_up

onready var character = get_parent()

func is_own():
	return (character.get_parent().net_mode == character.get_parent().NET_MODE.own_on_host or character.get_parent().net_mode == character.get_parent().NET_MODE.own_on_client )

func _ready():
	if is_own():
		var character_x = -character.global_position.x  + get_viewport().size.x/2
		var target_point = Vector2( character_x, startingy )
		var frame_step = Transform2D(0.0, target_point)
		Viewport.set_canvas_transform(frame_step)
		window_resized()
		get_tree().get_root().connect("size_changed", self, "window_resized")

func window_resized():
	bound_down = arena.get_node("camera_bottom").global_position.y - get_viewport().size.y
	bound_top = arena.get_node("die_top").global_position.y + cam_margin
	bound_left = arena.get_node("die_left").global_position.x + cam_margin
	bound_right = arena.get_node("die_right").global_position.x - get_viewport().size.x - cam_margin
#	bound_right = 999999
#	bound_left = -999999

	deadzone_y_up = (get_viewport().size.y)*0.4

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_own():
		var ctrans = get_canvas_transform()
		var min_pos = -ctrans.get_origin() / ctrans.get_scale()
		var view_size = get_viewport_rect().size / ctrans.get_scale()
		var max_pos = min_pos + view_size

		var mouse_offcenter = get_viewport().get_mouse_position()*2/view_size - (Vector2(1.0,1.0))

		var time_number = 3
		var smoothing_time_seconds = 0.06
		var almost_three
		if delta != 0:
			almost_three = smoothing_time_seconds/(delta)
		else:
			almost_three = time_number
		
		var previous_frame_view_x = Viewport.get_canvas_transform().get_origin().x
		var previous_frame_view_y = Viewport.get_canvas_transform().get_origin().y

		var uncorr_target_x = -(character.global_position.x - get_viewport().size.x/2)
	
		if character.get_parent().spectator_mode == false:
			# deadzone
			var uncorr_x_diff = uncorr_target_x - previous_frame_view_x
			if uncorr_x_diff < 0:
				target_x = min(uncorr_target_x + deadzone_x, previous_frame_view_x)
			else: # uncorr_x_diff >= 0:
				target_x = max(uncorr_target_x - deadzone_x, previous_frame_view_x)


			var uncorr_target_y = -(character.global_position.y - get_viewport().size.y/2)
			var uncorr_y_diff = uncorr_target_y - previous_frame_view_y
			if uncorr_y_diff < 0:
				target_y = min(uncorr_target_y + deadzone_y_down, previous_frame_view_y)
			else: # uncorr_y_diff >= 0:
				target_y = max(uncorr_target_y - deadzone_y_up, previous_frame_view_y)
		
			# mouse correction
			var signum = sign(mouse_offcenter.x)
			var target_x_mouse_corr = (pow(abs(mouse_offcenter.x), 1.5)*view_size.x*0.27)
			target_x -= signum *target_x_mouse_corr
		
		else: # if character.spectator_mode == true:
			if Input.is_action_pressed("move_right"):
				target_x += - spectate_pan_speed * delta
			if Input.is_action_pressed("move_left"):
				target_x += spectate_pan_speed * delta
			if Input.is_action_pressed("move_down"):
				target_y += - spectate_pan_speed * delta
			if Input.is_action_pressed("move_up"):
				target_y += spectate_pan_speed * delta
				
#			# spectate mouse correction
#			var signum = sign(mouse_offcenter.x)
#			var target_x_mouse_corr = (pow(abs(mouse_offcenter.x), 1.5)*view_size.x*0.27)
#			target_x -= signum *target_x_mouse_corr
				


		# wall bounding
		if -target_y > bound_down:
			target_y = - (bound_down)   # don't drag
		if -target_y < bound_top:
			target_y = - (bound_top)   # don't drag
		if -target_x > bound_right:
			target_x = - (bound_right)   # don't drag
		if -target_x < bound_left:
			target_x = - (bound_left)   # don't drag


		var x_diff = target_x - previous_frame_view_x
		
		var y_diff = target_y - previous_frame_view_y
		
		var new_view_x = previous_frame_view_x + ( x_diff  )/almost_three
		var new_view_y = previous_frame_view_y + ( y_diff  )/almost_three
		
		var target_point = Vector2( new_view_x, new_view_y )
		var frame_step = Transform2D(0.0, target_point)
		
		Viewport.set_canvas_transform(frame_step)
