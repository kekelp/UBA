extends RigidBody2D

#var force: Vector2
var should_reset = false
var reset_pos = Vector2(0,0)


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _process(_delta):
#	print(self.rotation_degrees)
#	$g.rotation = -self.rotation
	pass

func _integrate_forces(state):
	if should_reset == true:
		state.transform.origin = reset_pos
		should_reset = false

func teleport(new_pos: Vector2):
	should_reset = true
	reset_pos = new_pos
	linear_velocity = Vector2(0,0)


