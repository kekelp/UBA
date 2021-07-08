extends RigidBody2D

#var force: Vector2
var should_reset = false
var reset_pos = Vector2(0,0)


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _process(_delta):
	$g.rotation = -self.rotation


func _integrate_forces(state):
	if should_reset == true:
		state.transform.origin = reset_pos
		should_reset = false
		get_parent().respawning = false
		get_parent().spectator_mode = false

