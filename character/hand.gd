extends RigidBody2D

var punch_force = Vector2(0,0)
var rest_pos = Vector2(98,0)

var offensive_arc:bool = false
var script_force_multiplier: float = 1.0

var should_reset = false
var reset_pos = Vector2(0,0)

var should_drag = true
var drag_return_vec
var drag_amount = 4.85

var idle_frames = 0

onready var base_y_scale = $g/Sprite.scale.y

# Called when the node enters the scene tree for the first time.
func _ready():
	self.position = rest_pos


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	$g.rotation = -self.rotation
#	$g/Sprite.rotation_degrees = 90
	var a = self.global_position
	var b = self.owner.target_b_pos
	$g/Sprite.rotation = -(PI/2 - atan2((b-a).x, -(b-a).y))
	if (b-a).x > 0:
		$g/Sprite.scale.y = base_y_scale
	else:
		$g/Sprite.scale.y = -base_y_scale

func _integrate_forces(state):

	if should_reset:
		state.transform.origin = reset_pos
		should_reset = false
	if should_drag:
		var drag_return_vec: Vector2 = $"../body".global_position - self.global_position
#		if (get_parent().net_mode == get_parent().NET_MODE.own_on_host || get_parent().net_mode == get_parent().NET_MODE.other_on_host ):
		state.transform.origin += drag_return_vec*drag_amount*get_parent().physics_proc_delta
	
	var total_force = (punch_force) * mass *0.5
	set_applied_force(total_force)


func teleport(new_pos: Vector2):
	reset_pos = new_pos + rest_pos
	should_reset = true
	linear_velocity = Vector2(0,0)
